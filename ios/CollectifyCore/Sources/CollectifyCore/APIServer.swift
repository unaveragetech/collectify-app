import Foundation

/// Port of ApiServer.kt: the routes the web UI calls (same paths, same JSON shapes as
/// collectify/webapp.py), served from the on-device database and the bundled static UI.
public final class APIServer {
    private let db: SQLiteDB
    private let www: URL?
    public private(set) var isSyncing = false
    public private(set) var lastSyncError: String?
    private let syncLock = NSLock()

    /// Called when the UI asks to open a trade room: starts the LAN listener and returns its port.
    public var onRoomOpen: (() -> Void)?

    public init(db: SQLiteDB, www: URL?) {
        self.db = db
        self.www = www
    }

    // ---------------------------------------------------------------- dispatch

    public func handle(_ req: HTTPRequest) -> HTTPResponse {
        do {
            return try route(req)
        } catch let e as BadRequest {
            return .detail(e.message, status: 400)
        } catch let e as SQLError {
            return .detail(e.message, status: 500)
        } catch {
            return .detail("\(error)", status: 500)
        }
    }

    private func parts(_ path: String) -> [String] {
        path.split(separator: "/", omittingEmptySubsequences: false).map(String.init) // ["", "api", "x", ...]
    }

    private func body(_ req: HTTPRequest) -> JSON { parseJSONObject(req.body) ?? [:] }

    private func ok(_ o: Any) -> HTTPResponse { .json(o) }
    private func okTrue() -> HTTPResponse { .json(["ok": true]) }

    private func route(_ req: HTTPRequest) throws -> HTTPResponse {
        let uri = req.path
        let m = req.method
        let q = req.query

        if uri == "/" { return serveAsset("index.html") }
        if uri == "/static/app.js" { return serveAsset("app.js") }
        if uri == "/static/style.css" { return serveAsset("style.css") }
        if uri.hasPrefix("/static/") && !uri.contains("..") { return serveAsset(String(uri.dropFirst("/static/".count))) }

        if uri == "/api/room/open" && m == "POST" { return try roomOpen(req) }
        if uri == "/api/game/state" && m == "GET" { return try stateGet("game_state") }
        if uri == "/api/game/state" && m == "PUT" { return try statePut(req, "game_state", 8_000_000, "game state too large") }
        if uri == "/api/island/state" && m == "GET" { return try stateGet("island_state") }
        if uri == "/api/island/state" && m == "PUT" { return try statePut(req, "island_state", 1_000_000, "island state too large") }
        if uri == "/api/game/sealed" {
            return ok(try Match.gameSealed(db, categoryId: q["category_id"].flatMap { Int($0) }, q: q["q"] ?? "", kind: q["kind"] ?? "any",
                                           limit: min(q["limit"].flatMap { Int($0) } ?? 40, 80), offset: max(q["offset"].flatMap { Int($0) } ?? 0, 0)))
        }
        if uri == "/api/game/pool" {
            guard let g = q["group_id"].flatMap({ Int($0) }) else { throw BadRequest("group_id required") }
            return ok(try Match.gamePool(db, groupId: g))
        }
        if uri == "/api/scan/names" {
            guard let c = q["category_id"].flatMap({ Int($0) }) else { throw BadRequest("category_id required") }
            return ok(["names": try Match.scanNames(db, categoryId: c)])
        }
        if uri == "/api/scan/lookup" && m == "POST" { return try scanLookup(req) }
        if uri == "/api/trades" && m == "GET" { return ok(try TradesRepo(db).list()) }
        if uri == "/api/trades" && m == "POST" { return try recordTrade(req) }
        if uri == "/api/categories" { return ok(try listCategories(q["search"])) }
        if uri == "/api/search" { return try search(q) }
        if uri.hasPrefix("/api/product/") { return try product(String(uri.dropFirst("/api/product/".count))) }
        if uri == "/api/binders" && m == "GET" { return ok(try CollectionRepo(db).listBinders()) }
        if uri == "/api/binders" && m == "POST" { return try createBinder(req) }
        if uri == "/api/collection" && m == "GET" { return try getCollection(q) }
        if uri == "/api/collection" && m == "POST" { return try addCollection(req) }
        if uri == "/api/collection/slots" && m == "PUT" {
            let moves = (body(req)["moves"] as? [Any])?.compactMap { $0 as? JSON } ?? []
            let moved = try CollectionRepo(db).moveItems(moves)
            return ok(["ok": true, "moved": moved])
        }
        if uri == "/api/wishlist" && m == "GET" { return ok(try WishlistRepo(db).list(categoryId: q["category_id"].flatMap { Int($0) })) }
        if uri == "/api/wishlist" && m == "POST" { return try addWishlist(req) }
        if uri == "/api/sync/categories" { return syncCategories() }
        if uri == "/api/sync/category" && m == "POST" { return try syncCategory(req) }
        if uri == "/api/sync/status" { return ok(["syncing": isSyncing, "last_error": orNull(lastSyncError)]) }
        if uri == "/api/stats" { return try stats() }

        let p = parts(uri) // "", "api", resource, id, sub
        if p.count == 5 && p[1] == "api" && p[2].allSatisfy({ $0.isLetter && $0.isLowercase }) && p[4].allSatisfy({ $0.isLetter && $0.isLowercase }) {
            let id = p[3]
            switch p[4] {
            case "page": return try binderPage(id, q)
            case "grade" where m == "PUT": return try setGrade(id, req)
            case "quantity" where m == "PUT":
                try CollectionRepo(db).setQuantity(id, jInt(body(req)["quantity"]) ?? 0)
                return okTrue()
            case "theme" where m == "PUT":
                let b = body(req)
                try CollectionRepo(db).setBinderTheme(id, b.has("theme") ? jString(b["theme"]) : nil)
                return okTrue()
            default: break
            }
        }
        if p.count == 4 && p[1] == "api" && p[2].allSatisfy({ $0.isLetter && $0.isLowercase }) { return try idRoute(p[2], p[3], req) }
        return .detail("not found", status: 404)
    }

    // ---------------------------------------------------------------- static UI

    private func mime(_ name: String) -> String {
        switch (name as NSString).pathExtension.lowercased() {
        case "html": return "text/html; charset=utf-8"
        case "js", "mjs": return "application/javascript; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "svg": return "image/svg+xml"
        case "json": return "application/json"
        case "wasm": return "application/wasm"
        case "woff2": return "font/woff2"
        case "gz": return "application/gzip"
        default: return "application/octet-stream"
        }
    }

    private func serveAsset(_ name: String) -> HTTPResponse {
        guard let www = www, !name.contains("..") else { return .detail("not found", status: 404) }
        let url = www.appendingPathComponent(name)
        guard let data = try? Data(contentsOf: url) else { return .detail("not found", status: 404) }
        return HTTPResponse(status: 200, contentType: mime(name), body: data, headers: ["Cache-Control": "no-cache"])
    }

    // ---------------------------------------------------------------- handlers

    private func search(_ q: [String: String]) throws -> HTTPResponse {
        guard let term = q["q"], !term.isBlankString else { return ok([Any]()) }
        let cardsOnly = ["1", "true"].contains(q["cards_only"] ?? "")
        do {
            return ok(try Match.search(db, term, categoryId: q["category_id"].flatMap { Int($0) }, limit: q["limit"].flatMap { Int($0) } ?? 20, cardsOnly: cardsOnly))
        } catch is BadRequest {
            return ok([Any]())
        }
    }

    private func product(_ idStr: String) throws -> HTTPResponse {
        guard let productId = Int(idStr) else { throw BadRequest("bad product id") }
        guard let r = try db.query("""
            SELECT p.*, c.display_name AS category_name, g.name AS group_name
            FROM products p
            JOIN categories c ON c.category_id = p.category_id
            JOIN groups g ON g.group_id = p.group_id
            WHERE p.product_id = ?
            """, [productId]).first else { return .detail("not found", status: 404) }
        var o: JSON = [
            "product_id": productId,
            "name": r.string("name"),
            "clean_name": orNull(r.stringOrNil("clean_name")),
            "number": orNull(r.stringOrNil("number")),
            "rarity": orNull(r.stringOrNil("rarity")),
            "artist": orNull(r.stringOrNil("artist")),
            "rules_text": orNull(r.stringOrNil("rules_text")),
            "category_id": r.int("category_id"),
            "group_id": r.int("group_id"),
            "image_url": orNull(r.stringOrNil("image_url")),
            "url": orNull(r.stringOrNil("url")),
            "category_name": orNull(r.stringOrNil("category_name")),
            "group_name": orNull(r.stringOrNil("group_name")),
        ]
        o["price_history"] = try db.query(
            "SELECT sub_type_name, price_date, low_price, mid_price, high_price, market_price FROM prices WHERE product_id=? ORDER BY price_date",
            [productId]
        ).map { h in
            [
                "sub_type_name": orNull(h.stringOrNil("sub_type_name")),
                "price_date": orNull(h.stringOrNil("price_date")),
                "low_price": orNull(h.doubleOrNil("low_price")),
                "mid_price": orNull(h.doubleOrNil("mid_price")),
                "high_price": orNull(h.doubleOrNil("high_price")),
                "market_price": orNull(h.doubleOrNil("market_price")),
            ] as JSON
        }
        o["latest_prices"] = try Match.latestPrices(db, productId: productId)
        return ok(o)
    }

    private func createBinder(_ req: HTTPRequest) throws -> HTTPResponse {
        let b = body(req)
        let name = (jString(b["name"]) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let cat = b.has("category_id") ? jInt(b["category_id"]) : nil
        let size = b.has("page_size") ? (jInt(b["page_size"]) ?? 9) : 9
        let repo = CollectionRepo(db)
        let id = try repo.createBinder(name: name, categoryId: cat, pageSize: size)
        return ok(try repo.getBinder(id) ?? [:])
    }

    private func binderPage(_ id: String, _ q: [String: String]) throws -> HTTPResponse {
        do {
            return ok(try CollectionRepo(db).binderPage(id, page: q["page"].flatMap { Int($0) } ?? 0))
        } catch is BadRequest {
            return .detail("not found", status: 404)
        }
    }

    private func idRoute(_ resource: String, _ id: String, _ req: HTTPRequest) throws -> HTTPResponse {
        let m = req.method
        switch resource {
        case "binders":
            switch m {
            case "GET":
                if let b = try CollectionRepo(db).getBinder(id) { return ok(b) }
                return .detail("not found", status: 404)
            case "PATCH", "PUT":
                let b = body(req)
                let repo = CollectionRepo(db)
                try repo.updateBinder(id, name: b.has("name") ? jString(b["name"]) : nil, setCategory: b["category_id"] != nil,
                                      categoryId: b.has("category_id") ? jInt(b["category_id"]) : nil, pageSize: b.has("page_size") ? jInt(b["page_size"]) : nil)
                return ok(try repo.getBinder(id) ?? [:])
            case "DELETE":
                try CollectionRepo(db).deleteBinder(id)
                return okTrue()
            default: return .detail("not found", status: 404)
            }
        case "collection":
            if m == "DELETE" {
                try CollectionRepo(db).deleteItem(id)
                return okTrue()
            }
        case "wishlist":
            if m == "DELETE" {
                try WishlistRepo(db).remove(id)
                return okTrue()
            }
        default: break
        }
        return .detail("not found", status: 404)
    }

    private func stateGet(_ key: String) throws -> HTTPResponse {
        guard let raw = try db.getMeta(key), let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else { return ok(["state": NSNull()]) }
        return ok(["state": obj])
    }

    private func statePut(_ req: HTTPRequest, _ key: String, _ max: Int, _ tooLarge: String) throws -> HTTPResponse {
        guard let state = body(req)["state"] as? JSON else { throw BadRequest("state must be an object") }
        let raw = jsonString(state)
        if raw.utf16.count > max { throw BadRequest(tooLarge) }
        try db.setMeta(key, raw)
        return okTrue()
    }

    private func scanLookup(_ req: HTTPRequest) throws -> HTTPResponse {
        let b = body(req)
        func strings(_ a: Any?) -> [String] { ((a as? [Any]) ?? []).compactMap { jString($0) } }
        let cat: Int? = b.has("category_id") && !(jString(b["category_id"]) ?? "").isEmpty ? jInt(b["category_id"]) : nil
        let limit = min(jInt(b["limit"]) ?? 80, 200)
        return ok(try Match.scanLookup(db, names: strings(b["names"]), numbers: strings(b["numbers"]), categoryId: cat, limit: limit))
    }

    private func roomOpen(_ req: HTTPRequest) throws -> HTTPResponse {
        let b = body(req)
        let client = jString(b["client"]) ?? ""
        if client.isEmpty { throw BadRequest("client id required") }
        onRoomOpen?()
        let token = TradeRooms.shared.open(hostName: jString(b["name"]) ?? "Collector", client: client)
        return ok([
            "token": token,
            "ips": TradeRooms.lanAddresses(),
            "port": Int(RoomRoutes.port),
            "local_base": "http://127.0.0.1:\(RoomRoutes.port)",
        ])
    }

    private func recordTrade(_ req: HTTPRequest) throws -> HTTPResponse {
        let b = body(req)
        guard let session = jString(b["session"]), let role = jString(b["role"]) else { throw BadRequest("session and role required") }
        try TradesRepo(db).record(
            session: session, role: role,
            partner: b.has("partner_name") ? jString(b["partner_name"]) : nil,
            gave: (b["gave"] as? [Any]) ?? [], got: (b["got"] as? [Any]) ?? [],
            status: jString(b["status"]) ?? "pending", code: b.has("code") ? jString(b["code"]) : nil
        )
        return okTrue()
    }

    private func setGrade(_ id: String, _ req: HTTPRequest) throws -> HTTPResponse {
        let b = body(req)
        let grade = b.has("grade") ? jDouble(b["grade"]) : nil
        // grade_data is stored as JSON text whatever shape the page sent (object or string)
        var gradeData: String? = nil
        if b.has("grade_data") {
            let v = b["grade_data"]!
            gradeData = (v is String) ? (v as! String) : jsonString(v)
        }
        try CollectionRepo(db).setGrade(id, grade: grade, gradeData: gradeData, condition: b.has("condition") ? jString(b["condition"]) : nil)
        return okTrue()
    }

    private func getCollection(_ q: [String: String]) throws -> HTTPResponse {
        let cat = q["category_id"].flatMap { Int($0) }
        let binder = q["binder_id"]
        let repo = CollectionRepo(db)
        if let g = q["group_by"] {
            return ok(["group_by": g, "rows": try repo.collectionSummary(categoryId: cat, groupBy: g, binderId: binder)])
        }
        return ok(["items": try repo.rows(categoryId: cat, binderId: binder), "total_value": try repo.collectionValue(categoryId: cat, binderId: binder)])
    }

    private func addCollection(_ req: HTTPRequest) throws -> HTTPResponse {
        let b = body(req)
        guard let productId = jInt(b["product_id"]) else { throw BadRequest("product_id required") }
        let binderId = b.has("binder_id") ? jString(b["binder_id"]) : nil
        var sub = b.has("sub_type_name") ? jString(b["sub_type_name"]) : nil
        if sub == nil { sub = Match.defaultSubType(try Match.latestPrices(db, productId: productId)) }
        let condition = jString(b["condition"]) ?? "Near Mint"
        let quantity = jInt(b["quantity"]) ?? 1
        let rawQuery = b.has("raw_query") ? jString(b["raw_query"]) : nil
        let conf = b.has("match_confidence") ? jDouble(b["match_confidence"]) : nil
        let source = b.has("source") ? String(jString(b["source"])!.prefix(16)) : (rawQuery != nil ? "scan" : "manual")
        let id = try CollectionRepo(db).addScan(productId: productId, binderId: binderId, subTypeName: sub!, condition: condition, quantity: quantity, source: source, rawQuery: rawQuery, matchConfidence: conf)
        return ok(["id": id, "product_id": productId, "sub_type_name": sub!])
    }

    private func addWishlist(_ req: HTTPRequest) throws -> HTTPResponse {
        let b = body(req)
        guard let productId = jInt(b["product_id"]) else { throw BadRequest("product_id required") }
        var sub = b.has("sub_type_name") ? jString(b["sub_type_name"]) : nil
        if sub == nil { sub = Match.defaultSubType(try Match.latestPrices(db, productId: productId)) }
        let id = try WishlistRepo(db).add(productId: productId, subTypeName: sub!, note: b.has("note") ? jString(b["note"]) : nil)
        return ok(["id": id, "product_id": productId, "sub_type_name": sub!])
    }

    private func syncCategories() -> HTTPResponse {
        do {
            return ok(["synced": try Sync(db).syncCategories()])
        } catch {
            return .detail("Couldn't reach tcgcsv.com: \(error)", status: 500)
        }
    }

    private func syncCategory(_ req: HTTPRequest) throws -> HTTPResponse {
        guard let cat = jInt(body(req)["category_id"]) else { throw BadRequest("category_id required") }
        syncLock.lock()
        if isSyncing {
            syncLock.unlock()
            throw BadRequest("A sync is already running")
        }
        isSyncing = true
        lastSyncError = nil
        syncLock.unlock()
        defer {
            syncLock.lock()
            isSyncing = false
            syncLock.unlock()
        }
        do {
            let s = try Sync(db).syncCategory(cat)
            Match.clearCaches()
            return ok(["groups": s.groups, "products": s.products, "prices": s.prices, "errors": s.errors])
        } catch {
            lastSyncError = "\(error)"
            return .detail("Sync failed: \(error)", status: 500)
        }
    }

    private func stats() throws -> HTTPResponse {
        func count(_ t: String) throws -> Int { try db.scalarInt("SELECT COUNT(*) FROM \(t)") }
        return ok([
            "categories": try count("categories"),
            "products": try count("products"),
            "prices": try count("prices"),
            "collection_items": try count("collection_items"),
            "binders": try count("binders"),
            "wishlist_items": try count("wishlist_items"),
            "last_synced": orNull(try db.scalarString("SELECT MAX(synced_at) FROM products")),
        ])
    }

    private func listCategories(_ search: String?) throws -> [JSON] {
        var whereSql = ""
        var args = [Any?]()
        if let s = search, !s.isBlankString {
            whereSql = "WHERE name LIKE ? OR display_name LIKE ?"
            args = ["%\(s)%", "%\(s)%"]
        }
        return try db.query("SELECT * FROM categories \(whereSql) ORDER BY popularity DESC", args).map { r in
            [
                "category_id": r.int("category_id"),
                "name": r.string("name"),
                "display_name": orNull(r.stringOrNil("display_name")),
                "popularity": orNull(r.intOrNil("popularity")),
            ] as JSON
        }
    }
}
