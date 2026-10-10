import Foundation

/// Condition -> price multiplier, matching collectify/config.py CONDITIONS.
let CONDITIONS: [(String, Double)] = [
    ("Near Mint", 1.00),
    ("Lightly Played", 0.85),
    ("Moderately Played", 0.65),
    ("Heavily Played", 0.45),
    ("Damaged", 0.30),
]
func conditionMultiplier(_ name: String) -> Double? { CONDITIONS.first { $0.0 == name }?.1 }

/// Port of CollectionRepo.kt: binders (fixed-size pages) holding scanned cards.
public final class CollectionRepo {
    let db: SQLiteDB
    public init(_ db: SQLiteDB) { self.db = db }

    public func createBinder(name: String, categoryId: Int?, pageSize: Int) throws -> String {
        let id = newId()
        let nextOrder = try db.scalarInt("SELECT COALESCE(MAX(sort_order), -1) + 1 FROM binders")
        try db.exec(
            "INSERT INTO binders(id, name, category_id, page_size, sort_order, created_at) VALUES(?,?,?,?,?,?)",
            [id, name.isBlankString ? "Untitled Binder" : name, categoryId, pageSize, nextOrder, utcNow()]
        )
        return id
    }

    func ensureDefaultBinder() throws -> String {
        if let r = try db.query("SELECT id FROM binders ORDER BY sort_order LIMIT 1").first { return r.string("id") }
        return try createBinder(name: "My Binder", categoryId: nil, pageSize: 9)
    }

    /// A binder tied to one TCG only holds that TCG's cards (Mixed binders hold anything).
    func checkBinderAccepts(_ binderId: String, productId: Int) throws {
        guard let b = try db.query(
            "SELECT b.name, b.category_id, c.display_name FROM binders b LEFT JOIN categories c ON c.category_id=b.category_id WHERE b.id=?",
            [binderId]
        ).first else { throw BadRequest("That binder doesn't exist") }
        guard let cat = b.intOrNil("category_id") else { return }
        let binderName = b.string("name")
        let binderCatName = b.stringOrNil("display_name") ?? ""
        if let p = try db.query("SELECT p.category_id, c.display_name FROM products p JOIN categories c ON c.category_id=p.category_id WHERE p.product_id=?", [productId]).first,
           p.int("category_id") != cat {
            let cn = p.stringOrNil("display_name") ?? ""
            throw BadRequest("\"\(binderName)\" is a \(binderCatName) binder, so it only holds \(binderCatName) cards. A \(cn) card belongs in a Mixed binder or a \(cn) one.")
        }
    }

    /// Rename, change the page size (cards keep their slots; pages regroup) or tie to a TCG.
    public func updateBinder(_ binderId: String, name: String?, setCategory: Bool, categoryId: Int?, pageSize: Int?) throws {
        if try getBinder(binderId) == nil { throw BadRequest("That binder doesn't exist") }
        try db.transaction {
            if let n = name {
                let t = String(n.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
                try db.exec("UPDATE binders SET name=? WHERE id=?", [t.isBlankString ? "Untitled Binder" : t, binderId])
            }
            if let ps = pageSize {
                if ps < 4 || ps > 64 { throw BadRequest("A page holds between 4 and 64 cards") }
                try db.exec("UPDATE binders SET page_size=? WHERE id=?", [ps, binderId])
            }
            if setCategory {
                if let c = categoryId {
                    let other = try db.scalarInt("SELECT COUNT(*) FROM collection_items i JOIN products p ON p.product_id=i.product_id WHERE i.binder_id=? AND p.category_id<>?", [binderId, c])
                    if other > 0 { throw BadRequest("\(other) card(s) in this binder are from other games. Move them out first, or leave it Mixed.") }
                }
                try db.exec("UPDATE binders SET category_id=? WHERE id=?", [categoryId, binderId])
            }
        }
    }

    /// Re-slot cards and/or move them between binders; dropping onto an occupied slot swaps.
    public func moveItems(_ moves: [JSON]) throws -> Int {
        var done = 0
        try db.transaction {
            for m in moves.prefix(500) {
                let id = jString(m["id"]) ?? ""
                guard let cur = try db.query("SELECT binder_id, slot, product_id FROM collection_items WHERE id=?", [id]).first else { continue }
                let curBinder = cur.string("binder_id"), curSlot = cur.int("slot"), productId = cur.int("product_id")
                let target = m.has("binder_id") ? (jString(m["binder_id"]) ?? curBinder) : curBinder
                if target != curBinder { try checkBinderAccepts(target, productId: productId) }
                var slot = m.has("slot") ? (jInt(m["slot"]) ?? -1) : -1
                if slot < 0 { slot = try nextSlot(target) }
                if let occ = try db.query("SELECT id FROM collection_items WHERE binder_id=? AND slot=? AND id<>?", [target, slot, id]).first {
                    if target == curBinder { try db.exec("UPDATE collection_items SET slot=? WHERE id=?", [curSlot, occ.string("id")]) }
                    else { slot = try nextSlot(target) }
                }
                try db.exec("UPDATE collection_items SET binder_id=?, slot=? WHERE id=?", [target, slot, id])
                done += 1
            }
        }
        return done
    }

    public func deleteBinder(_ binderId: String) throws {
        try db.transaction {
            try db.exec("DELETE FROM collection_items WHERE binder_id=?", [binderId])
            try db.exec("DELETE FROM binders WHERE id=?", [binderId])
        }
    }

    public func getBinder(_ binderId: String) throws -> JSON? {
        try db.query("""
            SELECT b.*, c.display_name AS category_name
            FROM binders b LEFT JOIN categories c ON c.category_id = b.category_id
            WHERE b.id = ?
            """, [binderId]).first.map(binderJSON)
    }

    private func binderJSON(_ r: Row) -> JSON {
        [
            "id": r.string("id"),
            "name": r.string("name"),
            "category_id": orNull(r.intOrNil("category_id")),
            "page_size": r.int("page_size"),
            "theme": orNull(r.stringOrNil("theme")),
            "sort_order": r.int("sort_order"),
            "created_at": r.string("created_at"),
            "category_name": orNull(r.stringOrNil("category_name")),
        ]
    }

    public func listBinders() throws -> [JSON] {
        let rows = try db.query("""
            SELECT b.id, b.name, b.category_id, b.page_size, b.theme, b.sort_order, b.created_at,
                   c.display_name AS category_name
            FROM binders b LEFT JOIN categories c ON c.category_id = b.category_id
            ORDER BY b.sort_order
            """)
        var out = [JSON]()
        for r in rows {
            var b = binderJSON(r)
            let items = try self.rows(binderId: r.string("id"))
            var unique = Set<Int>()
            var quantity = 0
            var total = 0.0
            var maxSlot = -1
            for i in items {
                unique.insert(i["product_id"] as! Int)
                quantity += i["quantity"] as! Int
                total += i["line_value"] as! Double
                maxSlot = max(maxSlot, i["slot"] as! Int)
            }
            let pageSize = r.int("page_size")
            b["unique_cards"] = unique.count
            b["quantity"] = quantity
            b["total_value"] = round2(total)
            b["pages"] = max(1, Int((Double(maxSlot + 1) / Double(pageSize)).rounded(.up)))
            out.append(b)
        }
        return out
    }

    public func binderPage(_ binderId: String, page: Int) throws -> JSON {
        guard let binder = try getBinder(binderId) else { throw BadRequest("No binder \(binderId)") }
        let pageSize = binder["page_size"] as! Int
        let items = try rows(binderId: binderId)
        var bySlot = [Int: JSON]()
        var maxSlot = -1
        for i in items {
            let s = i["slot"] as! Int
            bySlot[s] = i
            maxSlot = max(maxSlot, s)
        }
        let totalPages = max(1, Int((Double(maxSlot + 1) / Double(pageSize)).rounded(.up)))
        let clamped = min(max(page, 0), totalPages - 1)
        let start = clamped * pageSize
        var slots = [Any]()
        for i in 0..<pageSize { slots.append(bySlot[start + i] ?? NSNull()) }
        return ["binder": binder, "page": clamped, "total_pages": totalPages, "slots": slots]
    }

    private func nextSlot(_ binderId: String) throws -> Int {
        try db.scalarInt("SELECT COALESCE(MAX(slot), -1) + 1 FROM collection_items WHERE binder_id=?", [binderId])
    }

    public func addScan(productId: Int, binderId: String?, subTypeName: String, condition: String, quantity: Int, source: String, rawQuery: String?, matchConfidence: Double?) throws -> String {
        if conditionMultiplier(condition) == nil { throw BadRequest("Unknown condition \(condition)") }
        let resolved = try binderId ?? ensureDefaultBinder()
        let id = newId()
        try checkBinderAccepts(resolved, productId: productId)
        try db.transaction {
            let slot = try nextSlot(resolved)
            try db.exec("""
                INSERT INTO collection_items(id, binder_id, slot, product_id, sub_type_name, condition, quantity, source, raw_query, match_confidence, acquired_at)
                VALUES(?,?,?,?,?,?,?,?,?,?,?)
                """, [id, resolved, slot, productId, subTypeName, condition, quantity, source, rawQuery, matchConfidence, utcNow()])
        }
        return id
    }

    /// Store (or clear, with grade == nil) an item's pseudo-grade; optionally moves its condition too.
    public func setGrade(_ itemId: String, grade: Double?, gradeData: String?, condition: String?) throws {
        if let g = grade, g < 1.0 || g > 10.0 { throw BadRequest("grade must be between 1 and 10") }
        if let c = condition, conditionMultiplier(c) == nil { throw BadRequest("Unknown condition \(c)") }
        var sets = ["grade=?", "grade_data=?"]
        var args: [Any?] = [grade, (grade != nil && gradeData != nil) ? gradeData : nil]
        if let c = condition {
            sets.append("condition=?")
            args.append(c)
        }
        args.append(itemId)
        try db.exec("UPDATE collection_items SET \(sets.joined(separator: ", ")) WHERE id=?", args)
    }

    public func setQuantity(_ itemId: String, _ quantity: Int) throws {
        if quantity < 1 || quantity > 999 { throw BadRequest("quantity must be between 1 and 999") }
        try db.exec("UPDATE collection_items SET quantity=? WHERE id=?", [quantity, itemId])
    }

    public func setBinderTheme(_ binderId: String, _ theme: String?) throws {
        if let t = theme, t.count > 20000 { throw BadRequest("cover design too large") }
        try db.exec("UPDATE binders SET theme=? WHERE id=?", [theme, binderId])
    }

    public func deleteItem(_ itemId: String) throws {
        try db.exec("DELETE FROM collection_items WHERE id=?", [itemId])
    }

    /// Every collection item joined to product context + latest price, with a condition-adjusted value.
    public func rows(categoryId: Int? = nil, binderId: String? = nil) throws -> [JSON] {
        var wh = [String]()
        var args = [Any?]()
        if let c = categoryId {
            wh.append("p.category_id = ?")
            args.append(c)
        }
        if let b = binderId {
            wh.append("ci.binder_id = ?")
            args.append(b)
        }
        let whereSql = wh.isEmpty ? "" : "WHERE " + wh.joined(separator: " AND ")
        let rs = try db.query("""
            SELECT ci.id, ci.binder_id, ci.slot, ci.product_id, ci.sub_type_name, ci.condition, ci.quantity,
                   ci.source, ci.acquired_at, ci.grade, ci.grade_data,
                   p.name, p.number, p.rarity, p.image_url, p.group_id, p.category_id,
                   g.name AS group_name, c.display_name AS category_name,
                   (SELECT market_price FROM prices
                    WHERE product_id = ci.product_id AND sub_type_name = ci.sub_type_name
                    ORDER BY price_date DESC LIMIT 1) AS market_price
            FROM collection_items ci
            JOIN products p ON p.product_id = ci.product_id
            JOIN groups g ON g.group_id = p.group_id
            JOIN categories c ON c.category_id = p.category_id
            \(whereSql)
            ORDER BY ci.acquired_at DESC
            """, args)
        return rs.map { r in
            let market = r.doubleOrNil("market_price") ?? 0.0
            let cond = r.string("condition")
            let adjusted = round2(market * (conditionMultiplier(cond) ?? 1.0))
            let qty = r.int("quantity")
            let isGame = r.string("source") == "game"
            return [
                "id": r.string("id"),
                "binder_id": r.string("binder_id"),
                "slot": r.int("slot"),
                "product_id": r.int("product_id"),
                "sub_type_name": r.string("sub_type_name"),
                "condition": cond,
                "quantity": qty,
                "source": r.string("source"),
                "acquired_at": r.string("acquired_at"),
                "grade": orNull(r.doubleOrNil("grade")),
                "grade_data": orNull(r.stringOrNil("grade_data")),
                "name": r.string("name"),
                "number": orNull(r.stringOrNil("number")),
                "rarity": orNull(r.stringOrNil("rarity")),
                "image_url": orNull(r.stringOrNil("image_url")),
                "group_id": r.int("group_id"),
                "category_id": r.int("category_id"),
                "group_name": orNull(r.stringOrNil("group_name")),
                "category_name": orNull(r.stringOrNil("category_name")),
                "adjusted_value": adjusted,
                // Treasure Box pulls are game cards, not cards the user owns: they never count toward a total.
                "is_game": isGame,
                "line_value": isGame ? 0.0 : round2(adjusted * Double(qty)),
            ] as JSON
        }
    }

    public func collectionValue(categoryId: Int? = nil, binderId: String? = nil) throws -> Double {
        round2(try rows(categoryId: categoryId, binderId: binderId).reduce(0.0) { $0 + ($1["line_value"] as! Double) })
    }

    private static let groupColumns = ["category": "category_name", "group": "group_name", "rarity": "rarity", "condition": "condition"]

    public func collectionSummary(categoryId: Int?, groupBy: String, binderId: String?) throws -> [JSON] {
        guard let key = Self.groupColumns[groupBy] else { throw BadRequest("bad group_by") }
        struct Bucket { var products = Set<Int>(); var quantity = 0; var total = 0.0 }
        var order = [String]()
        var buckets = [String: Bucket]()
        for item in try rows(categoryId: categoryId, binderId: binderId) {
            let k: String
            if let s = item[key] as? String { k = s } else { k = "Unknown" }
            if buckets[k] == nil {
                order.append(k)
                buckets[k] = Bucket()
            }
            buckets[k]!.products.insert(item["product_id"] as! Int)
            buckets[k]!.quantity += item["quantity"] as! Int
            buckets[k]!.total += item["line_value"] as! Double
        }
        let list: [(Int, JSON)] = order.enumerated().map { (i, k) in
            let b = buckets[k]!
            return (i, ["group": k, "unique_products": b.products.count, "quantity": b.quantity, "total_value": round2(b.total)])
        }
        return list.sorted { a, b in
            let av = a.1["total_value"] as! Double, bv = b.1["total_value"] as! Double
            return av != bv ? av > bv : a.0 < b.0
        }.map { $0.1 }
    }
}

/// Port of WishlistRepo.kt.
public final class WishlistRepo {
    let db: SQLiteDB
    public init(_ db: SQLiteDB) { self.db = db }

    public func add(productId: Int, subTypeName: String, note: String?) throws -> String {
        let id = newId()
        try db.exec("INSERT INTO wishlist_items(id, product_id, sub_type_name, note, added_at) VALUES(?,?,?,?,?)", [id, productId, subTypeName, note, utcNow()])
        return id
    }

    public func remove(_ itemId: String) throws {
        try db.exec("DELETE FROM wishlist_items WHERE id=?", [itemId])
    }

    public func list(categoryId: Int?) throws -> [JSON] {
        let whereSql = categoryId != nil ? "WHERE p.category_id = ?" : ""
        let args: [Any?] = categoryId != nil ? [categoryId] : []
        return try db.query("""
            SELECT w.id, w.product_id, w.sub_type_name, w.note, w.added_at,
                   p.name, p.number, p.rarity, p.image_url, p.group_id, p.category_id,
                   g.name AS group_name, c.display_name AS category_name,
                   (SELECT market_price FROM prices
                    WHERE product_id = w.product_id AND sub_type_name = w.sub_type_name
                    ORDER BY price_date DESC LIMIT 1) AS market_price
            FROM wishlist_items w
            JOIN products p ON p.product_id = w.product_id
            JOIN groups g ON g.group_id = p.group_id
            JOIN categories c ON c.category_id = p.category_id
            \(whereSql)
            ORDER BY w.added_at DESC
            """, args).map { r in
            [
                "id": r.string("id"),
                "product_id": r.int("product_id"),
                "sub_type_name": r.string("sub_type_name"),
                "note": orNull(r.stringOrNil("note")),
                "added_at": r.string("added_at"),
                "name": r.string("name"),
                "number": orNull(r.stringOrNil("number")),
                "rarity": orNull(r.stringOrNil("rarity")),
                "image_url": orNull(r.stringOrNil("image_url")),
                "group_id": r.int("group_id"),
                "category_id": r.int("category_id"),
                "group_name": orNull(r.stringOrNil("group_name")),
                "category_name": orNull(r.stringOrNil("category_name")),
                "market_price": orNull(r.doubleOrNil("market_price")),
            ] as JSON
        }
    }
}

/// Port of TradesRepo.kt: the on-device log of in-person trades.
public final class TradesRepo {
    let db: SQLiteDB
    public init(_ db: SQLiteDB) { self.db = db }

    public func record(session: String, role: String, partner: String?, gave: [Any], got: [Any], status: String, code: String?) throws {
        if role != "offerer" && role != "joiner" { throw BadRequest("bad trade role") }
        if !["pending", "agreed", "completed", "cancelled"].contains(status) { throw BadRequest("bad trade status") }
        let sess = String(session.prefix(32))
        let id = "\(sess)-\(role)"
        let existing = try db.scalarString("SELECT created_at FROM trades WHERE id=?", [id])
        let now = utcNow()
        try db.exec("""
            INSERT OR REPLACE INTO trades(id, session, role, partner_name, gave, got, status, code, created_at, completed_at)
            VALUES(?,?,?,?,?,?,?,?,?,?)
            """, [id, sess, role, String((partner ?? "").prefix(40)), jsonString(gave), jsonString(got), status, code, existing ?? now, status == "completed" ? now : nil])
    }

    public func list(limit: Int = 50) throws -> [JSON] {
        try db.query("SELECT * FROM trades ORDER BY created_at DESC LIMIT ?", [limit]).map { r in
            var o: JSON = [:]
            for col in ["id", "session", "role", "status", "created_at"] { o[col] = r.string(col) }
            o["partner_name"] = orNull(r.stringOrNil("partner_name"))
            o["code"] = orNull(r.stringOrNil("code"))
            o["completed_at"] = orNull(r.stringOrNil("completed_at"))
            o["gave"] = (try? JSONSerialization.jsonObject(with: Data(r.string("gave").utf8))) ?? []
            o["got"] = (try? JSONSerialization.jsonObject(with: Data(r.string("got").utf8))) ?? []
            return o
        }
    }
}
