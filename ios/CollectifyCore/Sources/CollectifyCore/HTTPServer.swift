import Foundation
import Network

/// A minimal HTTP/1.1 server on Network.framework: one request per connection (`Connection: close`),
/// bodies by Content-Length. It stands in for NanoHTTPD, so the WebView can keep talking to
/// http://127.0.0.1:8321 exactly like on Android (and localhost is a secure context for the camera).
public final class HTTPServer {
    public enum Binding { case loopback, allInterfaces }

    private let port: UInt16
    private let binding: Binding
    private let handler: (HTTPRequest) -> HTTPResponse
    private let queue = DispatchQueue(label: "collectify.http.\(UUID().uuidString.prefix(6))", qos: .userInitiated, attributes: .concurrent)
    private var listener: NWListener?
    private let stateLock = NSLock()
    public private(set) var isRunning = false
    public private(set) var lastError: String?
    private let maxBody = 16 * 1024 * 1024

    public init(port: UInt16, binding: Binding, handler: @escaping (HTTPRequest) -> HTTPResponse) {
        self.port = port
        self.binding = binding
        self.handler = handler
    }

    /// Starts listening; returns once the socket is ready (or failed).
    @discardableResult
    public func start() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        if isRunning { return true }
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { return false }
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        let l: NWListener
        do {
            if binding == .loopback {
                params.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: nwPort)
                l = try NWListener(using: params)
            } else {
                l = try NWListener(using: params, on: nwPort)
                // advertising on Bonjour is also what makes iOS ask for Local Network access up front
                l.service = NWListener.Service(name: nil, type: "_collectify._tcp")
            }
        } catch {
            lastError = "\(error)"
            return false
        }
        let ready = DispatchSemaphore(value: 0)
        var signalled = false
        l.stateUpdateHandler = { [weak self] st in
            switch st {
            case .ready:
                if !signalled { signalled = true; ready.signal() }
            case .failed(let e):
                self?.lastError = "\(e)"
                self?.stateLock.lock()
                self?.isRunning = false
                self?.stateLock.unlock()
                if !signalled { signalled = true; ready.signal() }
            case .cancelled:
                if !signalled { signalled = true; ready.signal() }
            default: break
            }
        }
        l.newConnectionHandler = { [weak self] conn in self?.accept(conn) }
        l.start(queue: queue)
        _ = ready.wait(timeout: .now() + 5)
        if case .ready = l.state {
            listener = l
            isRunning = true
            return true
        }
        l.cancel()
        return false
    }

    public func stop() {
        stateLock.lock()
        defer { stateLock.unlock() }
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    /// iOS may have torn the socket down while the app was suspended: bring it back if so.
    public func ensureRunning() {
        stateLock.lock()
        let bad: Bool
        if let l = listener {
            if case .ready = l.state { bad = false } else { bad = true }
        } else { bad = true }
        stateLock.unlock()
        if bad {
            stop()
            start()
        }
    }

    // ---------------------------------------------------------------- connections

    private func accept(_ conn: NWConnection) {
        conn.start(queue: queue)
        let timeout = DispatchWorkItem { conn.cancel() }
        queue.asyncAfter(deadline: .now() + 120, execute: timeout)
        receive(conn, Data(), timeout)
    }

    private enum Parsed {
        case need
        case bad
        case request(HTTPRequest)
    }

    private func parse(_ buf: Data) -> Parsed {
        let sep = Data("\r\n\r\n".utf8)
        guard let range = buf.range(of: sep) else { return buf.count > 65536 ? .bad : .need }
        guard let head = String(data: buf[buf.startIndex..<range.lowerBound], encoding: .utf8) else { return .bad }
        var lines = head.components(separatedBy: "\r\n")
        let first = lines.removeFirst().split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map(String.init)
        guard first.count >= 2 else { return .bad }
        var headers = [String: String]()
        for l in lines {
            if let i = l.firstIndex(of: ":") {
                headers[l[..<i].lowercased()] = l[l.index(after: i)...].trimmingCharacters(in: .whitespaces)
            }
        }
        let bodyStart = range.upperBound
        let length = Int(headers["content-length"] ?? "0") ?? 0
        if length > maxBody { return .bad }
        if buf.count - (bodyStart - buf.startIndex) < length { return .need }
        let body = length > 0 ? Data(buf[bodyStart..<(bodyStart + length)]) : Data()
        let (path, query) = HTTPRequest.parseTarget(first[1])
        return .request(HTTPRequest(method: first[0].uppercased(), path: path, query: query, headers: headers, body: body))
    }

    private func receive(_ conn: NWConnection, _ buf: Data, _ timeout: DispatchWorkItem) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 256 * 1024) { [weak self] data, _, isComplete, error in
            guard let self = self else { conn.cancel(); return }
            var buf = buf
            if let d = data { buf.append(d) }
            switch self.parse(buf) {
            case .request(let req):
                self.queue.async {
                    let resp = self.handler(req)
                    self.send(conn, resp, timeout)
                }
            case .bad:
                self.send(conn, HTTPResponse(status: 400, contentType: "text/plain", body: Data("bad request".utf8)), timeout)
            case .need:
                if error != nil || isComplete { timeout.cancel(); conn.cancel() }
                else { self.receive(conn, buf, timeout) }
            }
        }
    }

    private static let reasons: [Int: String] = [
        200: "OK", 204: "No Content", 400: "Bad Request", 403: "Forbidden", 404: "Not Found",
        409: "Conflict", 410: "Gone", 500: "Internal Server Error",
    ]

    private func send(_ conn: NWConnection, _ resp: HTTPResponse, _ timeout: DispatchWorkItem) {
        var head = "HTTP/1.1 \(resp.status) \(Self.reasons[resp.status] ?? "OK")\r\n"
        head += "Content-Type: \(resp.contentType)\r\n"
        head += "Content-Length: \(resp.body.count)\r\n"
        head += "Connection: close\r\n"
        for (k, v) in resp.headers { head += "\(k): \(v)\r\n" }
        head += "\r\n"
        var out = Data(head.utf8)
        out.append(resp.body)
        conn.send(content: out, contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { _ in
            timeout.cancel()
            conn.cancel()
        })
    }
}
