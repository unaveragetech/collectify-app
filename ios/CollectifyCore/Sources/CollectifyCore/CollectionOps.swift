import Foundation

/// The collection no longer matches what the caller expected: becomes a 409.
public struct ConflictError: Error, CustomStringConvertible {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var description: String { message }
}

/// Binder tags (Tradable, Gradable, ...). Stored on the collection row as a comma list; same rules as
/// collectify/collection.py and CollectionOps.kt.
public enum Tags {
    public static let maxTags = 8

    public static func norm(_ tag: String?) -> String? {
        let t = (tag ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            .replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)
        return t.range(of: "^[a-z0-9][a-z0-9_-]{0,19}$", options: .regularExpression) != nil ? t : nil
    }

    public static func normList(_ tags: [String?]) -> [String] {
        var out = [String]()
        for t in tags {
            if let n = norm(t), !out.contains(n) { out.append(n) }
        }
        return out.take(maxTags)
    }

    public static func split(_ raw: String?) -> [String] {
        guard let raw = raw, !raw.isEmpty else { return [] }
        return normList(raw.split(separator: ",", omittingEmptySubsequences: false).map { String($0) })
    }

    public static func join(_ tags: [String?]) -> String? {
        let t = normList(tags)
        return t.isEmpty ? nil : t.joined(separator: ",")
    }

    static func strings(_ v: Any?) -> [String] {
        ((v as? [Any]) ?? []).compactMap { jString($0) }
    }
}

/// Port of the all-or-nothing operations in collectify/collection.py: tag many cards at once, and add +
/// remove cards in ONE transaction with a key that makes a retry safe.
public final class CollectionOps {
    private let db: SQLiteDB
    public init(_ db: SQLiteDB) { self.db = db }

    public func updateTags(ids: [String], add: [String], remove: [String], set: [String]?) throws -> Int {
        let addT = Tags.normList(add)
        let remT = Set(Tags.normList(remove))
        let setT = set.map { Tags.normList($0) }
        var changed = 0
        try db.transaction {
            for id in ids.distinctOrdered().take(2000) {
                guard let row = try db.query("SELECT tags FROM collection_items WHERE id=?", [id]).first else { continue }
                let cur = Tags.split(row.stringOrNil("tags"))
                var next: [String]
                if let s = setT {
                    next = s
                } else {
                    next = cur.filter { !remT.contains($0) }
                    for t in addT where !next.contains(t) { next.append(t) }
                }
                next = next.take(Tags.maxTags)
                if next != cur {
                    try db.exec("UPDATE collection_items SET tags=? WHERE id=?", [Tags.join(next), id])
                    changed += 1
                }
            }
        }
        return changed
    }

    public func apply(key rawKey: String, add: [JSON], remove: [JSON]) throws -> JSON {
        let key = String(rawKey.prefix(80))
        if key.isEmpty { throw BadRequest("an operation key is required") }
        let adds = add.take(400)
        let removes = remove.take(400)
        // looked up before the transaction starts
        var subs = [String]()
        for a in adds {
            guard let pid = jInt(a["product_id"]) else { throw BadRequest("product_id required") }
            if a.has("sub_type_name"), let s = jString(a["sub_type_name"]), !s.isEmpty { subs.append(s) }
            else { subs.append(Match.defaultSubType(try Match.latestPrices(db, productId: pid))) }
        }
        let repo = CollectionRepo(db)
        return try db.transaction { () throws -> JSON in
            if let done = try db.scalarString("SELECT result FROM applied_ops WHERE key=?", [key]), var res = parseJSONObject(Data(done.utf8)) {
                res["replay"] = true
                return res
            }
            var need = [String: Int]()
            var order = [String]()
            for r in removes {
                let id = jString(r["id"]) ?? ""
                if need[id] == nil { order.append(id) }
                need[id, default: 0] += Swift.max(1, jInt(r["quantity"]) ?? 1)
            }
            for r in removes {
                let id = jString(r["id"]) ?? ""
                guard let item = try db.query(
                    "SELECT i.product_id, i.quantity, i.condition, i.grade, p.name FROM collection_items i JOIN products p ON p.product_id=i.product_id WHERE i.id=?", [id]
                ).first else { throw ConflictError("A card in this change is no longer in your binders") }
                let name = item.string("name")
                if item.int("quantity") < (need[id] ?? 1) { throw ConflictError("You no longer have enough copies of \(name)") }
                if r.has("product_id"), jInt(r["product_id"]) != item.int("product_id") { throw ConflictError("\(name) is not the card it was when this started") }
                if r.has("condition"), jString(r["condition"]) != item.string("condition") { throw ConflictError("\(name) changed condition since this started") }
                if r.keys.contains("grade"), !r.has("grade") != item.isNull("grade") { throw ConflictError("\(name) was graded or un-graded since this started") }
            }
            var removed = [String]()
            for id in order {
                let q = need[id] ?? 1
                let have = try db.scalarInt("SELECT quantity FROM collection_items WHERE id=?", [id])
                if have > q { try db.exec("UPDATE collection_items SET quantity=? WHERE id=?", [have - q, id]) }
                else { try db.exec("DELETE FROM collection_items WHERE id=?", [id]) }
                removed.append(id)
            }
            var added = [String]()
            var defaultBinder: String? = nil
            for (n, a) in adds.enumerated() {
                let pid = jInt(a["product_id"]) ?? 0
                var binderId = a.has("binder_id") ? (jString(a["binder_id"]) ?? "") : ""
                if binderId.isEmpty {
                    if defaultBinder == nil { defaultBinder = try db.scalarString("SELECT id FROM binders ORDER BY sort_order LIMIT 1") }
                    guard let d = defaultBinder else { throw BadRequest("You don't have a binder to put these in") }
                    binderId = d
                }
                try repo.checkBinderAccepts(binderId, productId: pid)
                let cond = a.has("condition") ? (jString(a["condition"]) ?? "Near Mint") : "Near Mint"
                if conditionMultiplier(cond) == nil { throw BadRequest("Unknown condition \(cond)") }
                let grade = a.has("grade") ? jDouble(a["grade"]) : nil
                if let g = grade, g < 1.0 || g > 10.0 { throw BadRequest("grade must be between 1 and 10") }
                var gd: String? = nil
                if a.has("grade_data") { let v = a["grade_data"]!; gd = (v is String) ? (v as! String) : jsonString(v) }
                let id = newId()
                let slot = try db.scalarInt("SELECT COALESCE(MAX(slot), -1) + 1 FROM collection_items WHERE binder_id=?", [binderId])
                let source = String((a.has("source") ? (jString(a["source"]) ?? "manual") : "manual").prefix(16))
                try db.exec("""
                    INSERT INTO collection_items(id, binder_id, slot, product_id, sub_type_name, condition, quantity, source, raw_query, match_confidence, acquired_at, grade, grade_data, tags)
                    VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                    """, [id, binderId, slot, pid, subs[n], cond, Swift.max(1, Swift.min(999, jInt(a["quantity"]) ?? 1)), source,
                          a.has("raw_query") ? jString(a["raw_query"]) : nil, nil, utcNow(), grade, grade != nil ? gd : nil, Tags.join(Tags.strings(a["tags"]))])
                added.append(id)
            }
            let result: JSON = ["ok": true, "key": key, "added": added, "removed": removed, "replay": false]
            try db.exec("INSERT INTO applied_ops(key, result, applied_at) VALUES(?,?,?)", [key, jsonString(result), utcNow()])
            try db.exec("DELETE FROM applied_ops WHERE applied_at < date('now', '-120 days')")
            return result
        }
    }
}
