"""Black-box check of an island-visit relay over HTTP (works against the desktop server or the Android app).

    python tests/visit_http_check.py http://127.0.0.1:8000                      # desktop: one server does both
    adb forward tcp:18321 tcp:8321; adb forward tcp:18322 tcp:8322
    python tests/visit_http_check.py http://127.0.0.1:18321 http://127.0.0.1:18322   # Android: API port, room port

Runs the same scenario as tests/test_visit.py: join, act, answer, snapshot deltas, limits, kick, leave, long-poll.
"""
import json
import sys
import threading
import time
import urllib.error
import urllib.request

api = sys.argv[1].rstrip("/")
room = (sys.argv[2] if len(sys.argv) > 2 else sys.argv[1]).rstrip("/")


def call(base, method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(base + path, data=data, method=method, headers={"Content-Type": "text/plain"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            return e.code, json.loads(raw)
        except ValueError:
            return e.code, {"detail": raw}


ok_count = 0


def check(cond, what):
    global ok_count
    if not cond:
        print("FAIL:", what)
        sys.exit(1)
    ok_count += 1


st, out = call(api, "POST", "/api/visit/open", {"name": "Host", "client": "hc"})
check(st == 200 and out["token"] and out["port"], "open a room")
tok = out["token"]
V = f"/visit/{tok}"

st, out = call(room, "POST", V + "/join", {"name": "Sam", "client": "c1"})
check(st == 200 and out["you"] == {"id": 1, "name": "Sam"} and out["feed"][-1]["text"] == "arrived", "join")
check(call(room, "POST", V + "/join", {"name": "Me", "client": "hc"})[0] == 409, "host can't visit themself")

st, out = call(room, "POST", V + "/act", {"client": "c1", "kind": "water", "data": {"plot": 3}})
check(st == 200 and out["id"] == 1, "act")
st, r = call(room, "GET", V + "?me=hc")
check(r["you"] == "host" and r["events"][0]["kind"] == "water" and r["events"][0]["name"] == "Sam" and r["events"][0]["data"] == {"plot": 3}, "host sees the event")

st, _ = call(room, "POST", V + "/host", {"client": "hc", "ack": [1], "results": {"1": {"ok": True, "msg": "Watered", "rewards": {"xp": 2}}}, "feed": [{"text": "Sam watered a plot"}], "snap": {"level": 7}})
check(st == 200, "host answers")
st, r = call(room, "GET", V + "?me=c1")
check(r["events"] == [] and r["results"]["1"]["rewards"] == {"xp": 2} and r["feed"][-1]["text"] == "Sam watered a plot" and r["snap"]["level"] == 7, "visitor sees the answer + snapshot")
st, r2 = call(room, "GET", f"{V}?sv={r['snap_v']}")
check("snap" not in r2, "snapshot only when changed")

check(call(room, "POST", V + "/host", {"client": "c1", "snap": {}})[0] == 403, "visitor can't publish")
check(call(room, "POST", V + "/act", {"client": "stranger", "kind": "water", "data": {}})[0] == 403, "strangers can't act")
check(call(room, "POST", V + "/act", {"client": "c1", "kind": "nope", "data": {}})[0] == 400, "unknown kind")
check(call(room, "POST", V + "/act", {"client": "c1", "kind": "note", "data": {"text": "x" * 5000}})[0] == 400, "oversized event")
check(call(room, "POST", V + "/host", {"client": "hc", "snap": {"x": "y" * 300000}})[0] == 413, "oversized snapshot")

call(room, "POST", V + "/act", {"client": "c1", "kind": "pos", "data": {"x": 3.5, "z": -2, "ry": 1}})
st, r = call(room, "GET", V)
check((r["visitors"][0]["x"], r["visitors"][0]["z"]) == (3.5, -2.0), "position")

for i in range(2, 5):
    check(call(room, "POST", V + "/join", {"name": f"v{i}", "client": f"c{i}"})[0] == 200, "join " + str(i))
check(call(room, "POST", V + "/join", {"name": "late", "client": "cx"})[0] == 409, "room is full")
check(call(room, "POST", V + "/join", {"name": "Sam", "client": "c1"})[0] == 200, "rejoin is fine")

call(room, "POST", V + "/act", {"client": "c1", "kind": "water", "data": {}})
call(room, "POST", V + "/host", {"client": "hc", "kick": 1})
st, r = call(room, "GET", V + "?me=c1")
check(r["you"] is None and all(v["id"] != 1 for v in r["visitors"]) and r["events"] == [], "kick")

# long-poll wakes on change
st, r = call(room, "GET", V)
got = {}
t = threading.Thread(target=lambda: got.update(r=call(room, "GET", f"{V}?v={r['v']}&wait=8")[1]))
t0 = time.time()
t.start()
time.sleep(0.4)
call(room, "POST", V + "/act", {"client": "c2", "kind": "emote", "data": {"e": "👋"}})
t.join(10)
check(got.get("r") and time.time() - t0 < 6 and any(e["kind"] == "emote" for e in got["r"]["events"]), "long-poll wakes")

check(call(room, "POST", V + "/leave", {"client": "c2"})[0] == 200, "visitor leaves")
check(call(room, "POST", V + "/leave", {"client": "c2"})[0] == 403, "can't leave twice")
check(call(room, "POST", V + "/leave", {"client": "hc"})[0] == 200, "host closes")
st, r = call(room, "GET", V)
check(r["stage"] == "closed" and call(room, "POST", V + "/join", {"name": "Z", "client": "z"})[0] == 410, "closed rooms refuse visitors")
check(call(room, "GET", "/visit/nonexistent")[0] == 404, "unknown room")
print(f"all {ok_count} checks passed against {room}")
