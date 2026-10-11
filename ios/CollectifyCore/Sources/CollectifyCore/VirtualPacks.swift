import Foundation

/// Generated ("virtual") packs for the Treasure Box: every set with enough single cards can be mined
/// and opened, even when the catalog has no sealed booster-pack product for it. Port of
/// VirtualPacks.kt / collectify/virtual_packs.py: keep the rules, ids and prices identical.
public enum VirtualPacks {
    public static let base = 2_000_000_000

    // Games with fewer than minPacks sets get "mixed packs" so there are at least that many packs to open (see
    // collectify/virtual_packs.py): pack k of K draws on a window of the game's cards. Their ids are
    // mixBase + category_id * 100 + k, and that same number is the pack's group_id for /api/game/pool.
    public static let mixBase = 2_100_000_000
    private static let minPacks = 10
    private static let mixMaxCards = 600

    struct Mixed {
        let productId: Int
        let categoryId: Int
        let categoryName: String?
        let popularity: Int
        let k: Int
        let cardCount: Int
        let ids: [Int]
        var name: String { "\(categoryName ?? "") Mixed Pack \(k)" }
    }
    private static let excluded = [29, 31, 32, 35] // Funko, Card Sleeves, Deck Boxes, Playmats

    struct VGroup {
        let groupId: Int
        let name: String
        let publishedOn: String?
        let categoryId: Int
        let categoryName: String?
        let popularity: Int
        let cardCount: Int
        let hasReal: Bool
    }

    private static let lock = NSLock()
    private static var cache = [String: [VGroup]]()
    private static var mixedCache = [String: [Mixed]]()

    public static func clearCache() {
        lock.lock()
        cache.removeAll()
        mixedCache.removeAll()
        lock.unlock()
    }

    private static func mixed(_ db: SQLiteDB) throws -> [Mixed] {
        lock.lock()
        if let c = mixedCache[db.path] {
            lock.unlock()
            return c
        }
        lock.unlock()
        var byCat = [Int: [VGroup]]()
        for g in try groups(db) { byCat[g.categoryId, default: []].append(g) }
        var out = [Mixed]()
        for cat in byCat.keys.sorted() {
            let gs = byCat[cat]!
            if gs.count >= minPacks { continue }
            var cards = [Int]()
            for g in gs {
                for r in try db.query("SELECT p.product_id FROM products p WHERE p.group_id = ? AND \(Match.poolCardSQL) ORDER BY p.product_id LIMIT 900", [g.groupId]) {
                    cards.append(r.int("product_id"))
                }
            }
            let n = cards.count
            if n < Match.minSetCards { continue }
            let kTotal = minPacks - gs.count
            let w = Swift.max(Match.minSetCards, Swift.min(Swift.min(n, mixMaxCards), (2 * n + kTotal - 1) / kTotal))
            for i in 0..<kTotal {
                let s = (i * n) / kTotal
                let ids = (0..<w).map { cards[(s + $0) % n] }.sorted()
                out.append(Mixed(productId: mixBase + cat * 100 + (i + 1), categoryId: cat, categoryName: gs[0].categoryName, popularity: gs[0].popularity, k: i + 1, cardCount: w, ids: ids))
            }
        }
        lock.lock()
        mixedCache[db.path] = out
        lock.unlock()
        return out
    }

    static func mixedById(_ db: SQLiteDB, _ productId: Int) throws -> Mixed? {
        try mixed(db).first(where: { $0.productId == productId })
    }

    public static func mixedPool(_ db: SQLiteDB, groupId: Int) throws -> [JSON]? {
        guard let m = try mixedById(db, groupId) else { return nil }
        return try Match.gamePoolIds(db, ids: m.ids)
    }

    private static func priceIds(_ db: SQLiteDB, _ ids: [Int]) throws -> Double {
        let r = try db.query("""
            SELECT AVG(m) AS a FROM (
              SELECT MAX(pr.market_price) AS m FROM products p JOIN prices pr ON pr.product_id = p.product_id
              WHERE p.product_id IN (\(ids.map { _ in "?" }.joined(separator: ","))) AND pr.market_price IS NOT NULL
                AND pr.price_date = (SELECT MAX(price_date) FROM prices WHERE product_id = pr.product_id AND sub_type_name = pr.sub_type_name)
              GROUP BY p.product_id)
            """, ids).first
        guard let avg = r?.doubleOrNil("a") else { return 2.5 }
        return round2(Swift.min(45.0, Swift.max(1.5, avg * 2.5)))
    }

    private static func groups(_ db: SQLiteDB) throws -> [VGroup] {
        lock.lock()
        if let c = cache[db.path] {
            lock.unlock()
            return c
        }
        lock.unlock()
        let rows = try db.query("""
            SELECT g.group_id, g.name, g.published_on, g.category_id, c.display_name AS category_name,
                   COALESCE(c.popularity, 0) AS popularity, n.cnt AS card_count,
                   EXISTS(SELECT 1 FROM products p WHERE p.group_id = g.group_id AND p.number IS NULL
                          AND p.image_url IS NOT NULL AND \(Match.packClauseSQL)) AS has_real
            FROM groups g
            JOIN categories c ON c.category_id = g.category_id
            JOIN (\(Match.groupCardCountSQL) GROUP BY p.group_id HAVING cnt >= \(Match.minSetCards)) n
              ON n.group_id = g.group_id
            WHERE g.category_id NOT IN (\(excluded.map(String.init).joined(separator: ",")))
            ORDER BY g.published_on DESC, g.group_id
            """)
        let out = rows.map {
            VGroup(groupId: $0.int("group_id"), name: $0.string("name"), publishedOn: $0.stringOrNil("published_on"), categoryId: $0.int("category_id"),
                   categoryName: $0.stringOrNil("category_name"), popularity: $0.int("popularity"), cardCount: $0.int("card_count"), hasReal: $0.int("has_real") == 1)
        }
        lock.lock()
        cache[db.path] = out
        lock.unlock()
        return out
    }

    private static func price(_ db: SQLiteDB, _ groupId: Int) throws -> Double {
        let r = try db.query("""
            SELECT AVG(m) AS a FROM (
              SELECT MAX(pr.market_price) AS m FROM products p JOIN prices pr ON pr.product_id = p.product_id
              WHERE p.group_id = ? AND \(Match.poolCardSQL) AND pr.market_price IS NOT NULL
                AND pr.price_date = (SELECT MAX(price_date) FROM prices WHERE product_id = pr.product_id AND sub_type_name = pr.sub_type_name)
              GROUP BY p.product_id)
            """, [groupId]).first
        guard let avg = r?.doubleOrNil("a") else { return 2.5 }
        return round2(min(45.0, max(1.5, avg * 2.5)))
    }

    public static func games(_ db: SQLiteDB) throws -> [JSON] {
        struct Acc { var id: Int; var name: String?; var pop: Int; var sets = 0; var gen = 0 }
        var order = [Int]()
        var by = [Int: Acc]()
        for g in try groups(db) {
            if by[g.categoryId] == nil {
                by[g.categoryId] = Acc(id: g.categoryId, name: g.categoryName, pop: g.popularity)
                order.append(g.categoryId)
            }
            by[g.categoryId]!.sets += 1
            if !g.hasReal { by[g.categoryId]!.gen += 1 }
        }
        var mixedBy = [Int: Int]()
        for m in try mixed(db) { mixedBy[m.categoryId, default: 0] += 1 }
        let list = order.enumerated().map { ($0.offset, by[$0.element]!) }
        return list.sorted { a, b in
            if a.1.pop != b.1.pop { return a.1.pop > b.1.pop }
            let an = a.1.name ?? "", bn = b.1.name ?? ""
            return an != bn ? an < bn : a.0 < b.0
        }.map { _, a in
            let mx = mixedBy[a.id] ?? 0
            return ["category_id": a.id, "name": orNull(a.name), "popularity": a.pop, "sets": a.sets, "generated_sets": a.gen, "mixed": mx, "packs": a.sets + mx] as JSON
        }
    }

    public static func packs(_ db: SQLiteDB, categoryId: Int?, q: String, limit: Int, offset: Int) throws -> [JSON] {
        let toks = Match.tokenize(q).take(4)
        let list = try groups(db).filter { g in
            !g.hasReal && (categoryId == nil || g.categoryId == categoryId) && toks.allSatisfy { "\(g.name) \(g.categoryName ?? "")".lowercased().contains($0) }
        }
        let mixedList = try mixed(db).filter { m in
            (categoryId == nil || m.categoryId == categoryId) && toks.allSatisfy { "\(m.name) mixed".lowercased().contains($0) }
        }
        var out = [JSON]()
        for g in list.dropFirst(offset).prefix(limit) {
            out.append([
                "product_id": base + g.groupId,
                "name": "\(g.name) Booster Pack",
                "image_url": "/api/game/packart/\(g.groupId)",
                "group_id": g.groupId,
                "group_name": g.name,
                "published_on": orNull(g.publishedOn),
                "category_id": g.categoryId,
                "category_name": orNull(g.categoryName),
                "card_count": g.cardCount,
                "kind": "pack",
                "virtual": true,
                "price": try price(db, g.groupId),
            ])
        }
        // the mixed packs follow the set packs (so they page in after them)
        let room = limit - out.count
        let first = Swift.max(0, offset - list.count)
        if room > 0 {
            for m in mixedList.dropFirst(first).prefix(room) {
                out.append([
                    "product_id": m.productId,
                    "name": m.name,
                    "image_url": "/api/game/packart/\(m.productId)",
                    "group_id": m.productId,
                    "group_name": "Mixed Pack \(m.k)",
                    "published_on": NSNull(),
                    "category_id": m.categoryId,
                    "category_name": orNull(m.categoryName),
                    "card_count": m.cardCount,
                    "kind": "pack",
                    "virtual": true,
                    "price": try priceIds(db, m.ids),
                ])
            }
        }
        return out
    }

    public static func product(_ db: SQLiteDB, productId: Int) throws -> JSON? {
        if productId < base { return nil }
        if productId >= mixBase {
            guard let m = try mixedById(db, productId) else { return nil }
            let lp: JSON = ["sub_type_name": "Sealed Pack", "market_price": try priceIds(db, m.ids), "low_price": NSNull(), "mid_price": NSNull(), "high_price": NSNull(), "price_date": NSNull()]
            return [
                "product_id": productId,
                "name": m.name,
                "clean_name": m.name,
                "number": NSNull(), "rarity": NSNull(), "artist": NSNull(), "rules_text": NSNull(),
                "category_id": m.categoryId,
                "group_id": productId,
                "image_url": "/api/game/packart/\(productId)",
                "url": NSNull(),
                "category_name": orNull(m.categoryName),
                "group_name": "Mixed Pack \(m.k)",
                "price_history": [Any](),
                "latest_prices": [lp],
            ]
        }
        let gid = productId - base
        guard let g = try groups(db).first(where: { $0.groupId == gid }) else { return nil }
        let lp: JSON = ["sub_type_name": "Sealed Pack", "market_price": try price(db, gid), "low_price": NSNull(), "mid_price": NSNull(), "high_price": NSNull(), "price_date": NSNull()]
        return [
            "product_id": productId,
            "name": "\(g.name) Booster Pack",
            "clean_name": "\(g.name) Booster Pack",
            "number": NSNull(), "rarity": NSNull(), "artist": NSNull(), "rules_text": NSNull(),
            "category_id": g.categoryId,
            "group_id": gid,
            "image_url": "/api/game/packart/\(gid)",
            "url": NSNull(),
            "category_name": orNull(g.categoryName),
            "group_name": g.name,
            "price_history": [Any](),
            "latest_prices": [lp],
        ]
    }

    private static func wrapName(_ name: String, width: Int = 13, maxLines: Int = 4) -> [String] {
        var lines = [String]()
        var cur = ""
        for w in name.split(whereSeparator: { $0.isWhitespace }).map(String.init) {
            if !cur.isEmpty && cur.count + 1 + w.count > width {
                lines.append(cur)
                cur = w
            } else {
                cur = (cur + " " + w).trimmingCharacters(in: .whitespaces)
            }
        }
        if !cur.isEmpty { lines.append(cur) }
        if lines.count > maxLines {
            lines = Array(lines.prefix(maxLines))
            let last = lines[maxLines - 1]
            lines[maxLines - 1] = String(last.prefix(max(1, width - 1))).trimmingCharacters(in: .whitespaces) + "…"
        }
        return lines.map { $0.count <= width + 4 ? $0 : String($0.prefix(width + 3)) + "…" }
    }

    private static func xml(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// A foil booster-pack wrapper for a set (no external images, so it works offline).
    public static func packArt(_ db: SQLiteDB, groupId: Int) throws -> String? {
        var name = "", cat = 0, catName = "", hueKey = groupId
        if groupId >= mixBase {
            guard let m = try mixedById(db, groupId) else { return nil }
            name = "Mixed Pack \(m.k)"; cat = m.categoryId; catName = m.categoryName ?? ""; hueKey = m.k
        } else {
            guard let r = try db.query("SELECT g.name, g.category_id, c.display_name FROM groups g JOIN categories c ON c.category_id = g.category_id WHERE g.group_id = ?", [groupId]).first else { return nil }
            name = r.string("name"); cat = r.int("category_id"); catName = r.stringOrNil("display_name") ?? ""
        }
        let h = (cat * 47 + hueKey * 13) % 360
        let lines = wrapName(name)
        let longest = lines.map { $0.count }.max() ?? 1
        let size = longest <= 9 ? 36 : longest <= 11 ? 30 : longest <= 14 ? 25 : 21
        let y0 = 212.0 - Double((lines.count - 1) * (size + 6)) / 2.0
        var text = ""
        for (i, ln) in lines.enumerated() {
            let y = Int((y0 + Double(i * (size + 6))).rounded())
            text += "<text x=\"150\" y=\"\(y)\" text-anchor=\"middle\" font-size=\"\(size)\" font-weight=\"800\" fill=\"#fff\" stroke=\"rgba(0,0,0,.45)\" stroke-width=\"5\" paint-order=\"stroke\" font-family=\"Arial Black,Arial,Helvetica,sans-serif\">\(xml(ln))</text>"
        }
        var crimps = ""
        for i in stride(from: 0, to: 300, by: 10) {
            crimps += "<rect x=\"\(i)\" y=\"0\" width=\"5\" height=\"26\" fill=\"rgba(0,0,0,.2)\"/><rect x=\"\(i)\" y=\"394\" width=\"5\" height=\"26\" fill=\"rgba(0,0,0,.2)\"/>"
        }
        let cname = xml(String(catName.uppercased().prefix(26)))
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 300 420\">"
            + "<defs><linearGradient id=\"a\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0\" stop-color=\"hsl(\(h),75%,62%)\"/><stop offset=\".55\" stop-color=\"hsl(\((h + 28) % 360),80%,45%)\"/><stop offset=\"1\" stop-color=\"hsl(\((h + 340) % 360),72%,27%)\"/></linearGradient>"
            + "<radialGradient id=\"r\" cx=\".5\" cy=\".5\" r=\".5\"><stop offset=\"0\" stop-color=\"#fff\" stop-opacity=\".5\"/><stop offset=\"1\" stop-color=\"#fff\" stop-opacity=\"0\"/></radialGradient></defs>"
            + "<rect width=\"300\" height=\"420\" rx=\"14\" fill=\"url(#a)\"/>"
            + "<circle cx=\"150\" cy=\"210\" r=\"140\" fill=\"url(#r)\"/>"
            + "<polygon points=\"150,92 160,122 192,122 166,140 176,170 150,152 124,170 134,140 108,122 140,122\" fill=\"rgba(255,255,255,.25)\"/>"
            + crimps
            + "<polygon points=\"40,0 90,0 -10,420 -60,420\" fill=\"rgba(255,255,255,.14)\"/>"
            + "<text x=\"150\" y=\"66\" text-anchor=\"middle\" font-size=\"15\" font-weight=\"700\" letter-spacing=\"3\" fill=\"rgba(255,255,255,.92)\" font-family=\"Arial,Helvetica,sans-serif\">\(cname)</text>"
            + text
            + "<rect x=\"70\" y=\"318\" width=\"160\" height=\"34\" rx=\"17\" fill=\"rgba(0,0,0,.35)\"/>"
            + "<text x=\"150\" y=\"342\" text-anchor=\"middle\" font-size=\"17\" font-weight=\"800\" letter-spacing=\"3\" fill=\"#fff\" font-family=\"Arial,Helvetica,sans-serif\">BOOSTER PACK</text>"
            + "<rect x=\"1.5\" y=\"1.5\" width=\"297\" height=\"417\" rx=\"13\" fill=\"none\" stroke=\"rgba(255,255,255,.55)\" stroke-width=\"3\"/>"
            + "</svg>"
    }
}
