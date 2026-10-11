"""Records reference responses from the *Android* (Kotlin) server so the Swift port can be tested against them.

Usage (an emulator or phone running the app, with the port forwarded):
    adb forward tcp:18321 tcp:8321
    python ios/tools/capture_golden.py http://127.0.0.1:18321 ios/CollectifyCore/Tests/CollectifyCoreTests/Golden

Only catalog queries are recorded (they depend on the bundled catalog, not on user data).
`mode` says how the Swift test compares: "exact", "set:<key>" (same items by key, ignoring order and `rank`,
because the Android emulator may lack FTS5 and fall back to LIKE ordering) or "names" (same set of strings).
"""
import json
import os
import sys
import urllib.request

base = sys.argv[1].rstrip("/")
out = sys.argv[2]
os.makedirs(out, exist_ok=True)


def call(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(base + path, data=data, method=method, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=300) as r:
        raw = r.read().decode()
        return r.status, (json.loads(raw) if "json" in (r.headers.get("Content-Type") or "") else raw)


cases = [
    ("search_pikachu", "GET", "/api/search?q=pikachu&limit=5", None, "set:product_id"),
    ("search_charizard_cards", "GET", "/api/search?q=charizard&category_id=3&cards_only=1&limit=5", None, "set:product_id"),
    ("search_two_words", "GET", "/api/search?q=dark%20charizard&limit=5", None, "set:product_id"),
    ("search_nothing", "GET", "/api/search?q=zzzzqqqxx", None, "exact"),
    ("categories", "GET", "/api/categories", None, "exact"),
    ("categories_search", "GET", "/api/categories?search=magic", None, "exact"),
    ("product", "GET", "/api/product/42402", None, "exact"),
    ("scan_names", "GET", "/api/scan/names?category_id=3", None, "names"),
    ("scan_lookup", "POST", "/api/scan/lookup", {"names": ["Pikachu", "Charizard"], "numbers": ["058102"], "category_id": 3, "limit": 12}, "set:product_id"),
    ("game_sealed_pack", "GET", "/api/game/sealed?category_id=3&kind=pack&limit=5", None, "exact"),
    ("game_sealed_box", "GET", "/api/game/sealed?kind=box&limit=3", None, "exact"),
    ("game_sealed_query", "GET", "/api/game/sealed?q=base%20set&kind=pack&limit=3", None, "exact"),
    ("game_pool", "GET", "/api/game/pool?group_id=604", None, "exact"),
    # generated packs for sets that have no sealed booster pack
    ("game_games", "GET", "/api/game/games", None, "exact"),
    ("game_vsealed_dice", "GET", "/api/game/vsealed?category_id=18&limit=6", None, "exact"),
    ("game_vsealed_page2", "GET", "/api/game/vsealed?category_id=1&limit=5&offset=5", None, "exact"),
    ("game_vsealed_query", "GET", "/api/game/vsealed?q=x-men&limit=5", None, "exact"),
    ("product_generated", "GET", "/api/product/2000001594", None, "exact"),
    ("packart", "GET", "/api/game/packart/1594", None, "text"),
    # mixed packs (games with fewer than 10 sets) and the My Little Pony cards imported from another source
    ("game_vsealed_mixed", "GET", "/api/game/vsealed?category_id=36&limit=10", None, "exact"),
    ("game_vsealed_mixed_paging", "GET", "/api/game/vsealed?category_id=76&limit=5&offset=3", None, "exact"),
    ("game_pool_mixed", "GET", "/api/game/pool?group_id=2100003601", None, "exact"),
    ("product_mixed", "GET", "/api/product/2100003601", None, "exact"),
    ("packart_mixed", "GET", "/api/game/packart/2100003601", None, "text"),
    ("game_sealed_mlp", "GET", "/api/game/sealed?category_id=38&kind=pack&limit=10", None, "exact"),
    ("game_pool_mlp", "GET", "/api/game/pool?group_id=2003", None, "exact"),
    ("game_vsealed_mlp", "GET", "/api/game/vsealed?category_id=38&limit=10", None, "exact"),
]
index = []
for name, method, path, body, mode in cases:
    status, data = call(method, path, body)
    if mode == "text":
        with open(os.path.join(out, name + ".txt"), "w", encoding="utf-8", newline="") as f:
            f.write(data)
    else:
        with open(os.path.join(out, name + ".json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
    n = len(data) if isinstance(data, (list, dict)) else 1
    print(f"{name:26} {status} {n} items")
    index.append({"name": name, "method": method, "path": path, "body": body, "mode": mode, "status": status})
with open(os.path.join(out, "cases.json"), "w", encoding="utf-8") as f:
    json.dump(index, f, indent=1)
