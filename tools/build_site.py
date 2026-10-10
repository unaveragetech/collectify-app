"""Regenerate the GitHub Pages data for the Collectify app (docs/releases.json + docs/latest.json).

Run from the repo root after publishing a release:

    python tools/build_site.py

For every Collectify-vX.Y.Z.apk next to this repo it records the version, versionCode (read
with aapt2), size, SHA-256 and the release date/notes (from `gh`). If the release also carries an
iOS build (Collectify-vX.Y.Z.ipa, attached by the "Build iOS" workflow) its size, SHA-256 and
download link are recorded too (ipa, ipaSize, ipaSha256, ipaDownload). The app's "Check for
updates" button and the website's download table both read docs/releases.json.
"""
import glob
import hashlib
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, "docs")
REPO = "unaveragetech/collectify-app"
SITE = "https://unaveragetech.github.io/collectify-app/"
MIN_VERSION = (0, 11, 1)  # earlier files were debug builds; they're not listed


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def find_aapt2():
    sdk = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT") or os.path.expanduser(r"~\AppData\Local\Android\Sdk")
    cands = sorted(glob.glob(os.path.join(sdk, "build-tools", "*", "aapt2*")))
    return cands[-1] if cands else None


def version_code(apk, aapt2):
    if not aapt2:
        return None
    try:
        out = subprocess.run([aapt2, "dump", "badging", apk], capture_output=True, text=True, timeout=60).stdout
        m = re.search(r"versionCode='(\d+)'", out)
        return int(m.group(1)) if m else None
    except Exception:
        return None


def gh_json(args):
    try:
        out = subprocess.run(["gh", *args], capture_output=True, text=True, timeout=60)
        return json.loads(out.stdout) if out.returncode == 0 and out.stdout.strip() else None
    except Exception:
        return None


def ipa_info(tag, ver, prev):
    """Size / checksum / link of the iOS build attached to a release, or {} if there is none."""
    name = f"Collectify-v{ver}.ipa"
    data = gh_json(["release", "view", tag, "-R", REPO, "--json", "assets"])
    assets = {a["name"]: a for a in (data or {}).get("assets", [])}
    if name not in assets:
        return {k: prev[k] for k in ("ipa", "ipaSize", "ipaSha256", "ipaDownload") if k in prev and data is None}
    size = assets[name]["size"]
    digest = prev.get("ipaSha256") if prev.get("ipaSize") == size else None
    if not digest and name + ".sha256" in assets:
        try:
            out = subprocess.run(["gh", "release", "download", tag, "-R", REPO, "-p", name + ".sha256", "-O", "-"], capture_output=True, text=True, timeout=60).stdout
            digest = out.split()[0].lower() if out.strip() else None
        except Exception:
            digest = None
    return {
        "ipa": name,
        "ipaSize": size,
        "ipaSha256": digest,
        "ipaDownload": f"https://github.com/{REPO}/releases/download/{tag}/{name}",
    }


def main():
    os.makedirs(DOCS, exist_ok=True)
    aapt2 = find_aapt2()
    cached = {}
    old = os.path.join(DOCS, "releases.json")
    if os.path.exists(old):
        for r in json.load(open(old, encoding="utf-8")).get("releases", []):
            cached[r["version"]] = r
    meta = {}
    listing = gh_json(["release", "list", "-R", REPO, "--limit", "100", "--json", "tagName,publishedAt"]) or []
    for r in listing:
        m = re.match(r"v(\d+\.\d+\.\d+)-standalone$", r["tagName"])
        if m:
            meta[m.group(1)] = r

    releases = []
    for apk in sorted(glob.glob(os.path.join(ROOT, "Collectify-v*.apk"))):
        m = re.search(r"Collectify-v(\d+)\.(\d+)\.(\d+)\.apk$", apk)
        if not m:
            continue
        ver = ".".join(m.groups())
        if tuple(int(x) for x in m.groups()) < MIN_VERSION:
            continue
        prev = cached.get(ver, {})
        size = os.path.getsize(apk)
        digest = prev.get("sha256") if prev.get("size") == size and prev.get("sha256") else sha256(apk)
        sidecar = apk + ".sha256"
        if os.path.exists(sidecar):
            side = open(sidecar).read().split()[0].lower()
            if side != digest:
                print(f"WARNING: {os.path.basename(sidecar)} ({side[:12]}) differs from the computed hash ({digest[:12]})", file=sys.stderr)
        tag = f"v{ver}-standalone"
        notes_file = os.path.join(ROOT, f"notes-{ver}.md")
        notes = open(notes_file, encoding="utf-8").read() if os.path.exists(notes_file) else prev.get("notes", "")
        releases.append(
            {
                "version": ver,
                "versionCode": prev.get("versionCode") or version_code(apk, aapt2),
                "tag": tag,
                "date": (meta.get(ver) or {}).get("publishedAt") or prev.get("date"),
                "apk": os.path.basename(apk),
                "size": size,
                "sha256": digest,
                "url": f"https://github.com/{REPO}/releases/tag/{tag}",
                "download": f"https://github.com/{REPO}/releases/download/{tag}/{os.path.basename(apk)}",
                "notes": notes,
                **ipa_info(tag, ver, prev),
            }
        )
    releases.sort(key=lambda r: tuple(int(x) for x in r["version"].split(".")), reverse=True)
    json.dump({"app": "Collectify", "site": SITE, "releases": releases}, open(old, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    if releases:
        latest = {k: v for k, v in releases[0].items() if k != "notes"}
        json.dump(latest, open(os.path.join(DOCS, "latest.json"), "w", encoding="utf-8"), indent=2)
    print(f"{len(releases)} releases; latest {releases[0]['version'] if releases else '-'}")


if __name__ == "__main__":
    main()
