"""Packages the parts of the app that are not in git, for the iOS CI build.

  ios-www.zip              the web UI (the same files the Android app bundles under assets/www)
  collectify.db.gz         the pre-synced card catalog (only needed when catalog_version.txt changes)
  catalog_version.txt

Run from the project root (the folder that contains android/ and ios/):

    python ios/tools/pack_resources.py out_dir

then upload `ios-www.zip` to the app release (v<version>-standalone) and `collectify.db.gz` to the
release `catalog-v<N>` (create it once per catalog version; N is catalog_version.txt).
"""
import gzip
import os
import shutil
import sys
import zipfile

root = os.getcwd()
assets = os.path.join(root, "android", "app", "src", "main", "assets")
out = sys.argv[1] if len(sys.argv) > 1 else "ios-resources"
os.makedirs(out, exist_ok=True)

www = os.path.join(assets, "www")
zpath = os.path.join(out, "ios-www.zip")
with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for base, _dirs, files in os.walk(www):
        for f in files:
            full = os.path.join(base, f)
            z.write(full, os.path.join("www", os.path.relpath(full, www)))
print("wrote", zpath, os.path.getsize(zpath) // 1024, "KB")

shutil.copy(os.path.join(assets, "catalog_version.txt"), os.path.join(out, "catalog_version.txt"))
if "--no-db" not in sys.argv:
    gpath = os.path.join(out, "collectify.db.gz")
    with open(os.path.join(assets, "collectify.db"), "rb") as src, gzip.open(gpath, "wb", compresslevel=6) as dst:
        shutil.copyfileobj(src, dst, 1 << 20)
    print("wrote", gpath, os.path.getsize(gpath) // (1024 * 1024), "MB")
