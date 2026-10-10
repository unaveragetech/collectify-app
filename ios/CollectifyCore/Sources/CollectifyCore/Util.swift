import Foundation

public typealias JSON = [String: Any]

/// JSON null (Swift dictionaries drop nil, so nulls must be explicit).
let NULL: Any = NSNull()

@inline(__always) func orNull(_ v: Any?) -> Any { v ?? NSNull() }

// ---------------------------------------------------------------- time

private let utcCalendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}()

private func pad(_ n: Int, _ w: Int = 2) -> String {
    let s = String(n)
    return String(repeating: "0", count: max(0, w - s.count)) + s
}

/// "2026-10-10T12:00:00Z" - same format the Android and Python versions store.
func utcNow(_ date: Date = Date()) -> String {
    let c = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    return "\(pad(c.year!, 4))-\(pad(c.month!))-\(pad(c.day!))T\(pad(c.hour!)):\(pad(c.minute!)):\(pad(c.second!))Z"
}

func utcToday(_ date: Date = Date()) -> String {
    let c = utcCalendar.dateComponents([.year, .month, .day], from: date)
    return "\(pad(c.year!, 4))-\(pad(c.month!))-\(pad(c.day!))"
}

func newId() -> String {
    String(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(16))
}

func round2(_ v: Double) -> Double { (v * 100).rounded(.toNearestOrEven) / 100 }

// ---------------------------------------------------------------- JSON value coercion (org.json style)

func jInt(_ v: Any?) -> Int? {
    switch v {
    case let n as NSNumber: return n.intValue
    case let s as String:
        let t = s.trimmingCharacters(in: .whitespaces)
        return Int(t) ?? Double(t).map { Int($0) }
    default: return nil
    }
}

func jDouble(_ v: Any?) -> Double? {
    switch v {
    case let n as NSNumber: return n.doubleValue
    case let s as String: return Double(s.trimmingCharacters(in: .whitespaces))
    default: return nil
    }
}

func jBool(_ v: Any?) -> Bool? {
    switch v {
    case let n as NSNumber: return n.boolValue
    case let s as String: return s == "true" ? true : (s == "false" ? false : nil)
    default: return nil
    }
}

/// A string value; numbers are rendered like org.json would.
func jString(_ v: Any?) -> String? {
    switch v {
    case let s as String: return s
    case let n as NSNumber: return n.stringValue
    default: return nil
    }
}

extension Dictionary where Key == String, Value == Any {
    /// Present and not JSON null.
    func has(_ k: String) -> Bool {
        if let v = self[k] { return !(v is NSNull) }
        return false
    }
    func isNullOrMissing(_ k: String) -> Bool { !has(k) }
}

func parseJSONObject(_ data: Data) -> JSON? {
    guard !data.isEmpty, let o = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else { return nil }
    return o as? JSON
}

func jsonData(_ any: Any) -> Data {
    (try? JSONSerialization.data(withJSONObject: any, options: [.fragmentsAllowed, .sortedKeys])) ?? Data("null".utf8)
}

func jsonString(_ any: Any) -> String {
    String(data: jsonData(any), encoding: .utf8) ?? "null"
}

extension Array {
    func take(_ n: Int) -> [Element] { Array(prefix(Swift.max(0, n))) }
}

extension Array where Element: Hashable {
    /// Order-preserving de-duplication (Kotlin's `distinct()`).
    func distinctOrdered() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension String {
    var isBlankString: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

// ---------------------------------------------------------------- HTTP types

public struct HTTPRequest {
    public var method: String
    public var path: String
    public var query: [String: String]
    public var headers: [String: String]
    public var body: Data

    public init(method: String, path: String, query: [String: String] = [:], headers: [String: String] = [:], body: Data = Data()) {
        self.method = method
        self.path = path
        self.query = query
        self.headers = headers
        self.body = body
    }

    /// Parses "/path?a=1&b=two" into path + first-value-wins query parameters.
    public static func parseTarget(_ target: String) -> (String, [String: String]) {
        var path = target
        var q = [String: String]()
        if let i = target.firstIndex(of: "?") {
            path = String(target[..<i])
            let qs = target[target.index(after: i)...]
            for part in qs.split(separator: "&", omittingEmptySubsequences: true) {
                let kv = part.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                let k = decode(String(kv[0]))
                let v = kv.count > 1 ? decode(String(kv[1])) : ""
                if q[k] == nil { q[k] = v }
            }
        }
        return (decode(path), q)
    }

    private static func decode(_ s: String) -> String {
        let spaced = s.replacingOccurrences(of: "+", with: " ")
        return spaced.removingPercentEncoding ?? spaced
    }
}

public struct HTTPResponse {
    public var status: Int
    public var contentType: String
    public var body: Data
    public var headers: [String: String]

    public init(status: Int, contentType: String, body: Data, headers: [String: String] = [:]) {
        self.status = status
        self.contentType = contentType
        self.body = body
        self.headers = headers
    }

    public static func json(_ obj: Any, status: Int = 200) -> HTTPResponse {
        HTTPResponse(status: status, contentType: "application/json", body: jsonData(obj))
    }

    public static func detail(_ msg: String, status: Int) -> HTTPResponse {
        .json(["detail": msg], status: status)
    }

    public var text: String { String(data: body, encoding: .utf8) ?? "" }
}
