import Foundation
import CryptoKit
#if canImport(Darwin)
import Darwin
#endif

/// Port of RoomServer.kt's `TradeRooms`: the shared state two collectors see after one scans the
/// other's QR code. The phone that starts the trade hosts the room; the other phone reaches it over
/// the local network. Same protocol and rules as collectify/room.py and the Android version:
///   - a side can only change its own cards/flags, and only with its client id;
///   - changing either side's cards resets both "agreed" flags;
///   - both agreed => stage "swap" and a 4-digit verification code;
///   - "done" only once both sides report they completed;
///   - either side can leave, which closes the room for both.
/// Nothing is persisted.
public final class TradeRooms {
    public static let shared = TradeRooms()
    public static let maxCards = 12
    private let ttl: TimeInterval = 2 * 60 * 60
    private let longPollMax: TimeInterval = 20

    private final class Side {
        var name = ""
        var joined = false
        var client: String?
        var cards: [JSON] = []
        var agreed = false
        var gave: [Bool] = []
        var got: [Bool] = []
        var done = false
    }

    private final class Room {
        let token: String
        var v = 1
        var stage = "edit"
        var closedBy: String?
        let host = Side()
        let guest = Side()
        var code: String?
        var touched = Date()
        init(token: String) { self.token = token }
    }

    private let cond = NSCondition()
    private var rooms = [String: Room]()

    public init() {}

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
        let room = Room(token: token)
        room.host.name = String(hostName.prefix(24))
        room.host.joined = true
        room.host.client = client
        rooms[token] = room
        return token
    }

    public func hasRooms() -> Bool {
        cond.lock()
        defer { cond.unlock() }
        purge()
        return !rooms.isEmpty
    }

    private func purge() {
        let now = Date()
        rooms = rooms.filter { _, r in
            if now.timeIntervalSince(r.touched) > ttl { return false }
            if (r.stage == "closed" || r.stage == "done") && now.timeIntervalSince(r.touched) > 60 { return false }
            return true
        }
    }

    private func sideJSON(_ s: Side) -> JSON {
        ["name": s.name, "joined": s.joined, "cards": s.cards, "agreed": s.agreed, "gave": s.gave, "got": s.got, "done": s.done]
    }

    private func publicJSON(_ r: Room) -> JSON {
        [
            "token": r.token, "v": r.v, "stage": r.stage,
            "closed_by": orNull(r.closedBy), "code": orNull(r.code),
            "host": sideJSON(r.host), "guest": sideJSON(r.guest),
        ]
    }

    private func bump(_ r: Room) {
        r.v += 1
        r.touched = Date()
        cond.broadcast()
    }

    private func codeFor(_ r: Room) -> String {
        let blob = jsonString(r.host.cards) + "|" + jsonString(r.guest.cards) + "|" + r.token
        let digest = SHA256.hash(data: Data(blob.utf8))
        // big-endian digest mod 10000, computed byte by byte
        var rem = 0
        for b in digest { rem = (rem * 256 + Int(b)) % 10000 }
        let s = String(rem)
        return String(repeating: "0", count: max(0, 4 - s.count)) + s
    }

    private func cleanCards(_ arr: [Any]?) -> [JSON] {
        var out = [JSON]()
        for case let c as JSON in (arr ?? []).prefix(Self.maxCards) {
            guard let pid = jInt(c["product_id"]), pid > 0 else { continue }
            let sub = jString(c["sub_type_name"]) ?? "Normal"
            let cond = jString(c["condition"]) ?? "Near Mint"
            out.append([
                "product_id": pid,
                "sub_type_name": String((sub.isEmpty ? "Normal" : sub).prefix(40)),
                "condition": String((cond.isEmpty ? "Near Mint" : cond).prefix(24)),
                "grade": c.has("grade") ? orNull(jDouble(c["grade"])) : NSNull(),
                "digital": jBool(c["digital"]) ?? false,
                "pack": jBool(c["pack"]) ?? false,
                "n": max(1, min(60, jInt(c["n"]) ?? 1)),
            ])
        }
        return out
    }

    private func sameCards(_ a: [JSON], _ b: [JSON]) -> Bool { jsonString(a) == jsonString(b) }

    /// nil if the room doesn't exist. Long-polls while `since` still matches the room version.
    public func get(token: String, since: Int?, waitMs: Int) -> JSON? {
        cond.lock()
        defer { cond.unlock() }
        guard var room = rooms[token] else { return nil }
        let deadline = Date().addingTimeInterval(min(max(Double(waitMs) / 1000, 0), longPollMax))
        while let s = since, room.v == s, room.stage != "closed", Date() < deadline {
            _ = cond.wait(until: deadline)
            guard let r = rooms[token] else { return nil }
            room = r
        }
        return publicJSON(room)
    }

    public func join(token: String, name: String, client: String) -> (Int, JSON) {
        cond.lock()
        defer { cond.unlock() }
        guard let room = rooms[token] else { return (404, err("no such trade")) }
        if room.stage == "closed" { return (410, err("that trade was closed")) }
        let g = room.guest
        if g.joined && g.client != client { return (409, err("this trade already has two people")) }
        if !g.joined {
            g.joined = true
            g.client = client
            g.name = String(name.prefix(24))
            bump(room)
        }
        return (200, publicJSON(room))
    }

    public func update(token: String, body: JSON) -> (Int, JSON) {
        cond.lock()
        defer { cond.unlock() }
        let role = jString(body["role"]) ?? ""
        let client = jString(body["client"]) ?? ""
        if (role != "host" && role != "guest") || client.isEmpty { return (400, err("bad request")) }
        guard let room = rooms[token] else { return (404, err("no such trade")) }
        let side = role == "host" ? room.host : room.guest
        let other = role == "host" ? room.guest : room.host
        if side.client != client { return (403, err("not your side")) }
        if room.stage == "closed" || room.stage == "done" { return (409, err("trade is over")) }

        var dirty = false
        if body.has("name"), let n = jString(body["name"]), String(n.prefix(24)) != side.name {
            side.name = String(n.prefix(24))
            dirty = true
        }
        if body.has("cards") {
            if room.stage != "edit" { return (409, err("terms are locked - leave and start again to change them")) }
            let cards = cleanCards(body["cards"] as? [Any])
            if !sameCards(cards, side.cards) {
                side.cards = cards
                side.agreed = false
                other.agreed = false
                dirty = true
            }
        }
        if body.has("agreed"), room.stage == "edit" {
            let want = jBool(body["agreed"]) ?? false
            if want && room.host.cards.isEmpty && room.guest.cards.isEmpty { return (409, err("add at least one card first")) }
            if want && !other.joined { return (409, err("wait for your partner to join")) }
            if side.agreed != want {
                side.agreed = want
                dirty = true
            }
            if room.host.agreed && room.guest.agreed {
                room.stage = "swap"
                room.code = codeFor(room)
                dirty = true
            }
        }
        if room.stage == "swap" {
            for key in ["gave", "got"] {
                guard let arr = body[key] as? [Any] else { continue }
                let list = arr.prefix(Self.maxCards).map { jBool($0) ?? false }
                if key == "gave" { side.gave = list } else { side.got = list }
                dirty = true
            }
            if (jBool(body["done"]) ?? false) && !side.done {
                side.done = true
                dirty = true
                if room.host.done && room.guest.done { room.stage = "done" }
            }
        }
        if dirty { bump(room) }
        return (200, publicJSON(room))
    }

    public func leave(token: String, body: JSON) -> (Int, JSON) {
        cond.lock()
        defer { cond.unlock() }
        let role = jString(body["role"]) ?? ""
        guard let room = rooms[token] else { return (404, err("no such trade")) }
        let side: Side
        switch role {
        case "host": side = room.host
        case "guest": side = room.guest
        default: return (403, err("not your side"))
        }
        if side.client != (jString(body["client"]) ?? "") { return (403, err("not your side")) }
        if room.stage != "done" {
            room.stage = "closed"
            room.closedBy = role
            bump(room)
        }
        return (200, publicJSON(room))
    }

    private func err(_ msg: String) -> JSON { ["detail": msg] }

    /// Private IPv4 addresses of this phone, Wi-Fi first, then hotspot / other interfaces.
    public static func lanAddresses() -> [String] {
        var found = [(Int, String)]()
        #if canImport(Darwin)
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let first = ifap else { return [] }
        defer { freeifaddrs(ifap) }
        var p: UnsafeMutablePointer<ifaddrs>? = first
        while let cur = p {
            defer { p = cur.pointee.ifa_next }
            guard let sa = cur.pointee.ifa_addr, sa.pointee.sa_family == UInt8(AF_INET) else { continue }
            let flags = Int32(cur.pointee.ifa_flags)
            if (flags & IFF_UP) == 0 || (flags & IFF_LOOPBACK) != 0 { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(sa, socklen_t(sa.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) != 0 { continue }
            let ip = String(cString: host)
            let parts = ip.split(separator: ".").compactMap { Int($0) }
            guard parts.count == 4 else { continue }
            let site = parts[0] == 10 || (parts[0] == 172 && (16...31).contains(parts[1])) || (parts[0] == 192 && parts[1] == 168)
            if !site { continue }
            let name = String(cString: cur.pointee.ifa_name)
            let rank = name == "en0" ? 0 : (name.hasPrefix("bridge") || name.hasPrefix("ap") ? 1 : 2)
            found.append((rank, ip))
        }
        #endif
        return found.sorted { $0.0 < $1.0 }.map { $0.1 }
    }
}

/// The trade-room HTTP front (reachable from the other phone). Same routes and CORS as RoomServer.
public enum RoomRoutes {
    public static let port: UInt16 = 8322

    private static func cors(_ r: HTTPResponse) -> HTTPResponse {
        var r = r
        r.headers["Access-Control-Allow-Origin"] = "*"
        r.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        r.headers["Access-Control-Allow-Headers"] = "*"
        r.headers["Access-Control-Max-Age"] = "600"
        r.headers["Cache-Control"] = "no-store"
        return r
    }

    public static func handle(_ req: HTTPRequest, rooms: TradeRooms = .shared) -> HTTPResponse {
        if req.method == "OPTIONS" { return cors(HTTPResponse(status: 204, contentType: "text/plain", body: Data())) }
        let parts = req.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        func json(_ code: Int, _ o: JSON) -> HTTPResponse { cors(.json(o, status: code)) }
        if parts.count < 2 || parts[0] != "room" { return json(404, ["detail": "not found"]) }
        let token = parts[1]
        let body = parseJSONObject(req.body) ?? [:]
        if parts.count == 2 && req.method == "GET" {
            let since = req.query["v"].flatMap { Int($0) }
            let waitMs = Int(((req.query["wait"].flatMap { Double($0) }) ?? 0) * 1000)
            if let room = rooms.get(token: token, since: since, waitMs: waitMs) { return json(200, room) }
            return json(404, ["detail": "no such trade"])
        }
        if parts.count == 3 && req.method == "POST" {
            switch parts[2] {
            case "join":
                let (c, o) = rooms.join(token: token, name: jString(body["name"]) ?? "Collector", client: jString(body["client"]) ?? "")
                return json(c, o)
            case "update":
                let (c, o) = rooms.update(token: token, body: body)
                return json(c, o)
            case "leave":
                let (c, o) = rooms.leave(token: token, body: body)
                return json(c, o)
            default: break
            }
        }
        return json(404, ["detail": "not found"])
    }
}
