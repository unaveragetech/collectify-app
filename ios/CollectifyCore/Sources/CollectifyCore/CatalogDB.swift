import Foundation

/// Port of Db.kt: the on-device schema, first-launch copy of the bundled catalog, the catalog
/// merge that brings an existing install forward when a new app version ships a newer catalog,
/// and the FTS5 / column reconciliation that runs on every open.
public enum CatalogDB {
    public static let bundledDBName = "collectify.db"
    public static let versionFileName = "catalog_version.txt"

    // ---------------------------------------------------------------- opening

    /// Opens (creating and seeding if needed) the database at `path`. If the file is empty / brand
    /// new (user_version 0) the full schema is created, exactly like SQLiteOpenHelper.onCreate.
    public static func open(path: String) throws -> SQLiteDB {
        let db = try SQLiteDB(path: path)
        let version = try db.scalarInt("PRAGMA user_version")
        if version == 0 {
            try onCreate(db)
            try db.exec("PRAGMA user_version=1")
        }
        try onOpen(db)
        return db
    }

    static func onCreate(_ db: SQLiteDB) throws {
        try db.exec("""
            CREATE TABLE IF NOT EXISTS categories (
                category_id   INTEGER PRIMARY KEY,
                name          TEXT NOT NULL,
                display_name  TEXT,
                seo_name      TEXT,
                is_scannable  INTEGER NOT NULL DEFAULT 0,
                popularity    INTEGER,
                modified_on   TEXT,
                synced_at     TEXT
            )
            """)
        try db.exec("""
            CREATE TABLE IF NOT EXISTS groups (
                group_id        INTEGER PRIMARY KEY,
                category_id     INTEGER NOT NULL REFERENCES categories(category_id),
                name            TEXT NOT NULL,
                abbreviation    TEXT,
                is_supplemental INTEGER NOT NULL DEFAULT 0,
                published_on    TEXT,
                modified_on     TEXT,
                synced_at       TEXT
            )
            """)
        try db.exec("CREATE INDEX IF NOT EXISTS idx_groups_category ON groups(category_id)")
        try db.exec("""
            CREATE TABLE IF NOT EXISTS products (
                product_id    INTEGER PRIMARY KEY,
                group_id      INTEGER NOT NULL REFERENCES groups(group_id),
                category_id   INTEGER NOT NULL REFERENCES categories(category_id),
                name          TEXT NOT NULL,
                clean_name    TEXT,
                image_url     TEXT,
                url           TEXT,
                number        TEXT,
                rarity        TEXT,
                artist        TEXT,
                rules_text    TEXT,
                extended_data TEXT,
                modified_on   TEXT,
                synced_at     TEXT
            )
            """)
        try db.exec("CREATE INDEX IF NOT EXISTS idx_products_group ON products(group_id)")
        try db.exec("CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id)")
        try db.exec("CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)")
        try db.exec("CREATE INDEX IF NOT EXISTS idx_products_clean_name ON products(clean_name)")
        try db.exec("""
            CREATE TABLE IF NOT EXISTS prices (
                product_id        INTEGER NOT NULL REFERENCES products(product_id),
                sub_type_name     TEXT NOT NULL DEFAULT 'Normal',
                price_date        TEXT NOT NULL,
                low_price         REAL,
                mid_price         REAL,
                high_price        REAL,
                market_price      REAL,
                direct_low_price  REAL,
                captured_at       TEXT NOT NULL,
                PRIMARY KEY (product_id, sub_type_name, price_date)
            )
            """)
        try db.exec("CREATE INDEX IF NOT EXISTS idx_prices_product_date ON prices(product_id, price_date)")
        try db.exec("CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT)")
        let fts = createFtsIndex(db, ifNotExists: true)
        try db.setMeta("fts5_available", fts ? "1" : "0")
        try db.exec("""
            CREATE TABLE IF NOT EXISTS binders (
                id          TEXT PRIMARY KEY,
                name        TEXT NOT NULL,
                category_id INTEGER REFERENCES categories(category_id),
                page_size   INTEGER NOT NULL DEFAULT 25,
                theme       TEXT,
                sort_order  INTEGER NOT NULL DEFAULT 0,
                created_at  TEXT NOT NULL
            )
            """)
        try db.exec("""
            CREATE TABLE IF NOT EXISTS collection_items (
                id                TEXT PRIMARY KEY,
                binder_id         TEXT NOT NULL REFERENCES binders(id),
                slot              INTEGER NOT NULL,
                product_id        INTEGER NOT NULL REFERENCES products(product_id),
                sub_type_name     TEXT NOT NULL DEFAULT 'Normal',
                condition         TEXT NOT NULL DEFAULT 'Near Mint',
                quantity          INTEGER NOT NULL DEFAULT 1,
                source            TEXT NOT NULL DEFAULT 'scan',
                raw_query         TEXT,
                match_confidence  REAL,
                acquired_at       TEXT NOT NULL,
                grade             REAL,
                grade_data        TEXT
            )
            """)
        try db.exec("CREATE INDEX IF NOT EXISTS idx_collection_product ON collection_items(product_id)")
        try db.exec("CREATE INDEX IF NOT EXISTS idx_collection_binder ON collection_items(binder_id, slot)")
        try db.exec("""
            CREATE TABLE IF NOT EXISTS wishlist_items (
                id            TEXT PRIMARY KEY,
                product_id    INTEGER NOT NULL REFERENCES products(product_id),
                sub_type_name TEXT NOT NULL DEFAULT 'Normal',
                note          TEXT,
                added_at      TEXT NOT NULL
            )
            """)
        try db.exec("CREATE INDEX IF NOT EXISTS idx_wishlist_product ON wishlist_items(product_id)")
        try createTradesTable(db)
        try db.exec("INSERT OR IGNORE INTO binders(id, name, category_id, page_size, sort_order, created_at) VALUES('default', 'My Binder', NULL, 9, 0, ?)", [utcNow()])
    }

    // Reconciles FTS5, columns and one-time migrations. Runs once per process, like Db.onOpen.
    private static var reconciled = Set<String>()
    private static let reconcileLock = NSLock()
    private static var ftsCache = [String: Bool]()

    static func onOpen(_ db: SQLiteDB) throws {
        reconcileLock.lock()
        defer { reconcileLock.unlock() }
        if reconciled.contains(db.path) { return }
        try reconcileFts(db)
        try ensureArtistColumn(db)
        try ensureColumn(db, "rules_text")
        try ensureColumn(db, "grade", "REAL", table: "collection_items")
        try ensureColumn(db, "grade_data", "TEXT", table: "collection_items")
        try createTradesTable(db)
        try ensureBinderLayoutV2(db)
        try db.exec("CREATE INDEX IF NOT EXISTS idx_products_clean_name ON products(clean_name)")
        reconciled.insert(db.path)
    }

    /// Forget the once-per-process flags (tests that re-open the same file).
    static func resetForTesting() {
        reconcileLock.lock()
        reconciled.removeAll()
        ftsCache.removeAll()
        reconcileLock.unlock()
    }

    // ---------------------------------------------------------------- FTS5

    public static func isFtsAvailable(_ db: SQLiteDB) -> Bool {
        reconcileLock.lock()
        defer { reconcileLock.unlock() }
        if let c = ftsCache[db.path] { return c }
        let r = ((try? db.getMeta("fts5_available")) ?? nil) == "1"
        ftsCache[db.path] = r
        return r
    }

    private static func setFtsMeta(_ db: SQLiteDB, _ available: Bool) throws {
        try db.setMeta("fts5_available", available ? "1" : "0")
        ftsCache[db.path] = available
    }

    @discardableResult
    private static func createFtsIndex(_ db: SQLiteDB, ifNotExists: Bool) -> Bool {
        let ine = ifNotExists ? "IF NOT EXISTS " : ""
        do {
            try db.exec("""
                CREATE VIRTUAL TABLE \(ine)products_fts USING fts5(
                    name, clean_name, number,
                    content='products', content_rowid='product_id'
                )
                """)
            try db.exec("""
                CREATE TRIGGER \(ine)products_ai AFTER INSERT ON products BEGIN
                    INSERT INTO products_fts(rowid, name, clean_name, number)
                    VALUES (new.product_id, new.name, new.clean_name, new.number);
                END
                """)
            try db.exec("""
                CREATE TRIGGER \(ine)products_ad AFTER DELETE ON products BEGIN
                    INSERT INTO products_fts(products_fts, rowid, name, clean_name, number)
                    VALUES('delete', old.product_id, old.name, old.clean_name, old.number);
                END
                """)
            try db.exec("""
                CREATE TRIGGER \(ine)products_au AFTER UPDATE ON products BEGIN
                    INSERT INTO products_fts(products_fts, rowid, name, clean_name, number)
                    VALUES('delete', old.product_id, old.name, old.clean_name, old.number);
                    INSERT INTO products_fts(rowid, name, clean_name, number)
                    VALUES (new.product_id, new.name, new.clean_name, new.number);
                END
                """)
            if ifNotExists { try db.exec("INSERT INTO products_fts(products_fts) VALUES('rebuild')") }
            return true
        } catch {
            return false
        }
    }

    private static func probeFts(_ db: SQLiteDB) -> Bool {
        do {
            try db.exec("CREATE VIRTUAL TABLE IF NOT EXISTS __fts_probe USING fts5(x)")
            try db.exec("DROP TABLE IF EXISTS __fts_probe")
            return true
        } catch {
            return false
        }
    }

    /// The bundled catalog was built on desktop (always FTS5); trust *this* device's SQLite instead.
    private static func reconcileFts(_ db: SQLiteDB) throws {
        let has = probeFts(db)
        let stored = try db.getMeta("fts5_available")
        if (has && stored == "1") || (!has && stored == "0") {
            ftsCache[db.path] = has
            return
        }
        if !has {
            for sql in ["DROP TRIGGER IF EXISTS products_ai", "DROP TRIGGER IF EXISTS products_ad", "DROP TRIGGER IF EXISTS products_au", "DROP TABLE IF EXISTS products_fts"] {
                try? db.exec(sql)
            }
            try setFtsMeta(db, false)
        } else {
            let created = createFtsIndex(db, ifNotExists: true)
            try setFtsMeta(db, created)
        }
    }

    // ---------------------------------------------------------------- idempotent migrations

    static func createTradesTable(_ db: SQLiteDB) throws {
        try db.exec("""
            CREATE TABLE IF NOT EXISTS trades (
                id            TEXT PRIMARY KEY,
                session       TEXT NOT NULL,
                role          TEXT NOT NULL,
                partner_name  TEXT,
                gave          TEXT NOT NULL,
                got           TEXT NOT NULL,
                status        TEXT NOT NULL,
                code          TEXT,
                created_at    TEXT NOT NULL,
                completed_at  TEXT
            )
            """)
    }

    private static func columns(_ db: SQLiteDB, _ table: String) throws -> Set<String> {
        Set(try db.query("PRAGMA table_info(\(table))").map { $0.string("name") })
    }

    private static func ensureColumn(_ db: SQLiteDB, _ column: String, _ type: String = "TEXT", table: String = "products") throws {
        if !(try columns(db, table)).contains(column) { try db.exec("ALTER TABLE \(table) ADD COLUMN \(column) \(type)") }
    }

    /// One time: the starter binder becomes 3x3.
    private static func ensureBinderLayoutV2(_ db: SQLiteDB) throws {
        if try db.getMeta("binder_layout_v2") == "1" { return }
        try db.exec("UPDATE binders SET page_size=9 WHERE id='default' AND page_size=25")
        try db.setMeta("binder_layout_v2", "1")
    }

    private static func ensureArtistColumn(_ db: SQLiteDB) throws {
        if !(try columns(db, "products")).contains("artist") { try db.exec("ALTER TABLE products ADD COLUMN artist TEXT") }
        if try db.getMeta("artist_backfilled") == "1" { return }
        let rows = try db.query("SELECT product_id, extended_data FROM products WHERE artist IS NULL AND extended_data IS NOT NULL")
        try db.transaction {
            for r in rows {
                guard let text = r.stringOrNil("extended_data"),
                      let data = text.data(using: .utf8),
                      let arr = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else { continue }
                for entry in arr where (entry["name"] as? String)?.lowercased() == "artist" {
                    if let v = entry["value"] as? String, !v.isBlankString {
                        try db.exec("UPDATE products SET artist=? WHERE product_id=?", [v, r.int("product_id")])
                    }
                    break
                }
            }
        }
        try db.setMeta("artist_backfilled", "1")
    }

    // ---------------------------------------------------------------- bundled catalog

    /// First launch: copy the pre-synced catalog out of the app bundle. Copies to a temp file and
    /// renames, so a copy that is killed half way never leaves a truncated database at `dest`.
    public static func copyBundledIfNeeded(bundled: URL?, dest: URL, progress: ((String) -> Void)? = nil) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: dest.path) { return }
        try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let bundled = bundled, fm.fileExists(atPath: bundled.path) else { return } // no bundled catalog: start empty
        progress?("Setting up the card catalog…")
        let tmp = dest.deletingLastPathComponent().appendingPathComponent("collectify.db.tmp")
        try? fm.removeItem(at: tmp)
        do {
            try fm.copyItem(at: bundled, to: tmp)
            try fm.moveItem(at: tmp, to: dest)
        } catch {
            try? fm.removeItem(at: tmp)
            throw error
        }
    }

    /// An app update only brings a newer catalog if `catalog_version.txt` is higher than what the
    /// device recorded: then the catalog tables (never binders/collection/wishlist) are replaced.
    public static func mergeCatalogUpdateIfNeeded(db: SQLiteDB, bundled: URL?, versionFile: URL?, onStart: (() -> Void)? = nil) {
        let fm = FileManager.default
        guard let bundled = bundled, fm.fileExists(atPath: bundled.path),
              let vf = versionFile, let vtext = try? String(contentsOf: vf, encoding: .utf8) else { return }
        let bundledVersion = vtext.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let bundledNum = Int(bundledVersion) else { return }
        let current = (try? db.getMeta("catalog_version")).flatMap { $0 }.flatMap { Int($0) }
        if let c = current, c >= bundledNum { return }
        onStart?()
        let tmp = URL(fileURLWithPath: db.path).deletingLastPathComponent().appendingPathComponent("collectify_update.db.tmp")
        try? fm.removeItem(at: tmp)
        defer { try? fm.removeItem(at: tmp) }
        do {
            try fm.copyItem(at: bundled, to: tmp)
            let escaped = tmp.path.replacingOccurrences(of: "'", with: "''")
            try db.exec("ATTACH DATABASE '\(escaped)' AS bundled")
            do {
                // foreign_keys can't be toggled inside a transaction; the referenced rows are
                // briefly gone between each DELETE and the INSERT of the same table.
                try db.exec("PRAGMA foreign_keys=OFF")
                try db.transaction {
                    for table in ["categories", "groups", "products", "prices"] {
                        try db.exec("DELETE FROM main.\(table)")
                        try db.exec("INSERT INTO main.\(table) SELECT * FROM bundled.\(table)")
                    }
                    try db.setMeta("catalog_version", bundledVersion)
                }
                try db.exec("PRAGMA foreign_keys=ON")
            } catch {
                try? db.exec("PRAGMA foreign_keys=ON")
                try? db.exec("DETACH DATABASE bundled")
                throw error
            }
            try? db.exec("DETACH DATABASE bundled")
            if isFtsAvailable(db) { try? db.exec("INSERT INTO products_fts(products_fts) VALUES('rebuild')") }
        } catch {
            // keep the existing catalog; the version marker did not advance so the next launch retries
        }
    }
}
