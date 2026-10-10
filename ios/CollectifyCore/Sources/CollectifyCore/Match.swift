import Foundation

/// Port of Match.kt (itself a port of collectify/match.py): FTS5 prefix-AND card search, the
/// scanner's name/number lookups, and the Treasure Box catalog queries.
public enum Match {
    private static let tokenRe = try! NSRegularExpression(pattern: "[a-z0-9]+")

    static func tokenize(_ term: String) -> [String] {
        let s = term.lowercased()
        let ns = s as NSString
        return tokenRe.matches(in: s, range: NSRange(location: 0, length: ns.length)).map { ns.substring(with: $0.range) }
    }

    // ---------------------------------------------------------------- search

    public static func search(_ db: SQLiteDB, _ term: String, categoryId: Int?, limit: Int, cardsOnly: Bool) throws -> [JSON] {
        let tokens = tokenize(term)
        if tokens.isEmpty { throw BadRequest("empty search term") }
        var results = try searchTokens(db, tokens, categoryId, limit, cardsOnly)
        if results.isEmpty && tokens.count > 1 {
            // OCR glues stray words onto a card's name: retry on the single longest token
            if let longest = tokens.max(by: { $0.count < $1.count }) {
                results = try searchTokens(db, [longest], categoryId, limit, cardsOnly)
            }
        }
        try attachLatestPrices(db, &results, ids: results.compactMap { $0["product_id"] as? Int })
        return results
    }

    private static func searchTokens(_ db: SQLiteDB, _ tokens: [String], _ categoryId: Int?, _ limit: Int, _ cardsOnly: Bool) throws -> [JSON] {
        if CatalogDB.isFtsAvailable(db) { return try searchFts(db, tokens, categoryId, limit, cardsOnly) }
        return try searchLike(db, tokens, categoryId, limit, cardsOnly)
    }

    private static func searchFts(_ db: SQLiteDB, _ tokens: [String], _ categoryId: Int?, _ limit: Int, _ cardsOnly: Bool) throws -> [JSON] {
        let query = tokens.map { "\"\($0)\"*" }.joined(separator: " AND ")
        var whereSql = ""
        var args: [Any?] = [query]
        if let c = categoryId {
            whereSql += " AND p.category_id = ?"
            args.append(c)
        }
        if cardsOnly { whereSql += " AND p.number IS NOT NULL" }
        args.append(limit)
        let sql = """
            SELECT p.product_id, p.name, p.clean_name, p.number, p.rarity, p.artist,
                   p.category_id, c.display_name AS category_name,
                   p.group_id, g.name AS group_name, p.image_url,
                   bm25(products_fts) AS rank
            FROM products_fts
            JOIN products p ON p.product_id = products_fts.rowid
            JOIN categories c ON c.category_id = p.category_id
            JOIN groups g ON g.group_id = p.group_id
            WHERE products_fts MATCH ? \(whereSql)
            ORDER BY rank
            LIMIT ?
            """
        return try db.query(sql, args).map { r in
            var o = productJSON(r)
            o["rank"] = r.double("rank")
            return o
        }
    }

    // For devices whose SQLite has no FTS5: prefix LIKE first (can use the name indexes), then substring.
    private static func searchLike(_ db: SQLiteDB, _ tokens: [String], _ categoryId: Int?, _ limit: Int, _ cardsOnly: Bool) throws -> [JSON] {
        let prefix = try searchLikeWithPattern(db, tokens, categoryId, limit, cardsOnly) { "\($0)%" }
        if !prefix.isEmpty { return prefix }
        return try searchLikeWithPattern(db, tokens, categoryId, limit, cardsOnly) { "%\($0)%" }
    }

    private static func searchLikeWithPattern(_ db: SQLiteDB, _ tokens: [String], _ categoryId: Int?, _ limit: Int, _ cardsOnly: Bool, _ pattern: (String) -> String) throws -> [JSON] {
        var whereSql = tokens.map { _ in "(p.name LIKE ? OR p.clean_name LIKE ?)" }.joined(separator: " AND ")
        var args: [Any?] = []
        for t in tokens {
            args.append(pattern(t))
            args.append(pattern(t))
        }
        if let c = categoryId {
            whereSql += " AND p.category_id = ?"
            args.append(c)
        }
        if cardsOnly { whereSql += " AND p.number IS NOT NULL" }
        args.append(limit)
        let sql = """
            SELECT p.product_id, p.name, p.clean_name, p.number, p.rarity, p.artist,
                   p.category_id, c.display_name AS category_name,
                   p.group_id, g.name AS group_name, p.image_url
            FROM products p
            JOIN categories c ON c.category_id = p.category_id
            JOIN groups g ON g.group_id = p.group_id
            WHERE \(whereSql)
            ORDER BY LENGTH(p.name)
            LIMIT ?
            """
        return try db.query(sql, args).map { r in
            var o = productJSON(r)
            o["rank"] = 0.0
            return o
        }
    }

    // ---------------------------------------------------------------- scanner lookups

    private static let scanSelect = """
        SELECT p.product_id, p.name, p.clean_name, p.number, p.rarity, p.artist,
               p.category_id, c.display_name AS category_name,
               p.group_id, g.name AS group_name, p.image_url
        FROM products p
        JOIN categories c ON c.category_id = p.category_id
        JOIN groups g ON g.group_id = p.group_id
        """

    private static let namesLock = NSLock()
    private static var scanNamesCache = [String: [String]]()

    public static func scanNames(_ db: SQLiteDB, categoryId: Int) throws -> [String] {
        let key = "\(db.path)#\(categoryId)"
        namesLock.lock()
        if let c = scanNamesCache[key] {
            namesLock.unlock()
            return c
        }
        namesLock.unlock()
        let rows = try db.query("SELECT DISTINCT clean_name FROM products WHERE category_id = ? AND number IS NOT NULL AND clean_name IS NOT NULL", [categoryId])
        let out = rows.compactMap { $0.stringOrNil("clean_name") }.filter { !$0.isEmpty }
        namesLock.lock()
        scanNamesCache[key] = out
        namesLock.unlock()
        return out
    }

    public static func clearCaches() {
        namesLock.lock()
        scanNamesCache.removeAll()
        namesLock.unlock()
    }

    public static func scanLookup(_ db: SQLiteDB, names namesIn: [String], numbers numbersIn: [String], categoryId: Int?, limit: Int) throws -> [JSON] {
        var order = [Int]()
        var found = [Int: JSON]()
        let catSql = categoryId != nil ? " AND p.category_id = ?" : ""
        let names = namesIn.filter { !$0.isEmpty }.distinctOrdered().take(60)
        if !names.isEmpty {
            let ph = names.map { _ in "?" }.joined(separator: ",")
            var args: [Any?] = names
            if let c = categoryId { args.append(c) }
            args.append(limit)
            for r in try db.query("\(scanSelect) WHERE p.clean_name IN (\(ph)) AND p.number IS NOT NULL\(catSql) ORDER BY p.product_id LIMIT ?", args) {
                let o = productJSON(r)
                let id = r.int("product_id")
                if found[id] == nil { order.append(id) }
                found[id] = o
            }
        }
        let numbers = numbersIn.map { $0.uppercased() }.filter { $0.count >= 4 }.distinctOrdered().take(12)
        if !numbers.isEmpty {
            let ph = numbers.map { _ in "?" }.joined(separator: ",")
            var args: [Any?] = numbers
            if let c = categoryId { args.append(c) }
            args.append(limit)
            for r in try db.query("\(scanSelect) WHERE UPPER(REPLACE(REPLACE(REPLACE(p.number, '-', ''), '/', ''), ' ', '')) IN (\(ph))\(catSql) LIMIT ?", args) {
                let id = r.int("product_id")
                if found[id] == nil {
                    found[id] = productJSON(r)
                    order.append(id)
                }
            }
        }
        var results = order.compactMap { found[$0] }
        try attachLatestPrices(db, &results, ids: order)
        return results
    }

    // ---------------------------------------------------------------- Treasure Box catalog

    private static func bestMarket(_ prices: [JSON]?) -> Any {
        var best = 0.0
        for p in prices ?? [] {
            if let m = p["market_price"] as? Double { best = max(best, m) }
        }
        return best > 0 ? best : NSNull()
    }

    private static let packClause = "((p.name LIKE '%Booster Pack%' OR p.name LIKE '%Celebration Pack%' OR p.name LIKE '%Anniversary Pack%') AND p.name NOT LIKE '%Case%' AND p.name NOT LIKE '%Box%' AND p.name NOT LIKE '%&%' AND p.name NOT LIKE '%Promo%' AND p.name NOT LIKE '%Portfolio%' AND p.name NOT LIKE '% Pin%' AND p.name NOT LIKE '%Bundle%' AND p.name NOT LIKE '%Display%' AND p.name NOT LIKE '%Blister%' AND p.name NOT LIKE '%Code Card%')"
    private static let boxClause = "(p.name LIKE '%Booster Box%' AND p.name NOT LIKE '%Case%' AND p.name NOT LIKE '%&%' AND p.name NOT LIKE '%Promo%' AND p.name NOT LIKE '%Portfolio%' AND p.name NOT LIKE '% Pin%' AND p.name NOT LIKE '%Bundle%' AND p.name NOT LIKE '%Display%' AND p.name NOT LIKE '%Blister%' AND p.name NOT LIKE '%Code Card%')"

    public static func gameSealed(_ db: SQLiteDB, categoryId: Int?, q: String, kind: String, limit: Int, offset: Int) throws -> [JSON] {
        let clause: String
        switch kind {
        case "pack": clause = packClause
        case "box": clause = boxClause
        default: clause = "(\(packClause) OR \(boxClause))"
        }
        var whereSql = "p.number IS NULL AND p.image_url IS NOT NULL AND \(clause)"
        var args: [Any?] = []
        if let c = categoryId {
            whereSql += " AND p.category_id = ?"
            args.append(c)
        }
        for tok in tokenize(q).take(4) {
            whereSql += " AND (p.name LIKE ? OR g.name LIKE ?)"
            args.append("%\(tok)%")
            args.append("%\(tok)%")
        }
        args.append(limit)
        args.append(offset)
        let rows = try db.query("""
            SELECT p.product_id, p.name, p.image_url, p.group_id, g.name AS group_name, g.published_on,
                   p.category_id, c.display_name AS category_name
            FROM products p
            JOIN groups g ON g.group_id = p.group_id
            JOIN categories c ON c.category_id = p.category_id
            WHERE \(whereSql)
            ORDER BY g.published_on DESC, p.product_id
            LIMIT ? OFFSET ?
            """, args)
        if rows.isEmpty { return [] }
        let raw: [JSON] = rows.map { r in
            [
                "product_id": r.int("product_id"),
                "name": r.string("name"),
                "image_url": orNull(r.stringOrNil("image_url")),
                "group_id": r.int("group_id"),
                "group_name": orNull(r.stringOrNil("group_name")),
                "published_on": orNull(r.stringOrNil("published_on")),
                "category_id": r.int("category_id"),
                "category_name": orNull(r.stringOrNil("category_name")),
            ]
        }
        let gids = raw.compactMap { $0["group_id"] as? Int }.distinctOrdered()
        var counts = [Int: Int]()
        let ph = gids.map { _ in "?" }.joined(separator: ",")
        for r in try db.query("SELECT group_id, COUNT(*) AS n FROM products WHERE group_id IN (\(ph)) AND number IS NOT NULL GROUP BY group_id", gids) {
            counts[r.int("group_id")] = r.int("n")
        }
        var kept = raw.filter { (counts[$0["group_id"] as! Int] ?? 0) >= 12 }.take(limit)
        for i in kept.indices {
            let gid = kept[i]["group_id"] as! Int
            kept[i]["card_count"] = counts[gid] ?? 0
            kept[i]["kind"] = (kept[i]["name"] as! String).lowercased().contains("booster box") ? "box" : "pack"
        }
        try attachLatestPrices(db, &kept, ids: kept.compactMap { $0["product_id"] as? Int })
        for i in kept.indices {
            kept[i]["price"] = bestMarket(kept[i]["prices"] as? [JSON])
            kept[i].removeValue(forKey: "prices")
        }
        return kept
    }

    public static func gamePool(_ db: SQLiteDB, groupId: Int) throws -> [JSON] {
        let rows = try db.query("""
            SELECT p.product_id, p.name, p.number, p.rarity, p.image_url, p.category_id, p.group_id,
                   g.name AS group_name, c.display_name AS category_name
            FROM products p
            JOIN groups g ON g.group_id = p.group_id
            JOIN categories c ON c.category_id = p.category_id
            WHERE p.group_id = ? AND p.number IS NOT NULL AND p.image_url IS NOT NULL
            ORDER BY p.product_id
            LIMIT 900
            """, [groupId])
        var arr: [JSON] = rows.map { r in
            [
                "product_id": r.int("product_id"),
                "name": r.string("name"),
                "number": orNull(r.stringOrNil("number")),
                "rarity": orNull(r.stringOrNil("rarity")),
                "image_url": orNull(r.stringOrNil("image_url")),
                "category_id": r.int("category_id"),
                "group_id": r.int("group_id"),
                "group_name": orNull(r.stringOrNil("group_name")),
                "category_name": orNull(r.stringOrNil("category_name")),
            ]
        }
        try attachLatestPrices(db, &arr, ids: arr.compactMap { $0["product_id"] as? Int })
        for i in arr.indices {
            arr[i]["price"] = bestMarket(arr[i]["prices"] as? [JSON])
            arr[i].removeValue(forKey: "prices")
        }
        return arr
    }

    // ---------------------------------------------------------------- shared helpers

    static func productJSON(_ r: Row) -> JSON {
        [
            "product_id": r.int("product_id"),
            "name": r.string("name"),
            "clean_name": orNull(r.stringOrNil("clean_name")),
            "number": orNull(r.stringOrNil("number")),
            "rarity": orNull(r.stringOrNil("rarity")),
            "artist": orNull(r.stringOrNil("artist")),
            "category_id": r.int("category_id"),
            "category_name": orNull(r.stringOrNil("category_name")),
            "group_id": r.int("group_id"),
            "group_name": orNull(r.stringOrNil("group_name")),
            "image_url": orNull(r.stringOrNil("image_url")),
        ]
    }

    static func priceRowJSON(_ r: Row) -> JSON {
        [
            "sub_type_name": orNull(r.stringOrNil("sub_type_name")),
            "market_price": orNull(r.doubleOrNil("market_price")),
            "low_price": orNull(r.doubleOrNil("low_price")),
            "mid_price": orNull(r.doubleOrNil("mid_price")),
            "high_price": orNull(r.doubleOrNil("high_price")),
            "price_date": orNull(r.stringOrNil("price_date")),
        ]
    }

    public static func latestPrices(_ db: SQLiteDB, productId: Int) throws -> [JSON] {
        try db.query("""
            SELECT sub_type_name, market_price, low_price, mid_price, high_price, price_date
            FROM prices
            WHERE product_id = ?
              AND price_date = (
                  SELECT MAX(price_date) FROM prices
                  WHERE product_id = ? AND sub_type_name = prices.sub_type_name
              )
            """, [productId, productId]).map(priceRowJSON)
    }

    public static func defaultSubType(_ prices: [JSON]) -> String {
        for p in prices where (p["sub_type_name"] as? String) == "Normal" { return "Normal" }
        return (prices.first?["sub_type_name"] as? String) ?? "Normal"
    }

    static func attachLatestPrices(_ db: SQLiteDB, _ results: inout [JSON], ids: [Int]) throws {
        if ids.isEmpty { return }
        var byProduct = [Int: [JSON]]()
        let ph = ids.map { _ in "?" }.joined(separator: ",")
        let rows = try db.query("""
            SELECT pr.product_id, pr.sub_type_name, pr.market_price, pr.low_price,
                   pr.mid_price, pr.high_price, pr.price_date
            FROM prices pr
            WHERE pr.product_id IN (\(ph))
              AND pr.price_date = (
                  SELECT MAX(price_date) FROM prices
                  WHERE product_id = pr.product_id AND sub_type_name = pr.sub_type_name
              )
            """, ids)
        for r in rows { byProduct[r.int("product_id"), default: []].append(priceRowJSON(r)) }
        for i in results.indices {
            let pid = results[i]["product_id"] as? Int ?? -1
            results[i]["prices"] = byProduct[pid] ?? []
        }
    }
}
