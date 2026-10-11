# Collectify (Android and iPhone)

**Website:** https://unaveragetech.github.io/collectify-app/ - [features](https://unaveragetech.github.io/collectify-app/features.html), [step-by-step install guides for Android and iPhone](https://unaveragetech.github.io/collectify-app/install.html) (with troubleshooting), the [changelog](https://unaveragetech.github.io/collectify-app/changelog.html) and the SHA-256 of every release. In the app, ℹ️ → *Check for updates* compares your install with that list.

Sideloadable builds of the Collectify app for Android (`.apk`) and iPhone / iPad (`.ipa`): a WebView shell around the
[Collectify](https://github.com/unaveragetech/collectify) web app - card
scanning/OCR, binders, grading, in-person trading, wishlist, and price tracking
across every TCG on tcgcsv.com. The full card catalog is bundled, so it works
offline.

## Install on Android

> Full walkthrough with troubleshooting: **[install.html](https://unaveragetech.github.io/collectify-app/install.html#android)**.

1. Download the latest `Collectify-vX.Y.Z.apk` from [Releases](../../releases)
   (about 80 MB). Wait for the download to finish before opening it.
2. Open the file and allow "install unknown apps" for your browser / file
   manager if Android asks.
3. First launch unpacks the card catalog (needs roughly 400 MB of free space)
   and takes a few seconds.

Requires Android 8.0 or newer.

Updates install over the existing app and keep your binders, grades and
trade history, as long as the build is signed with the same key (all
`Collectify-v0.11.1` and newer files are).

## Install on iPhone / iPad (iOS 15 or newer)

> Full walkthrough (Sideloadly, AltStore, TrollStore; trust, Developer Mode, weekly refresh, problems): **[install.html](https://unaveragetech.github.io/collectify-app/install.html#iphone)**.

Every release also carries `Collectify-vX.Y.Z.ipa` (about 90 MB): the same app, the same version
number, built from the same web interface. It is **not signed** and not in the App Store, so
install it with a sideloading tool that signs it with your own Apple ID:
[AltStore](https://altstore.io), [Sideloadly](https://sideloadly.io) or TrollStore.

- Allow the camera when asked (scanning, trade QR codes). For in-person trades also allow
  *Local Network* access.
- First launch unpacks the card catalog (needs roughly 400 MB free) and takes a few seconds.
- With a free Apple ID iOS lets a sideloaded app run for 7 days before it must be refreshed from the
  sideloading tool; your binders and data are kept.
- Updates install over the old app (keep the same bundle id `com.collectify.app`).

The iPhone `.ipa` is built by the **Build iOS** workflow in this repo (`.github/workflows/ios.yml`) on
a macOS runner: it tests the Swift core against the real card catalog, builds the app, starts it in
the iOS Simulator and attaches the `.ipa` and its `.sha256` to the release. The app's native layer
(`ios/CollectifyCore`) is a Swift port of the Android server and is checked against recordings of the
Android server's answers. Real-device testing of the iPhone build is still limited.

## Checking a download

Each release includes a `.sha256` file next to each APK and IPA. If Android says the
package can't be parsed or is invalid, the download is usually incomplete:
compare `sha256sum Collectify-vX.Y.Z.apk` (or any checksum app) with that file
and download again if they differ.

## Notes

- These are sideload builds, not Play Store builds, so Play Protect may ask you
  to confirm the install.
- If you installed an older build that was signed with a different key,
  uninstall it first. Uninstalling removes local data.
- Releases up to v0.11.0 shipped as `app-debug.apk` (debug builds, 170+ MB).
  Use the newest release instead.

## Publishing a release (maintainers)

After `gh release create`, run `python tools/build_site.py`, then commit and push `docs/` so the website and the in-app update check see the new version and its checksum.
