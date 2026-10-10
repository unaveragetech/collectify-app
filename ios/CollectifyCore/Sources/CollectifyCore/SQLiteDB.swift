import Foundation
import SQLite3

/// A failed database operation (or any other server-side failure): becomes a 500.
public struct SQLError: Error, CustomStringConvertible {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var description: String { message }
}

/// The client sent something we won't accept: becomes a 400 with `{"detail": message}`.
public struct BadRequest: Error, CustomStringConvertible {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var description: String { message }
}

/// One result row. Columns are read by name; NULL columns come back as nil.
public final class Row {
    let names: [String: Int]
    let values: [Any?]

    init(names: [String: Int], values: [Any?]) {
        self.names = names
        self.values = values
    }

    public func raw(_ c: String) -> Any? {
        guard let i = names[c] else { return nil }
        return values[i]
    }

    public func isNull(_ c: String) -> Bool { raw(c) == nil }

    public func intOrNil(_ c: String) -> Int? {
        switch raw(c) {
        case let v as Int: return v
        case let v as Double: return Int(v)
        case let v as String: return Int(v) ?? Double(v).map { Int($0) }
        default: return nil
        }
    }
    public func int(_ c: String) -> Int { intOrNil(c) ?? 0 }

    public func doubleOrNil(_ c: String) -> Double? {
        switch raw(c) {
        case let v as Double: return v
        case let v as Int: return Double(v)
        case let v as String: return Double(v)
        default: return nil
        }
    }
    public func double(_ c: String) -> Double { doubleOrNil(c) ?? 0 }

    public func stringOrNil(_ c: String) -> String? {
        switch raw(c) {
        case let v as String: return v
        case let v as Int: return String(v)
        case let v as Double: return String(v)
        default: return nil
        }
    }
    public func string(_ c: String) -> String { stringOrNil(c) ?? "" }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// A small, thread-safe wrapper over the system SQLite (which has FTS5 on iOS and macOS).
/// All access is serialised with a recursive lock, which also lets `transaction` hold the
/// connection for its whole duration - the same guarantee Android's SQLiteDatabase gives.
public final class SQLiteDB {
    private var handle: OpaquePointer?
    private let lock = NSRecursiveLock()
    public let path: String

    public init(path: String) throws {
        self.path = path
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(path, &handle, flags, nil) != SQLITE_OK {
            let msg = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "cannot open database"
            if let h = handle { sqlite3_close(h) }
            throw SQLError("Couldn't open the database: \(msg)")
        }
        sqlite3_busy_timeout(handle, 15_000)
        try exec("PRAGMA foreign_keys=ON")
    }

    deinit {
        if let h = handle { sqlite3_close(h) }
    }

    private var lastError: String { handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown error" }

    private func bind(_ stmt: OpaquePointer?, _ args: [Any?]) throws {
        for (i, a) in args.enumerated() {
            let idx = Int32(i + 1)
            var rc: Int32 = SQLITE_OK
            switch a {
            case nil:
                rc = sqlite3_bind_null(stmt, idx)
            case let v as Bool:
                rc = sqlite3_bind_int64(stmt, idx, v ? 1 : 0)
            case let v as Int:
                rc = sqlite3_bind_int64(stmt, idx, Int64(v))
            case let v as Int64:
                rc = sqlite3_bind_int64(stmt, idx, v)
            case let v as Int32:
                rc = sqlite3_bind_int64(stmt, idx, Int64(v))
            case let v as Double:
                rc = sqlite3_bind_double(stmt, idx, v)
            case let v as String:
                rc = sqlite3_bind_text(stmt, idx, v, -1, SQLITE_TRANSIENT)
            default:
                throw SQLError("Unsupported SQL argument type \(type(of: a))")
            }
            if rc != SQLITE_OK { throw SQLError(lastError) }
        }
    }

    private func column(_ stmt: OpaquePointer?, _ i: Int32) -> Any? {
        switch sqlite3_column_type(stmt, i) {
        case SQLITE_INTEGER: return Int(sqlite3_column_int64(stmt, i))
        case SQLITE_FLOAT: return sqlite3_column_double(stmt, i)
        case SQLITE_TEXT:
            if let c = sqlite3_column_text(stmt, i) { return String(cString: c) }
            return ""
        case SQLITE_BLOB:
            let n = Int(sqlite3_column_bytes(stmt, i))
            if let p = sqlite3_column_blob(stmt, i) { return Data(bytes: p, count: n) }
            return Data()
        default: return nil
        }
    }

    @discardableResult
    public func query(_ sql: String, _ args: [Any?] = []) throws -> [Row] {
        lock.lock()
        defer { lock.unlock() }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK else { throw SQLError(lastError) }
        defer { sqlite3_finalize(stmt) }
        try bind(stmt, args)
        let n = sqlite3_column_count(stmt)
        var names = [String: Int]()
        for i in 0..<n {
            if let c = sqlite3_column_name(stmt, i) { names[String(cString: c)] = Int(i) }
        }
        var rows = [Row]()
        while true {
            let rc = sqlite3_step(stmt)
            if rc == SQLITE_ROW {
                var vals = [Any?]()
                vals.reserveCapacity(Int(n))
                for i in 0..<n { vals.append(column(stmt, i)) }
                rows.append(Row(names: names, values: vals))
            } else if rc == SQLITE_DONE {
                break
            } else {
                throw SQLError(lastError)
            }
        }
        return rows
    }

    public func exec(_ sql: String, _ args: [Any?] = []) throws {
        lock.lock()
        defer { lock.unlock() }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK else { throw SQLError(lastError) }
        defer { sqlite3_finalize(stmt) }
        try bind(stmt, args)
        while true {
            let rc = sqlite3_step(stmt)
            if rc == SQLITE_ROW { continue }
            if rc == SQLITE_DONE { break }
            throw SQLError(lastError)
        }
    }

    /// First column of the first row (nil when there is no row or the value is NULL).
    public func scalar(_ sql: String, _ args: [Any?] = []) throws -> Any? {
        guard let row = try query(sql, args).first, let v = row.values.first else { return nil }
        return v
    }

    public func scalarInt(_ sql: String, _ args: [Any?] = []) throws -> Int {
        switch try scalar(sql, args) {
        case let v as Int: return v
        case let v as Double: return Int(v)
        case let v as String: return Int(v) ?? 0
        default: return 0
        }
    }

    public func scalarString(_ sql: String, _ args: [Any?] = []) throws -> String? {
        switch try scalar(sql, args) {
        case let v as String: return v
        case let v as Int: return String(v)
        case let v as Double: return String(v)
        default: return nil
        }
    }

    /// Runs `body` inside BEGIN/COMMIT, rolling back if it throws. Holds the connection throughout.
    public func transaction<T>(_ body: () throws -> T) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        try exec("BEGIN IMMEDIATE")
        do {
            let r = try body()
            try exec("COMMIT")
            return r
        } catch {
            try? exec("ROLLBACK")
            throw error
        }
    }

    public func getMeta(_ key: String) throws -> String? {
        try scalarString("SELECT value FROM meta WHERE key=?", [key])
    }

    public func setMeta(_ key: String, _ value: String) throws {
        try exec("INSERT INTO meta(key, value) VALUES(?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value", [key, value])
    }
}
