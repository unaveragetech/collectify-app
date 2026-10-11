import Foundation

/// Island-visit rooms: the meeting place between an island's owner (the host) and up to four friends on the same
/// network. Port of VisitRooms (RoomServer side, Kotlin) / collectify/visit.py: same protocol and rules, keep them in sync.
///
/// It is a relay, not a game engine: the host's phone owns the island and applies everything visitors do, so this only
/// keeps the host's public island view (`snap`), what visitors asked for (`events`) and the host's answers (`results`),
/// who is here, and a short feed. Only the host can publish / answer / kick; visitors act only as themselves; sizes are
/// capped. Nothing is persisted.
public final class VisitRooms {
    public static let shared = VisitRooms()
    public static let maxVisitors = 4
    private let ttl: TimeInterval = 3 * 60 * 60
    private let longPollMax: TimeInterval = 20
    private let maxSnapBytes = 256 * 1024
    private let maxEventBytes = 4096
    private let maxEvents = 300
    private let maxResults = 300
    private let feedMax = 40
    private let kinds: Set<String> = ["water", "harvest", "feeddish", "waterdish", "pet", "feedmon", "collect", "forage", "gift", "donate", "note", "emote", "pos"]

    private final class Visitor {
        let id: Int
        var name: String
        let client: String
        var x = 0.0, z = 8.0, ry = 0.0
        init(id: Int, name: String, client: String) { self.id = id; self.name = name; self.client = client }
    }

    private struct Event {
        let id: Int
        let vid: Int
        let name: String
        let kind: String
        let data: JSON
    }

    private final class Room {
        let token: String
        var hostName: String
        let hostClient: String
        var v = 1
        var stage = "open"
        var closedBy: String?
        var visitors = [Visitor]()
        var nextVid = 1
        var snap: JSON?
        var snapV = 0
        var events = [Event]()
        var nextEid = 1
        var results = [Int: JSON]()
        var feed = [JSON]()
        var touched = Date()
        init(token: String, hostName: String, hostClient: String) { self.token = token; self.hostName = hostName; self.hostClient = hostClient }
    }

    private let cond = NSCondition()
    private var rooms = [String: Room]()

    public init() {}

    private func err(_ msg: String) -> JSON { ["detail": msg] }

    private func purge() {
        let now = Date()
        rooms = rooms.filter { _, r in
            !(r.touched < now.addingTimeInterval(-ttl) || (r.stage == "closed" && r.touched < now.addingTimeInterval(-60)))
        }
    }

    public func hasRooms() -> Bool {
        cond.lock()
        defer { cond.unlock() }
        purge()
        return rooms.values.contains { $0.stage != "closed" }
    }

    public func open(hostName: String, client: String) -> String {
        cond.lock()
        defer { cond.unlock() }
        purge()
        var bytes = [UInt8](repeating: 0, count: 12)
        for i in bytes.indices { bytes[i] = UInt8.random(in: 0...255) }
        let token = Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        rooms[token] = Room(token: token, hostName: String(hostName.prefix(24)), hostClient: client)
        return token
    }

    private func bump(_ r: Room) {
        r.v += 1
        r.touched = Date()
        cond.broadcast()
    }

    private func addFeed(_ r: Room, _ who: String, _ text: String, _ kind: String = "info") {
        r.feed.append(["t": Int(Date().timeIntervalSince1970 * 1000), "who": String(who.prefix(24)), "text": String(text.prefix(140)), "kind": String(kind.prefix(12))])
        if r.feed.count > feedMax { r.feed.removeFirst(r.feed.count - feedMax) }
    }

    private func publicJSON(_ r: Room, sv: Int?, me: String?) -> JSON {
        var out: JSON = [
            "token": r.token,
            "v": r.v,
            "stage": r.stage,
            "closed_by": orNull(r.closedBy),
            "max": VisitRooms.maxVisitors,
            "host": ["name": r.hostName] as JSON,
            "snap_v": r.snapV,
            "you": NSNull(),
            "visitors": r.visitors.map { ["id": $0.id, "name": $0.name, "x": $0.x, "z": $0.z, "ry": $0.ry] as JSON },
            "events": r.events.map { ["id": $0.id, "vid": $0.vid, "name": $0.name, "kind": $0.kind, "data": $0.data] as JSON },
            "feed": r.feed,
        ]
        var rs = JSON()
        for (k, v) in r.results { rs[String(k)] = v }
        out["results"] = rs
        if sv != r.snapV { out["snap"] = r.snap ?? NSNull() }
        if let me = me, !me.isEmpty {
            if r.hostClient == me { out["you"] = "host" } else if let v = r.visitors.first(where: { $0.client == me }) { out["you"] = ["id": v.id, "name": v.name] as JSON }
        }
        return out
    }

    /// Returns nil if the room doesn't exist. Long-polls while `since` still matches.
    public func get(token: String, since: Int?, sv: Int?, waitMs: Int, me: String?) -> JSON? {
        cond.lock()
        defer { cond.unlock() }
        guard var room = rooms[token] else { return nil }
        let deadline = Date().addingTimeInterval(min(max(Double(waitMs) / 1000, 0), longPollMax))
        while let s = since, room.v == s, room.stage != "closed", Date() < deadline {
            _ = cond.wait(until: deadline)
            guard let r = rooms[token] else { return nil }
            room = r
        }
        return publicJSON(room, sv: sv, me: me)
    }

    public func join(token: String, name: String, client: String) -> (Int, JSON) {
        cond.lock()
        defer { cond.unlock() }
        if client.isEmpty { return (400, err("client id required")) }
        guard let room = rooms[token] else { return (404, err("no such island visit")) }
        if room.stage == "closed" { return (410, err("that visit was closed")) }
        if room.hostClient == client { return (409, err("that's your own island")) }
        if room.visitors.first(where: { $0.client == client }) == nil {
            if room.visitors.count >= VisitRooms.maxVisitors { return (409, err("this island already has \(VisitRooms.maxVisitors) visitors")) }
            let v = Visitor(id: room.nextVid, name: String((name.isEmpty ? "Visitor" : name).prefix(24)), client: client)
            room.nextVid += 1
            room.visitors.append(v)
            addFeed(room, v.name, "arrived", "join")
            bump(room)
        }
        return (200, publicJSON(room, sv: nil, me: client))
    }

    private func num(_ o: JSON, _ key: String, _ lo: Double, _ hi: Double) -> Double {
        guard let d = jDouble(o[key]), !d.isNaN else { return 0 }
        return Swift.max(lo, Swift.min(hi, d))
    }

    public func act(token: String, body: JSON) -> (Int, JSON) {
        cond.lock()
        defer { cond.unlock() }
        let client = jString(body["client"]) ?? ""
        let kind = jString(body["kind"]) ?? ""
        if client.isEmpty || !kinds.contains(kind) { return (400, err("bad request")) }
        var data = JSON()
        if let d = body["data"], !(d is NSNull) {
            guard let dd = d as? JSON else { return (400, err("bad request")) }
            data = dd
        }
        if jsonData(data).count > maxEventBytes { return (400, err("bad request")) }
        guard let room = rooms[token] else { return (404, err("no such island visit")) }
        if room.stage == "closed" { return (410, err("that visit was closed")) }
        guard let v = room.visitors.first(where: { $0.client == client }) else { return (403, err("you aren't visiting this island")) }
        if kind == "pos" {
            let nx = num(data, "x", -60, 60), nz = num(data, "z", -60, 60), nry = num(data, "ry", -7, 7)
            if abs(nx - v.x) + abs(nz - v.z) + abs(nry - v.ry) > 0.02 {
                v.x = nx; v.z = nz; v.ry = nry
                bump(room)
            }
            return (200, ["ok": true])
        }
        if room.events.count >= maxEvents { return (429, err("the island is busy: try again in a moment")) }
        let id = room.nextEid
        room.nextEid += 1
        room.events.append(Event(id: id, vid: v.id, name: v.name, kind: kind, data: data))
        bump(room)
        return (200, ["id": id])
    }

    public func hostUpdate(token: String, body: JSON) -> (Int, JSON) {
        cond.lock()
        defer { cond.unlock() }
        let client = jString(body["client"]) ?? ""
        guard let room = rooms[token] else { return (404, err("no such island visit")) }
        if client.isEmpty || room.hostClient != client { return (403, err("not your island")) }
        if room.stage == "closed" { return (410, err("that visit was closed")) }
        var dirty = false
        if let raw = body["snap"] {
            let snap = raw as? JSON
            if let s = snap, jsonData(s).count > maxSnapBytes { return (413, err("island view too large")) }
            room.snap = snap
            room.snapV += 1
            dirty = true
        }
        if let name = jString(body["name"]), !name.isEmpty, String(name.prefix(24)) != room.hostName {
            room.hostName = String(name.prefix(24))
            dirty = true
        }
        if let ack = body["ack"] as? [Any], !ack.isEmpty {
            let ids = Set(ack.compactMap { jInt($0) })
            room.events.removeAll { ids.contains($0.id) }
            dirty = true
        }
        if let results = body["results"] as? JSON {
            for (k, val) in results {
                guard let res = val as? JSON, let id = Int(k), jsonData(res).count <= maxEventBytes else { continue }
                room.results[id] = res
                dirty = true
            }
            if room.results.count > maxResults {
                for old in room.results.keys.sorted().prefix(room.results.count - maxResults) { room.results.removeValue(forKey: old) }
            }
        }
        if let fd = body["feed"] as? [Any] {
            for f in fd.prefix(20) {
                guard let o = f as? JSON, let text = jString(o["text"]), !text.isEmpty else { continue }
                addFeed(room, jString(o["who"]).flatMap { $0.isEmpty ? nil : $0 } ?? room.hostName, text, jString(o["kind"]).flatMap { $0.isEmpty ? nil : $0 } ?? "info")
                dirty = true
            }
        }
        if let kick = jInt(body["kick"]), let gone = room.visitors.first(where: { $0.id == kick }) {
            room.visitors.removeAll { $0.id == kick }
            room.events.removeAll { $0.vid == kick }
            addFeed(room, gone.name, "was asked to leave", "leave")
            dirty = true
        }
        if dirty { bump(room) }
        return (200, publicJSON(room, sv: nil, me: client))
    }

    public func leave(token: String, body: JSON) -> (Int, JSON) {
        cond.lock()
        defer { cond.unlock() }
        let client = jString(body["client"]) ?? ""
        guard let room = rooms[token] else { return (404, err("no such island visit")) }
        if room.hostClient == client {
            if room.stage != "closed" {
                room.stage = "closed"
                room.closedBy = "host"
                bump(room)
            }
            return (200, publicJSON(room, sv: nil, me: client))
        }
        guard let v = room.visitors.first(where: { $0.client == client }) else { return (403, err("you aren't visiting this island")) }
        room.visitors.removeAll { $0.id == v.id }
        addFeed(room, v.name, "left", "leave")
        bump(room)
        return (200, publicJSON(room, sv: nil, me: client))
    }
}
