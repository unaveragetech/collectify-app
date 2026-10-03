# Collectify (Android)

Sideloadable builds of the Collectify Android app: a WebView shell around the
[Collectify](https://github.com/unaveragetech/collectify) web app - card
scanning/OCR, binders, grading, in-person trading, wishlist, and price tracking
across every TCG on tcgcsv.com. The full card catalog is bundled, so it works
offline.

## Install

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

## Checking a download

Each release includes a `.sha256` file next to the APK. If Android says the
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
