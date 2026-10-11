import XCTest
@testable import CollectifyCore

/// The island-visit relay: same scenarios as tests/test_visit.py (the Python reference implementation).
final class VisitRoomTests: XCTestCase {
    var visits: VisitRooms!
    var token = ""

    override func setUp() {
        visits = VisitRooms()
        token = visits.open(hostName: "Host", client: "hc")
    }

    func testJoinActAndAnswer() {
        var (st, out) = visits.join(token: token, name: "Sam", client: "c1")
        XCTAssertEqual(st, 200)
        XCTAssertEqual((out["you"] as? JSON)?["id"] as? Int, 1)
        XCTAssertEqual((out["feed"] as? [JSON])?.last?["text"] as? String, "arrived")
        (st, out) = visits.act(token: token, body: ["client": "c1", "kind": "water", "data": ["plot": 3]])
        XCTAssertEqual(st, 200)
        XCTAssertEqual(out["id"] as? Int, 1)
        var room = visits.get(token: token, since: nil, sv: nil, waitMs: 0, me: "hc")!
        XCTAssertEqual(room["you"] as? String, "host")
        let events = room["events"] as! [JSON]
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0]["kind"] as? String, "water")
        XCTAssertEqual(events[0]["name"] as? String, "Sam")
        (st, _) = visits.hostUpdate(token: token, body: ["client": "hc", "ack": [1], "results": ["1": ["ok": true, "msg": "Watered", "rewards": ["xp": 2]]], "feed": [["text": "Sam watered a plot"]]])
        XCTAssertEqual(st, 200)
        room = visits.get(token: token, since: nil, sv: nil, waitMs: 0, me: "c1")!
        XCTAssertEqual((room["events"] as! [JSON]).count, 0)
        XCTAssertEqual((((room["results"] as! JSON)["1"] as! JSON)["rewards"] as! JSON)["xp"] as? Int, 2)
        XCTAssertEqual((room["feed"] as! [JSON]).last?["text"] as? String, "Sam watered a plot")
    }

    func testSnapshotOnlySentWhenChanged() {
        _ = visits.hostUpdate(token: token, body: ["client": "hc", "snap": ["level": 7]])
        let room = visits.get(token: token, since: nil, sv: nil, waitMs: 0, me: nil)!
        XCTAssertEqual((room["snap"] as? JSON)?["level"] as? Int, 7)
        let again = visits.get(token: token, since: nil, sv: room["snap_v"] as? Int, waitMs: 0, me: nil)!
        XCTAssertNil(again["snap"])
    }

    func testOnlyTheHostPublishesAndVisitorsMustJoin() {
        _ = visits.join(token: token, name: "Sam", client: "c1")
        XCTAssertEqual(visits.hostUpdate(token: token, body: ["client": "c1", "snap": [:] as JSON]).0, 403)
        XCTAssertEqual(visits.act(token: token, body: ["client": "stranger", "kind": "water", "data": [:] as JSON]).0, 403)
        XCTAssertEqual(visits.join(token: token, name: "Me", client: "hc").0, 409)
    }

    func testLimits() {
        for i in 0..<VisitRooms.maxVisitors { XCTAssertEqual(visits.join(token: token, name: "v\(i)", client: "c\(i)").0, 200) }
        XCTAssertEqual(visits.join(token: token, name: "late", client: "cx").0, 409)
        XCTAssertEqual(visits.join(token: token, name: "v0", client: "c0").0, 200)
        XCTAssertEqual(visits.act(token: token, body: ["client": "c0", "kind": "nope", "data": [:] as JSON]).0, 400)
        XCTAssertEqual(visits.act(token: token, body: ["client": "c0", "kind": "note", "data": ["text": String(repeating: "x", count: 5000)]]).0, 400)
        XCTAssertEqual(visits.hostUpdate(token: token, body: ["client": "hc", "snap": ["x": String(repeating: "y", count: 300_000)]]).0, 413)
    }

    func testPositionAndKick() {
        _ = visits.join(token: token, name: "Sam", client: "c1")
        _ = visits.act(token: token, body: ["client": "c1", "kind": "pos", "data": ["x": 3.5, "z": -2, "ry": 1]])
        var room = visits.get(token: token, since: nil, sv: nil, waitMs: 0, me: "hc")!
        let v = (room["visitors"] as! [JSON])[0]
        XCTAssertEqual(v["x"] as? Double, 3.5)
        XCTAssertEqual(v["z"] as? Double, -2)
        _ = visits.act(token: token, body: ["client": "c1", "kind": "water", "data": [:] as JSON])
        _ = visits.hostUpdate(token: token, body: ["client": "hc", "kick": 1])
        room = visits.get(token: token, since: nil, sv: nil, waitMs: 0, me: "c1")!
        XCTAssertEqual((room["visitors"] as! [JSON]).count, 0)
        XCTAssertTrue(room["you"] is NSNull)
        XCTAssertEqual((room["events"] as! [JSON]).count, 0)
    }

    func testLeaving() {
        _ = visits.join(token: token, name: "Sam", client: "c1")
        XCTAssertEqual(visits.leave(token: token, body: ["client": "c1"]).0, 200)
        XCTAssertEqual((visits.get(token: token, since: nil, sv: nil, waitMs: 0, me: nil)!["visitors"] as! [JSON]).count, 0)
        XCTAssertEqual(visits.leave(token: token, body: ["client": "c1"]).0, 403)
        XCTAssertEqual(visits.leave(token: token, body: ["client": "hc"]).0, 200)
        let room = visits.get(token: token, since: nil, sv: nil, waitMs: 0, me: nil)!
        XCTAssertEqual(room["stage"] as? String, "closed")
        XCTAssertEqual(visits.join(token: token, name: "Sam", client: "c1").0, 410)
    }

    func testRoutesOverHTTPFront() {
        // the same relay behind the room server's routes
        let open = visits.open(hostName: "H", client: "hh")
        XCTAssertFalse(open.isEmpty)
        let req = HTTPRequest(method: "GET", path: "/visit/nope", query: [:], body: Data())
        XCTAssertEqual(RoomRoutes.handle(req).status, 404)
    }
}
