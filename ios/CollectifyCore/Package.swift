// swift-tools-version:5.9
import PackageDescription

// The on-device brain of the iOS app: a Swift port of the Android app's embedded server
// (android/app/src/main/java/com/collectify/app/server). Everything here is UI-free so it can be
// unit-tested on macOS: SQLite access, the catalog (FTS5 search, scanner lookups, game queries),
// binders / collection / wishlist / trades, the trade rooms, tcgcsv sync, and an HTTP server that
// serves the same routes the web UI already calls.
let package = Package(
    name: "CollectifyCore",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "CollectifyCore", targets: ["CollectifyCore"]),
    ],
    targets: [
        .target(
            name: "CollectifyCore",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .testTarget(
            name: "CollectifyCoreTests",
            dependencies: ["CollectifyCore"],
            resources: [.copy("Golden")]
        ),
    ]
)
