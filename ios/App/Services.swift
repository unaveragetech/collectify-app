import Foundation
import CollectifyCore

/// Owns the database, the embedded HTTP servers and the bundled catalog setup.
final class Services {
    static let apiPort: UInt16 = 8321
    static let baseURL = URL(string: "http://127.0.0.1:8321/")!

    private(set) var db: SQLiteDB?
    private var api: APIServer?
    private var server: HTTPServer?
    private var roomServer: HTTPServer?
    private var idleTimer: Timer?
    private let lock = NSLock()

    var isReady: Bool { server?.isRunning ?? false }

    /// Copies the bundled catalog on first launch, merges a newer one after an update, opens the
    /// database and starts the local server. Blocking: call it off the main thread.
    func start(progress: @escaping (String) -> Void) throws {
        let fm = FileManager.default
        let support = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dest = support.appendingPathComponent("collectify.db")
        let bundledDB = Bundle.main.url(forResource: "collectify", withExtension: "db")
        let versionFile = Bundle.main.url(forResource: "catalog_version", withExtension: "txt")

        try CatalogDB.copyBundledIfNeeded(bundled: bundledDB, dest: dest, progress: progress)
        let db = try CatalogDB.open(path: dest.path)
        CatalogDB.mergeCatalogUpdateIfNeeded(db: db, bundled: bundledDB, versionFile: versionFile) {
            progress("Updating card catalog… this can take a minute or two, please don't close the app.")
        }
        progress("Starting Collectify…")

        let www = Bundle.main.resourceURL?.appendingPathComponent("www")
        let api = APIServer(db: db, www: www)
        api.onRoomOpen = { [weak self] in self?.ensureRoomServer() }
        let server = HTTPServer(port: Self.apiPort, binding: .loopback) { [weak self] req in
            #if DEBUG
            if req.path == "/__debug/js", let me = self { return me.runDebugJS(req) }
            #endif
            return api.handle(req)
        }
        if !server.start() { throw SQLError("Couldn't start the local server" + (server.lastError.map { ": \($0)" } ?? ".")) }

        lock.lock()
        self.db = db
        self.api = api
        self.server = server
        lock.unlock()
    }

    #if DEBUG
    /// Debug builds only (CI smoke test): POST some JavaScript to /__debug/js and get its result back.
    var debugEval: ((String, @escaping (String) -> Void) -> Void)?

    private func runDebugJS(_ req: HTTPRequest) -> HTTPResponse {
        guard let eval = debugEval else { return HTTPResponse(status: 503, contentType: "text/plain", body: Data("no web view yet".utf8)) }
        let code = String(data: req.body, encoding: .utf8) ?? ""
        let sem = DispatchSemaphore(value: 0)
        var result = ""
        DispatchQueue.main.async {
            eval(code) { r in
                result = r
                sem.signal()
            }
        }
        if sem.wait(timeout: .now() + 60) == .timedOut { result = "{\"error\":\"timeout\"}" }
        return HTTPResponse(status: 200, contentType: "application/json", body: Data(result.utf8))
    }
    #endif

    func ensureRunning() {
        server?.ensureRunning()
        if TradeRooms.shared.hasRooms() { roomServer?.ensureRunning() }
    }

    // In-person trades: the port is only open while a trade room is.
    private func ensureRoomServer() {
        lock.lock()
        defer { lock.unlock() }
        if roomServer == nil {
            roomServer = HTTPServer(port: RoomRoutes.port, binding: .allInterfaces) { RoomRoutes.handle($0) }
        }
        roomServer?.start()
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.idleTimer == nil else { return }
            self.idleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if !TradeRooms.shared.hasRooms() {
                    self.roomServer?.stop()
                    self.idleTimer?.invalidate()
                    self.idleTimer = nil
                }
            }
        }
    }
}
