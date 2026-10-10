## Collectify 0.21.0 — now on iPhone and iPad too

This release ships **two files with the same version and the same features**: `Collectify-v0.21.0.apk` for Android and `Collectify-v0.21.0.ipa` for iPhone / iPad (iOS 15+). Every release from here on will carry both.

### iPhone / iPad
- **Install:** the `.ipa` is not in the App Store and is not signed, so install it with a sideloading tool that signs it with your own Apple ID: [AltStore](https://altstore.io), [Sideloadly](https://sideloadly.io) or TrollStore. A free Apple ID lets a sideloaded app run for 7 days before it needs refreshing in the tool; your data is kept.
- It is the same app: the same web interface, the same bundled card catalog (works offline), binders, scanner, grading, in-person trading, wishlist, Treasure Box and Island Care.
- **How it's built:** the app's on-device server (database, search, scanner lookups, binders, trades, game and island saves, trade rooms, price sync) is a Swift port of the Android one. The `.ipa` is built by a GitHub Actions workflow on a macOS runner, which first runs tests of the Swift code against the real card catalog, including comparisons with answers recorded from the Android server.
- Allow the **camera** when asked, and **Local Network** access for in-person trades. Island reminders use iOS notifications.
- iOS can't let an app read its own installed package, so *Check for updates* tells you the latest version but can't verify the checksum on iPhone: compare the downloaded `.ipa` with the SHA-256 on the website.

### Both platforms
- *Check for updates* in the About sheet now knows which platform it's on (an iPhone is told to download the `.ipa`).
- Nothing else changed in the web interface since 0.20.0.

### Tested, and what wasn't
- Android: same code as 0.20.0 plus the update-check text; signed with the same key as every earlier release.
- iPhone: the Swift server passes its tests (searches, product pages, the scanner's name/number lookup, Treasure Box catalog queries and card pools match the Android server's recorded answers; binders, collection, wishlist, trades, game/island saves, catalog updates and trade rooms are exercised in a test database; the HTTP server is tested over a real socket). The app is also started in the iOS Simulator in CI.
- **Not tested:** any real iPhone. Camera scanning (the simulator has no camera), QR trading between two phones, notifications, battery/performance with the 3D island, and the sideloading step itself. Treat the iPhone build as a first release and tell us what breaks.
