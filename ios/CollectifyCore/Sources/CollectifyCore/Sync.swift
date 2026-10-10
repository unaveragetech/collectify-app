import Foundation

/// Port of TcgCsvClient.kt: the four tcgcsv.com endpoints, called straight from the phone.
public enum TcgCsvClient {
    static var base = "https://tcgcsv.com/tcgplayer"

    private static let session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 120
        return URLSession(configuration: cfg)
    }()

    static func get(_ path: String) throws -> [JSON] {
        guard let url = URL(string: "\(base)/\(path)") else { throw SQLError("bad url \(path)") }
        var req = URLRequest(url: url)
        req.setValue("Collectify-iOS/1.0", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let sem = DispatchSemaphore(value: 0)
        var out: (Data?, URLResponse?, Error?) = (nil, nil, nil)
        session.dataTask(with: req) { d, r, e in
            out = (d, r, e)
            sem.signal()
        }.resume()
        sem.wait()
        if let e = out.2 { throw e }
        guard let http = out.1 as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw SQLError("tcgcsv.com \(path) -> HTTP \((out.1 as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        guard let data = out.0, let obj = parseJSONObject(data) else { throw SQLError("empty response from \(path)") }
        if (obj["success"] as? Bool) != true { throw SQLError("tcgcsv.com reported failure for \(path)") }
        return (obj["results"] as? [JSON]) ?? []
    }

    static func categories() throws -> [JSON] { try get("categories") }
    static func groups(_ categoryId: Int) throws -> [JSON] { try get("\(categoryId)/groups") }
    static func products(_ categoryId: Int, _ groupId: Int) throws -> [JSON] { try get("\(categoryId)/\(groupId)/products") }
    static func prices(_ categoryId: Int, _ groupId: Int) throws -> [JSON] { try get("\(categoryId)/\(groupId)/prices") }
}

public struct SyncStats {
    public var groups = 0
    public var products = 0
    public var prices = 0
    public var errors = 0
}

/// Port of Sync.kt: upserts categories / groups / products / prices. The price key is per day and
/// printing, so re-syncing on a later day builds history instead of overwriting it.
public final class Sync {
    let db: SQLiteDB
    public init(_ db: SQLiteDB) { self.db = db }

    private func str(_ v: Any?) -> String? { (v is NSNull) ? nil : jString(v) }

    public func syncCategories() throws -> Int {
        let results = try TcgCsvClient.categories()
        let now = utcNow()
        try db.transaction {
            for c in results {
                try db.exec("""
                    INSERT OR REPLACE INTO categories(category_id, name, display_name, seo_name, is_scannable, popularity, modified_on, synced_at)
                    VALUES(?,?,?,?,?,?,?,?)
                    """, [jInt(c["categoryId"]), str(c["name"]) ?? "", str(c["displayName"]), str(c["seoCategoryName"]),
                          (jBool(c["isScannable"]) ?? false) ? 1 : 0, c.has("popularity") ? jInt(c["popularity"]) : nil, str(c["modifiedOn"]), now])
            }
        }
        return results.count
    }

    public func syncCategory(_ categoryId: Int, workers: Int = 6) throws -> SyncStats {
        let groups = try TcgCsvClient.groups(categoryId)
        var stats = SyncStats()
        let statsLock = NSLock()
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = workers
        for g in groups {
            queue.addOperation { [self] in
                do {
                    let r = try syncGroup(categoryId, g)
                    statsLock.lock()
                    stats.groups += 1
                    stats.products += r.0
                    stats.prices += r.1
                    statsLock.unlock()
                } catch {
                    statsLock.lock()
                    stats.errors += 1
                    statsLock.unlock()
                }
            }
        }
        queue.waitUntilAllOperationsAreFinished()
        return stats
    }

    private func syncGroup(_ categoryId: Int, _ group: JSON) throws -> (Int, Int) {
        guard let groupId = jInt(group["groupId"]) else { throw SQLError("group without id") }
        let products = try TcgCsvClient.products(categoryId, groupId)
        let prices = try TcgCsvClient.prices(categoryId, groupId)
        let now = utcNow()
        let today = utcToday()
        try db.transaction {
            try db.exec("""
                INSERT OR REPLACE INTO groups(group_id, category_id, name, abbreviation, is_supplemental, published_on, modified_on, synced_at)
                VALUES(?,?,?,?,?,?,?,?)
                """, [groupId, categoryId, str(group["name"]) ?? "", str(group["abbreviation"]), (jBool(group["isSupplemental"]) ?? false) ? 1 : 0,
                      str(group["publishedOn"]), str(group["modifiedOn"]), now])
            // A real upsert (not REPLACE) on purpose: artist / rules_text are filled only at build time
            // by the enrich scripts, and REPLACE would wipe them back to NULL on every in-app sync.
            for p in products {
                let extended = (p["extendedData"] as? [JSON]) ?? []
                var number: String?, rarity: String?
                for f in extended {
                    switch (f["name"] as? String)?.lowercased() {
                    case "number": number = str(f["value"])
                    case "rarity": rarity = str(f["value"])
                    default: break
                    }
                }
                try db.exec("""
                    INSERT INTO products(product_id, group_id, category_id, name, clean_name,
                                          image_url, url, number, rarity, extended_data,
                                          modified_on, synced_at)
                    VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(product_id) DO UPDATE SET
                        group_id=excluded.group_id, category_id=excluded.category_id,
                        name=excluded.name, clean_name=excluded.clean_name,
                        image_url=excluded.image_url, url=excluded.url,
                        number=excluded.number, rarity=excluded.rarity,
                        extended_data=excluded.extended_data,
                        modified_on=excluded.modified_on, synced_at=excluded.synced_at
                    """, [jInt(p["productId"]), groupId, categoryId, str(p["name"]) ?? "", str(p["cleanName"]), str(p["imageUrl"]),
                          str(p["url"]), number, rarity, jsonString(extended), str(p["modifiedOn"]), now])
            }
            for pr in prices {
                if !pr.has("productId") { continue }
                func d(_ k: String) -> Double? { pr.has(k) ? jDouble(pr[k]) : nil }
                try db.exec("""
                    INSERT OR REPLACE INTO prices(product_id, sub_type_name, price_date, low_price, mid_price, high_price, market_price, direct_low_price, captured_at)
                    VALUES(?,?,?,?,?,?,?,?,?)
                    """, [jInt(pr["productId"]), str(pr["subTypeName"]) ?? "Normal", today, d("lowPrice"), d("midPrice"), d("highPrice"), d("marketPrice"), d("directLowPrice"), now])
            }
        }
        return (products.count, prices.count)
    }
}
