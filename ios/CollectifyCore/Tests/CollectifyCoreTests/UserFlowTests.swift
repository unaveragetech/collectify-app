import XCTest
@testable import CollectifyCore

/// Exercises the whole API against a small catalog built in a temp database: binders, restrictions,
/// the collection, wishlist, trades, game/island state, search and the trade rooms.
final class UserFlowTests: XCTestCase {
    var dir: URL!
    var db: SQLiteDB!
    var api: APIServer!

    override func setUpWithError() throws {
        CatalogDB.resetForTesting()
        Match.clearCaches()
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("collectify-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        db = try CatalogDB.open(path: dir.appendingPathComponent("t.db").path)
        try seed()
        api = APIServer(db: db, www: nil)
    }

    override func tearDownWithError() throws {
        db = nil
        api = nil
        try? FileManager.default.removeItem(at: dir)
    }

    func seed() throws {
        try db.exec("INSERT INTO categories(category_id, name, display_name, popularity) VALUES(3,'Pokemon','Pokemon',100),(1,'Magic','Magic: The Gathering',90)")
        try db.exec("INSERT INTO groups(group_id, category_id, name, published_on) VALUES(100,3,'Base Set','1999-01-09'),(101,3,'Jungle & Fossil Mix Of Long Words','1999-06-16'),(200,1,'Alpha','1993-08-05')")
        try db.exec("INSERT INTO categories(category_id, name, display_name, popularity) VALUES(29,'Funko','Funko',5)")
        try db.exec("INSERT INTO groups(group_id, category_id, name, published_on) VALUES(900,29,'Pops','2020-01-01')")
        let ins = "INSERT INTO products(product_id, group_id, category_id, name, clean_name, image_url, number, rarity) VALUES(?,?,?,?,?,?,?,?)"
        try db.exec(ins, [1001, 100, 3, "Pikachu", "Pikachu", "https://img/1001.jpg", "58/102", "Common"])
        try db.exec(ins, [1002, 100, 3, "Charizard", "Charizard", "https://img/1002.jpg", "4/102", "Rare Holo"])
        try db.exec(ins, [1003, 100, 3, "Base Set Booster Pack", "Base Set Booster Pack", "https://img/1003.jpg", nil, nil])
        for n in 0..<14 { try db.exec(ins, [1100 + n, 100, 3, "Filler Card \(n)", "Filler Card \(n)", "https://img/f\(n).jpg", "\(n + 10)/102", "Common"]) }
        for n in 0..<14 { try db.exec(ins, [1300 + n, 101, 3, "Jungle Card \(n)", "Jungle Card \(n)", "https://img/j\(n).jpg", "\(n + 1)/64", n < 2 ? "Rare" : "Common"]) }
        for n in 0..<14 { try db.exec(ins, [1500 + n, 900, 29, "Pop \(n)", "Pop \(n)", "https://img/p\(n).jpg", "\(n + 1)", "Common"]) }
        try db.exec(ins, [2001, 200, 1, "Black Lotus", "Black Lotus", "https://img/2001.jpg", "232", "Rare"])
        let pr = "INSERT INTO prices(product_id, sub_type_name, price_date, low_price, mid_price, high_price, market_price, captured_at) VALUES(?,?,?,?,?,?,?,?)"
        try db.exec(pr, [1001, "Normal", "2026-01-01", 1.0, 2.0, 3.0, 5.0, "2026-01-01T00:00:00Z"])
        try db.exec(pr, [1001, "Normal", "2026-02-01", 1.0, 2.0, 3.0, 7.5, "2026-02-01T00:00:00Z"])
        try db.exec(pr, [1001, "Holofoil", "2026-02-01", 5.0, 9.0, 12.0, 10.0, "2026-02-01T00:00:00Z"])
        try db.exec(pr, [1002, "Holofoil", "2026-02-01", 100.0, 200.0, 300.0, 250.0, "2026-02-01T00:00:00Z"])
        try db.exec(pr, [1003, "Normal", "2026-02-01", 3.0, 4.0, 5.0, 4.5, "2026-02-01T00:00:00Z"])
        try db.exec(pr, [2001, "Normal", "2026-02-01", 1000.0, 2000.0, 3000.0, 2500.0, "2026-02-01T00:00:00Z"])
        for n in 0..<14 { try db.exec(pr, [1300 + n, "Normal", "2026-02-01", 1.0, 2.0, 3.0, 4.0, "2026-02-01T00:00:00Z"]) }
        try db.exec("INSERT INTO products_fts(products_fts) VALUES('rebuild')")
    }

    @discardableResult
    func call(_ method: String, _ target: String, _ body: JSON? = nil) -> (Int, Any) {
        let (path, query) = HTTPRequest.parseTarget(target)
        let r = api.handle(HTTPRequest(method: method, path: path, query: query, body: body.map { jsonData($0) } ?? Data()))
        let obj = (try? JSONSerialization.jsonObject(with: r.body, options: [.fragmentsAllowed])) ?? NSNull()
        return (r.status, obj)
    }
    func dict(_ a: Any) -> JSON { a as! JSON }
    func arr(_ a: Any) -> [JSON] { a as! [JSON] }

    func testDefaultBinderIsThreeByThree() throws {
        let (c, b) = call("GET", "/api/binders")
        XCTAssertEqual(c, 200)
        let list = arr(b)
        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(list[0]["id"] as? String, "default")
        XCTAssertEqual(list[0]["page_size"] as? Int, 9)
        XCTAssertEqual(list[0]["pages"] as? Int, 1)
    }

    func testSearchAndProduct() throws {
        var (c, r) = call("GET", "/api/search?q=pikach")
        XCTAssertEqual(c, 200)
        XCTAssertEqual(arr(r).first?["product_id"] as? Int, 1001)
        XCTAssertNotNil(arr(r).first?["rank"])
        let prices = arr(r).first?["prices"] as? [JSON]
        XCTAssertEqual(prices?.count, 2) // Normal + Holofoil, latest only
        XCTAssertEqual(prices?.first { ($0["sub_type_name"] as? String) == "Normal" }?["market_price"] as? Double, 7.5)
        (c, r) = call("GET", "/api/search?q=filler&cards_only=1&limit=3")
        XCTAssertEqual(arr(r).count, 3)
        (c, r) = call("GET", "/api/search?q=lotus&category_id=3")
        XCTAssertEqual(arr(r).count, 0)
        (c, r) = call("GET", "/api/search?q=")
        XCTAssertEqual(arr(r).count, 0)
        // OCR noise: extra words fall back to the longest token
        (c, r) = call("GET", "/api/search?q=pikachu%20energy%20xyz")
        XCTAssertEqual(arr(r).first?["product_id"] as? Int, 1001)

        (c, r) = call("GET", "/api/product/1001")
        XCTAssertEqual(c, 200)
        XCTAssertEqual(dict(r)["name"] as? String, "Pikachu")
        XCTAssertEqual(dict(r)["group_name"] as? String, "Base Set")
        XCTAssertEqual((dict(r)["price_history"] as? [Any])?.count, 3)
        (c, r) = call("GET", "/api/product/999999")
        XCTAssertEqual(c, 404)
        (c, r) = call("GET", "/api/product/abc")
        XCTAssertEqual(c, 400)
    }

    func testCategoriesAndStats() throws {
        var (c, r) = call("GET", "/api/categories")
        XCTAssertEqual(arr(r).map { $0["category_id"] as? Int }, [3, 1, 29]) // by popularity
        (c, r) = call("GET", "/api/categories?search=magic")
        XCTAssertEqual(arr(r).count, 1)
        (c, r) = call("GET", "/api/stats")
        XCTAssertEqual(dict(r)["categories"] as? Int, 3)
        XCTAssertEqual(dict(r)["products"] as? Int, 46)
        XCTAssertEqual(dict(r)["binders"] as? Int, 1)
    }

    func testCollectionFlow() throws {
        var (c, r) = call("POST", "/api/collection", ["product_id": 1001, "condition": "Lightly Played", "quantity": 2, "raw_query": "pikachu"])
        XCTAssertEqual(c, 200)
        let itemId = dict(r)["id"] as! String
        XCTAssertEqual(dict(r)["sub_type_name"] as? String, "Normal")
        (c, r) = call("POST", "/api/collection", ["product_id": 1002, "sub_type_name": "Holofoil"])
        XCTAssertEqual(c, 200)

        (c, r) = call("GET", "/api/collection")
        let items = arr(dict(r)["items"]!)
        XCTAssertEqual(items.count, 2)
        // 7.5 * 0.85 * 2
        let pika = items.first { ($0["product_id"] as? Int) == 1001 }!
        XCTAssertEqual(pika["adjusted_value"] as? Double, 6.38)
        XCTAssertEqual(pika["line_value"] as? Double, 12.76)
        XCTAssertEqual(pika["source"] as? String, "scan")
        XCTAssertEqual(dict(r)["total_value"] as? Double, round2(12.76 + 250.0))

        (c, r) = call("GET", "/api/collection?group_by=rarity")
        XCTAssertEqual(arr(dict(r)["rows"]!).first?["group"] as? String, "Rare Holo")
        (c, r) = call("GET", "/api/collection?group_by=nope")
        XCTAssertEqual(c, 400)

        (c, r) = call("PUT", "/api/collection/\(itemId)/quantity", ["quantity": 5])
        XCTAssertEqual(c, 200)
        (c, r) = call("PUT", "/api/collection/\(itemId)/quantity", ["quantity": 0])
        XCTAssertEqual(c, 400)
        (c, r) = call("PUT", "/api/collection/\(itemId)/grade", ["grade": 9.5, "grade_data": ["centering": 9], "condition": "Near Mint"])
        XCTAssertEqual(c, 200)
        (c, r) = call("PUT", "/api/collection/\(itemId)/grade", ["grade": 11])
        XCTAssertEqual(c, 400)
        (c, r) = call("GET", "/api/collection")
        let after = arr(dict(r)["items"]!).first { ($0["id"] as? String) == itemId }!
        XCTAssertEqual(after["grade"] as? Double, 9.5)
        XCTAssertEqual(after["condition"] as? String, "Near Mint")
        XCTAssertEqual(after["quantity"] as? Int, 5)
        XCTAssertTrue((after["grade_data"] as? String)?.contains("centering") == true)
    }

    func testBinderPageSlots() throws {
        call("POST", "/api/collection", ["product_id": 1001])
        call("POST", "/api/collection", ["product_id": 1002, "sub_type_name": "Holofoil"])
        let (c, r) = call("GET", "/api/binders/default/page?page=0")
        XCTAssertEqual(c, 200)
        let slots = dict(r)["slots"] as! [Any]
        XCTAssertEqual(slots.count, 9)
        XCTAssertTrue(slots[0] is JSON)
        XCTAssertTrue(slots[1] is JSON)
        XCTAssertTrue(slots[2] is NSNull)
        XCTAssertEqual(dict(r)["total_pages"] as? Int, 1)
        let (c2, _) = call("GET", "/api/binders/nope/page")
        XCTAssertEqual(c2, 404)
    }

    func testBinderRestrictionsAndMoves() throws {
        var (c, r) = call("POST", "/api/binders", ["name": "  Pokemon only  ", "category_id": 3, "page_size": 4])
        XCTAssertEqual(c, 200)
        let pokeBinder = dict(r)["id"] as! String
        XCTAssertEqual(dict(r)["name"] as? String, "Pokemon only")
        XCTAssertEqual(dict(r)["category_name"] as? String, "Pokemon")

        (c, r) = call("POST", "/api/collection", ["product_id": 2001, "binder_id": pokeBinder])
        XCTAssertEqual(c, 400)
        XCTAssertTrue((dict(r)["detail"] as? String)?.contains("only holds Pokemon cards") == true)
        (c, r) = call("POST", "/api/collection", ["product_id": 1001, "binder_id": pokeBinder])
        XCTAssertEqual(c, 200)
        let a = dict(r)["id"] as! String
        (c, r) = call("POST", "/api/collection", ["product_id": 1002, "binder_id": pokeBinder, "sub_type_name": "Holofoil"])
        let b = dict(r)["id"] as! String

        // swap slots
        (c, r) = call("PUT", "/api/collection/slots", ["moves": [["id": a, "slot": 1]]])
        XCTAssertEqual(c, 200)
        XCTAssertEqual(dict(r)["moved"] as? Int, 1)
        (c, r) = call("GET", "/api/binders/\(pokeBinder)/page")
        let slots = dict(r)["slots"] as! [Any]
        XCTAssertEqual((slots[0] as? JSON)?["id"] as? String, b) // a took slot 1, so b was swapped into a's old slot 0
        XCTAssertEqual((slots[1] as? JSON)?["id"] as? String, a)

        // moving a Magic card into the Pokemon binder is refused; into the default one is fine
        (c, r) = call("POST", "/api/collection", ["product_id": 2001])
        let magic = dict(r)["id"] as! String
        (c, r) = call("PUT", "/api/collection/slots", ["moves": [["id": magic, "binder_id": pokeBinder]]])
        XCTAssertEqual(c, 400)

        // tie the default binder to Pokemon while it holds a Magic card: refused
        (c, r) = call("PUT", "/api/binders/default", ["category_id": 3])
        XCTAssertEqual(c, 400)
        (c, r) = call("PUT", "/api/binders/default", ["page_size": 3])
        XCTAssertEqual(c, 400)
        (c, r) = call("PUT", "/api/binders/default", ["page_size": 12, "name": "Main"])
        XCTAssertEqual(c, 200)
        XCTAssertEqual(dict(r)["page_size"] as? Int, 12)
        XCTAssertEqual(dict(r)["name"] as? String, "Main")
        // clear the category with an explicit null
        (c, r) = call("PUT", "/api/binders/\(pokeBinder)", ["category_id": NSNull()])
        XCTAssertEqual(c, 200)
        XCTAssertTrue(dict(r)["category_id"] is NSNull)

        (c, r) = call("PUT", "/api/binders/\(pokeBinder)/theme", ["theme": "{\"v\":1}"])
        XCTAssertEqual(c, 200)
        (c, r) = call("GET", "/api/binders/\(pokeBinder)")
        XCTAssertEqual(dict(r)["theme"] as? String, "{\"v\":1}")

        (c, r) = call("DELETE", "/api/binders/\(pokeBinder)")
        XCTAssertEqual(c, 200)
        (c, r) = call("GET", "/api/binders/\(pokeBinder)")
        XCTAssertEqual(c, 404)
        (c, r) = call("DELETE", "/api/collection/\(magic)")
        XCTAssertEqual(c, 200)
    }

    func testWishlist() throws {
        var (c, r) = call("POST", "/api/wishlist", ["product_id": 1002])
        XCTAssertEqual(c, 200)
        XCTAssertEqual(dict(r)["sub_type_name"] as? String, "Holofoil") // only price row
        let id = dict(r)["id"] as! String
        (c, r) = call("GET", "/api/wishlist")
        XCTAssertEqual(arr(r).count, 1)
        XCTAssertEqual(arr(r)[0]["market_price"] as? Double, 250.0)
        (c, r) = call("GET", "/api/wishlist?category_id=1")
        XCTAssertEqual(arr(r).count, 0)
        (c, r) = call("DELETE", "/api/wishlist/\(id)")
        XCTAssertEqual(c, 200)
        (c, r) = call("GET", "/api/wishlist")
        XCTAssertEqual(arr(r).count, 0)
    }

    func testTrades() throws {
        var (c, r) = call("POST", "/api/trades", ["session": "abc", "role": "offerer", "partner_name": "Sam", "gave": [["product_id": 1]], "got": [], "status": "completed", "code": "1234"])
        XCTAssertEqual(c, 200)
        (c, r) = call("POST", "/api/trades", ["session": "abc", "role": "boss", "gave": [], "got": []])
        XCTAssertEqual(c, 400)
        (c, r) = call("GET", "/api/trades")
        XCTAssertEqual(arr(r).count, 1)
        XCTAssertEqual(arr(r)[0]["status"] as? String, "completed")
        XCTAssertEqual((arr(r)[0]["gave"] as? [Any])?.count, 1)
        XCTAssertNotNil(arr(r)[0]["completed_at"] as? String)
    }

    func testGameAndIslandState() throws {
        var (c, r) = call("GET", "/api/game/state")
        XCTAssertTrue(dict(r)["state"] is NSNull)
        (c, r) = call("PUT", "/api/game/state", ["state": ["coins": 12, "nested": ["a": [1, 2, 3]]]])
        XCTAssertEqual(c, 200)
        (c, r) = call("GET", "/api/game/state")
        XCTAssertEqual((dict(r)["state"] as? JSON)?["coins"] as? Int, 12)
        (c, r) = call("PUT", "/api/game/state", ["state": "nope"])
        XCTAssertEqual(c, 400)
        (c, r) = call("PUT", "/api/island/state", ["state": ["level": 3]])
        XCTAssertEqual(c, 200)
        (c, r) = call("GET", "/api/island/state")
        XCTAssertEqual((dict(r)["state"] as? JSON)?["level"] as? Int, 3)
    }

    func testScannerAndGameCatalog() throws {
        var (c, r) = call("GET", "/api/scan/names?category_id=3")
        let names = dict(r)["names"] as! [String]
        XCTAssertTrue(names.contains("Pikachu"))
        XCTAssertFalse(names.contains("Base Set Booster Pack")) // no collector number
        (c, r) = call("POST", "/api/scan/lookup", ["names": ["Charizard", "Nothing"], "numbers": ["58102"], "category_id": 3])
        XCTAssertEqual(c, 200)
        let ids = arr(r).compactMap { $0["product_id"] as? Int }
        XCTAssertEqual(ids, [1002, 1001]) // names first, then the number match
        XCTAssertNotNil(arr(r)[0]["prices"])

        (c, r) = call("GET", "/api/game/sealed?category_id=3&kind=pack")
        XCTAssertEqual(arr(r).count, 1)
        XCTAssertEqual(arr(r)[0]["product_id"] as? Int, 1003)
        XCTAssertEqual(arr(r)[0]["kind"] as? String, "pack")
        XCTAssertEqual(arr(r)[0]["price"] as? Double, 4.5)
        XCTAssertEqual(arr(r)[0]["card_count"] as? Int, 16)
        (c, r) = call("GET", "/api/game/pool?group_id=100")
        XCTAssertEqual(arr(r).count, 16)
        (c, r) = call("GET", "/api/game/pool")
        XCTAssertEqual(c, 400)
    }

    func testGeneratedPacks() throws {
        // Base Set has a real sealed pack; Jungle has none -> a generated pack; Funko is not a card game
        var (c, r) = call("GET", "/api/game/games")
        XCTAssertEqual(c, 200)
        let games = arr(r)
        XCTAssertEqual(games.map { $0["category_id"] as? Int }, [3])
        XCTAssertEqual(games[0]["sets"] as? Int, 2)
        XCTAssertEqual(games[0]["generated_sets"] as? Int, 1)
        (c, r) = call("GET", "/api/game/vsealed?category_id=3")
        XCTAssertEqual(arr(r).count, 1)
        let p = arr(r)[0]
        XCTAssertEqual(p["product_id"] as? Int, 2_000_000_101)
        XCTAssertEqual(p["name"] as? String, "Jungle & Fossil Mix Of Long Words Booster Pack")
        XCTAssertEqual(p["virtual"] as? Bool, true)
        XCTAssertEqual(p["price"] as? Double, 10.0) // 4.0 average market * 2.5
        XCTAssertEqual(p["image_url"] as? String, "/api/game/packart/101")
        XCTAssertEqual(p["card_count"] as? Int, 14)
        (c, r) = call("GET", "/api/game/vsealed?category_id=1")
        XCTAssertEqual(arr(r).count, 0)
        (c, r) = call("GET", "/api/game/vsealed?q=fossil")
        XCTAssertEqual(arr(r).count, 1)
        (c, r) = call("GET", "/api/product/2000000101")
        XCTAssertEqual(c, 200)
        XCTAssertEqual(dict(r)["group_id"] as? Int, 101)
        XCTAssertEqual((dict(r)["latest_prices"] as? [JSON])?.first?["market_price"] as? Double, 10.0)
        (c, r) = call("GET", "/api/product/2000000999")
        XCTAssertEqual(c, 404)
        // the wrapper image
        let art = api.handle(HTTPRequest(method: "GET", path: "/api/game/packart/101"))
        XCTAssertEqual(art.status, 200)
        XCTAssertEqual(art.contentType, "image/svg+xml")
        XCTAssertTrue(art.text.contains("BOOSTER PACK"))
        XCTAssertTrue(art.text.contains("Jungle &amp;"))
        XCTAssertEqual(api.handle(HTTPRequest(method: "GET", path: "/api/game/packart/424242")).status, 404)
        // its cards can be opened
        (c, r) = call("GET", "/api/game/pool?group_id=101")
        XCTAssertEqual(arr(r).count, 14)
    }

    func testStaticAssets() throws {
        let www = dir.appendingPathComponent("www")
        try FileManager.default.createDirectory(at: www.appendingPathComponent("vendor"), withIntermediateDirectories: true)
        try "<html>hi</html>".write(to: www.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        try "console.log(1)".write(to: www.appendingPathComponent("app.js"), atomically: true, encoding: .utf8)
        try "x".write(to: www.appendingPathComponent("vendor/a.wasm"), atomically: true, encoding: .utf8)
        let s = APIServer(db: db, www: www)
        func get(_ p: String) -> HTTPResponse { s.handle(HTTPRequest(method: "GET", path: p)) }
        XCTAssertEqual(get("/").text, "<html>hi</html>")
        XCTAssertTrue(get("/static/app.js").contentType.hasPrefix("application/javascript"))
        XCTAssertEqual(get("/static/vendor/a.wasm").contentType, "application/wasm")
        XCTAssertEqual(get("/static/missing.js").status, 404)
        XCTAssertEqual(get("/static/../secret").status, 404)
    }

    func testTradeRooms() throws {
        let rooms = TradeRooms()
        let token = rooms.open(hostName: "Host", client: "h1")
        var (code, o) = rooms.join(token: token, name: "Guest", client: "g1")
        XCTAssertEqual(code, 200)
        (code, o) = rooms.join(token: token, name: "Other", client: "g2")
        XCTAssertEqual(code, 409)
        // cards: sanitised, and changing them resets agreement
        (code, o) = rooms.update(token: token, body: ["role": "host", "client": "h1", "cards": [["product_id": 1001, "condition": "", "pack": true, "n": 99], ["product_id": -1]]])
        XCTAssertEqual(code, 200)
        let hostCards = (o["host"] as! JSON)["cards"] as! [JSON]
        XCTAssertEqual(hostCards.count, 1)
        XCTAssertEqual(hostCards[0]["condition"] as? String, "Near Mint")
        XCTAssertEqual(hostCards[0]["n"] as? Int, 60)
        XCTAssertEqual(hostCards[0]["pack"] as? Bool, true)
        (code, o) = rooms.update(token: token, body: ["role": "guest", "client": "WRONG", "agreed": true])
        XCTAssertEqual(code, 403)
        (code, o) = rooms.update(token: token, body: ["role": "host", "client": "h1", "agreed": true])
        XCTAssertEqual(o["stage"] as? String, "edit")
        (code, o) = rooms.update(token: token, body: ["role": "guest", "client": "g1", "agreed": true])
        XCTAssertEqual(o["stage"] as? String, "swap")
        let digits = o["code"] as? String
        XCTAssertEqual(digits?.count, 4)
        (code, o) = rooms.update(token: token, body: ["role": "host", "client": "h1", "cards": []])
        XCTAssertEqual(code, 409) // locked
        (code, o) = rooms.update(token: token, body: ["role": "host", "client": "h1", "done": true, "gave": [true]])
        XCTAssertEqual(o["stage"] as? String, "swap")
        (code, o) = rooms.update(token: token, body: ["role": "guest", "client": "g1", "done": true])
        XCTAssertEqual(o["stage"] as? String, "done")
        // long poll returns at once when the version differs, and times out otherwise
        let v = o["v"] as! Int
        let t0 = Date()
        _ = rooms.get(token: token, since: v - 1, waitMs: 5000)
        XCTAssertLessThan(Date().timeIntervalSince(t0), 1)
        let t1 = Date()
        _ = rooms.get(token: token, since: v, waitMs: 400)
        XCTAssertGreaterThan(Date().timeIntervalSince(t1), 0.3)
        XCTAssertNil(rooms.get(token: "missing", since: nil, waitMs: 0))
        // HTTP front
        let r = RoomRoutes.handle(HTTPRequest(method: "GET", path: "/room/\(token)"), rooms: rooms)
        XCTAssertEqual(r.status, 200)
        XCTAssertEqual(r.headers["Access-Control-Allow-Origin"], "*")
        XCTAssertEqual(RoomRoutes.handle(HTTPRequest(method: "OPTIONS", path: "/room/x"), rooms: rooms).status, 204)
        XCTAssertEqual(RoomRoutes.handle(HTTPRequest(method: "GET", path: "/nope"), rooms: rooms).status, 404)
    }

    func testHTTPServerRoundTrip() throws {
        let port: UInt16 = 18431
        let server = HTTPServer(port: port, binding: .loopback) { [api] req in api!.handle(req) }
        XCTAssertTrue(server.start(), server.lastError ?? "no error")
        defer { server.stop() }
        let ex = expectation(description: "response")
        var url = URLComponents(string: "http://127.0.0.1:\(port)/api/stats")!
        url.queryItems = nil
        var req = URLRequest(url: url.url!)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        var gotStatus = 0
        var body = Data()
        URLSession.shared.dataTask(with: req) { d, r, _ in
            gotStatus = (r as? HTTPURLResponse)?.statusCode ?? 0
            body = d ?? Data()
            ex.fulfill()
        }.resume()
        wait(for: [ex], timeout: 10)
        XCTAssertEqual(gotStatus, 200)
        let o = try JSONSerialization.jsonObject(with: body) as! JSON
        XCTAssertEqual(o["products"] as? Int, 46)

        // a POST with a body
        let ex2 = expectation(description: "post")
        var post = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/api/collection")!)
        post.httpMethod = "POST"
        post.httpBody = jsonData(["product_id": 1001])
        post.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var postStatus = 0
        URLSession.shared.dataTask(with: post) { _, r, _ in
            postStatus = (r as? HTTPURLResponse)?.statusCode ?? 0
            ex2.fulfill()
        }.resume()
        wait(for: [ex2], timeout: 10)
        XCTAssertEqual(postStatus, 200)
    }

    func testCatalogMergeKeepsUserData() throws {
        // user data
        call("POST", "/api/collection", ["product_id": 1001])
        call("POST", "/api/wishlist", ["product_id": 1002])
        // a "bundled" database with a newer catalog (one extra product) and version 12
        let bundled = dir.appendingPathComponent("bundled.db")
        let b = try SQLiteDB(path: bundled.path)
        for sql in try db.query("SELECT sql FROM sqlite_master WHERE type='table' AND name IN ('categories','groups','products','prices','meta')").map({ $0.string("sql") }) { try b.exec(sql) }
        try b.exec("INSERT INTO categories(category_id, name, display_name) VALUES(3,'Pokemon','Pokemon')")
        try b.exec("INSERT INTO groups(group_id, category_id, name) VALUES(100,3,'Base Set')")
        try b.exec("INSERT INTO products(product_id, group_id, category_id, name, clean_name, number) VALUES(1001,100,3,'Pikachu','Pikachu','58/102'),(1002,100,3,'Charizard','Charizard','4/102'),(5000,100,3,'Brand New Card','Brand New Card','99/102')")
        let vf = dir.appendingPathComponent("catalog_version.txt")
        try "12".write(to: vf, atomically: true, encoding: .utf8)
        var started = false
        CatalogDB.mergeCatalogUpdateIfNeeded(db: db, bundled: bundled, versionFile: vf) { started = true }
        XCTAssertTrue(started)
        XCTAssertEqual(try db.getMeta("catalog_version"), "12")
        XCTAssertEqual(try db.scalarInt("SELECT COUNT(*) FROM products"), 3)
        XCTAssertEqual(try db.scalarInt("SELECT COUNT(*) FROM collection_items"), 1)
        XCTAssertEqual(try db.scalarInt("SELECT COUNT(*) FROM wishlist_items"), 1)
        let (c, r) = call("GET", "/api/search?q=brand")
        XCTAssertEqual(c, 200)
        XCTAssertEqual(arr(r).first?["product_id"] as? Int, 5000) // FTS was rebuilt
        // already current: nothing happens
        started = false
        CatalogDB.mergeCatalogUpdateIfNeeded(db: db, bundled: bundled, versionFile: vf) { started = true }
        XCTAssertFalse(started)
    }

    func testReopenExistingDatabase() throws {
        call("POST", "/api/collection", ["product_id": 1001])
        let path = db.path
        db = nil
        api = nil
        CatalogDB.resetForTesting()
        let again = try CatalogDB.open(path: path)
        XCTAssertEqual(try again.scalarInt("SELECT COUNT(*) FROM collection_items"), 1)
        XCTAssertEqual(try again.getMeta("fts5_available"), "1")
    }
}
