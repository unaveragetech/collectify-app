import XCTest
@testable import CollectifyCore

/// Replays catalog requests that were recorded from the Android (Kotlin) server and checks the Swift
/// port answers the same. Needs the real bundled catalog: set COLLECTIFY_CATALOG_DB to its path
/// (CI downloads it); without it these tests are skipped.
final class GoldenTests: XCTestCase {
    struct Case: Decodable {
        let name: String
        let method: String
        let path: String
        let body: AnyJSON?
        let mode: String
    }

    /// Just enough to re-encode an arbitrary request body.
    struct AnyJSON: Decodable {
        let value: Any
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if c.decodeNil() { value = NSNull() }
            else if let b = try? c.decode(Bool.self) { value = b }
            else if let i = try? c.decode(Int.self) { value = i }
            else if let d = try? c.decode(Double.self) { value = d }
            else if let s = try? c.decode(String.self) { value = s }
            else if let a = try? c.decode([AnyJSON].self) { value = a.map { $0.value } }
            else if let o = try? c.decode([String: AnyJSON].self) { value = o.mapValues { $0.value } }
            else { value = NSNull() }
        }
    }

    var dbPath: String?
    var api: APIServer!
    var goldenDir: URL!

    override func setUpWithError() throws {
        guard let src = ProcessInfo.processInfo.environment["COLLECTIFY_CATALOG_DB"], FileManager.default.fileExists(atPath: src) else {
            throw XCTSkip("COLLECTIFY_CATALOG_DB not set")
        }
        CatalogDB.resetForTesting()
        Match.clearCaches()
        // work on a copy: opening runs migrations
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("golden-\(UUID().uuidString).db")
        try FileManager.default.copyItem(atPath: src, toPath: tmp.path)
        dbPath = tmp.path
        let db = try CatalogDB.open(path: tmp.path)
        api = APIServer(db: db, www: nil)
        goldenDir = Bundle.module.url(forResource: "Golden", withExtension: nil)
    }

    override func tearDownWithError() throws {
        if let p = dbPath { try? FileManager.default.removeItem(atPath: p) }
    }

    func testAgainstAndroidResponses() throws {
        let cases = try JSONDecoder().decode([Case].self, from: Data(contentsOf: goldenDir.appendingPathComponent("cases.json")))
        XCTAssertFalse(cases.isEmpty)
        var failures = [String]()
        for c in cases {
            let expected = try JSONSerialization.jsonObject(with: Data(contentsOf: goldenDir.appendingPathComponent(c.name + ".json")), options: [.fragmentsAllowed])
            let (path, query) = HTTPRequest.parseTarget(c.path)
            let body = c.body.map { jsonData($0.value) } ?? Data()
            let resp = api.handle(HTTPRequest(method: c.method, path: path, query: query, body: body))
            guard resp.status == 200 else {
                failures.append("\(c.name): HTTP \(resp.status) \(resp.text.prefix(200))")
                continue
            }
            let actual = try JSONSerialization.jsonObject(with: resp.body, options: [.fragmentsAllowed])
            if let why = compare(expected, actual, mode: c.mode) { failures.append("\(c.name) [\(c.mode)]: \(why)") }
        }
        XCTAssertTrue(failures.isEmpty, "\n" + failures.joined(separator: "\n"))
    }

    // ---------------------------------------------------------------- comparison

    func compare(_ e: Any, _ a: Any, mode: String) -> String? {
        if mode == "names" {
            guard let eo = e as? JSON, let ao = a as? JSON, let en = eo["names"] as? [String], let an = ao["names"] as? [String] else { return "shape" }
            if Set(en) != Set(an) { return "names differ: expected \(en.count), got \(an.count); missing \(Set(en).subtracting(an).prefix(5)) extra \(Set(an).subtracting(en).prefix(5))" }
            return nil
        }
        if mode.hasPrefix("set:") {
            let key = String(mode.dropFirst(4))
            guard let ea = e as? [JSON], let aa = a as? [JSON] else { return "expected arrays" }
            func index(_ l: [JSON]) -> [String: JSON] { Dictionary(l.map { ("\($0[key] ?? "")", $0) }, uniquingKeysWith: { f, _ in f }) }
            let ei = index(ea), ai = index(aa)
            // the Android build may have used the LIKE fallback; with FTS5 the *set* near the limit can differ,
            // so require the Android results to be a subset of ours when ours is capped by the same limit
            let missing = Set(ei.keys).subtracting(ai.keys)
            if !missing.isEmpty && ai.count < ea.count { return "missing \(missing)" }
            for (k, ev) in ei {
                guard let av = ai[k] else { continue }
                var e2 = ev, a2 = av
                e2["rank"] = nil
                a2["rank"] = nil
                if let why = equal(e2, a2, path: "[\(k)]") { return why }
            }
            return nil
        }
        return equal(e, a, path: "$")
    }

    func equal(_ e: Any, _ a: Any, path: String) -> String? {
        switch (e, a) {
        case (let e as NSNull, _ as NSNull): _ = e; return nil
        case (let e as [String: Any], let a as [String: Any]):
            if Set(e.keys) != Set(a.keys) { return "\(path): keys differ - expected \(e.keys.sorted()) got \(a.keys.sorted())" }
            for k in e.keys.sorted() { if let w = equal(e[k]!, a[k]!, path: path + "." + k) { return w } }
            return nil
        case (let e as [Any], let a as [Any]):
            if e.count != a.count { return "\(path): count \(e.count) vs \(a.count)" }
            for i in e.indices { if let w = equal(e[i], a[i], path: path + "[\(i)]") { return w } }
            return nil
        case (let e as String, let a as String):
            return e == a ? nil : "\(path): '\(e)' vs '\(a)'"
        case (let e as NSNumber, let a as NSNumber):
            let d1 = e.doubleValue, d2 = a.doubleValue
            return abs(d1 - d2) <= 1e-9 * max(1, abs(d1)) ? nil : "\(path): \(d1) vs \(d2)"
        default:
            return "\(path): type mismatch \(type(of: e)) vs \(type(of: a)) (\(e) / \(a))"
        }
    }
}
