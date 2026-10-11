"""Tests for the island-visit relay (collectify/visit.py).  Run:  python -m unittest tests.test_visit"""

import unittest

from collectify import visit


class VisitRelay(unittest.TestCase):
    def setUp(self):
        self.token = visit.open_room("Host", "hc")["token"]

    def test_join_and_act_and_answer(self):
        st, out = visit.join(self.token, "Sam", "c1")
        self.assertEqual(st, 200)
        self.assertEqual(out["you"], {"id": 1, "name": "Sam"})
        self.assertEqual(out["feed"][-1]["text"], "arrived")
        st, out = visit.act(self.token, {"client": "c1", "kind": "water", "data": {"plot": 3}})
        self.assertEqual((st, out["id"]), (200, 1))
        room = visit.get_room(self.token, None, None, 0, "hc")
        self.assertEqual(room["you"], "host")
        self.assertEqual(room["events"], [{"id": 1, "vid": 1, "name": "Sam", "kind": "water", "data": {"plot": 3}}])
        st, _ = visit.host_update(self.token, {"client": "hc", "ack": [1], "results": {"1": {"ok": True, "msg": "Watered", "rewards": {"xp": 2}}}, "feed": [{"text": "Sam watered a plot"}]})
        self.assertEqual(st, 200)
        room = visit.get_room(self.token, None, None, 0, "c1")
        self.assertEqual(room["events"], [])
        self.assertEqual(room["results"]["1"]["rewards"], {"xp": 2})
        self.assertEqual(room["feed"][-1]["text"], "Sam watered a plot")

    def test_snapshot_only_sent_when_changed(self):
        visit.host_update(self.token, {"client": "hc", "snap": {"level": 7, "plots": []}})
        room = visit.get_room(self.token, None, None, 0, None)
        self.assertEqual(room["snap"]["level"], 7)
        again = visit.get_room(self.token, None, room["snap_v"], 0, None)
        self.assertNotIn("snap", again)

    def test_only_the_host_can_publish_and_visitors_must_join(self):
        visit.join(self.token, "Sam", "c1")
        self.assertEqual(visit.host_update(self.token, {"client": "c1", "snap": {}})[0], 403)
        self.assertEqual(visit.act(self.token, {"client": "stranger", "kind": "water", "data": {}})[0], 403)
        self.assertEqual(visit.join(self.token, "Me", "hc")[0], 409)  # the host can't visit themself

    def test_limits(self):
        for i in range(visit.MAX_VISITORS):
            self.assertEqual(visit.join(self.token, f"v{i}", f"c{i}")[0], 200)
        self.assertEqual(visit.join(self.token, "late", "cx")[0], 409)
        self.assertEqual(visit.join(self.token, "v0", "c0")[0], 200)  # rejoining is fine
        self.assertEqual(visit.act(self.token, {"client": "c0", "kind": "nope", "data": {}})[0], 400)
        self.assertEqual(visit.act(self.token, {"client": "c0", "kind": "note", "data": {"text": "x" * 5000}})[0], 400)
        self.assertEqual(visit.host_update(self.token, {"client": "hc", "snap": {"x": "y" * (visit.MAX_SNAP_BYTES + 10)}})[0], 413)

    def test_position_updates_and_kick(self):
        visit.join(self.token, "Sam", "c1")
        visit.act(self.token, {"client": "c1", "kind": "pos", "data": {"x": 3.5, "z": -2, "ry": 1}})
        room = visit.get_room(self.token, None, None, 0, "hc")
        self.assertEqual((room["visitors"][0]["x"], room["visitors"][0]["z"]), (3.5, -2.0))
        visit.act(self.token, {"client": "c1", "kind": "water", "data": {}})
        visit.host_update(self.token, {"client": "hc", "kick": 1})
        room = visit.get_room(self.token, None, None, 0, "c1")
        self.assertEqual(room["visitors"], [])
        self.assertIsNone(room["you"])  # a kicked visitor sees they're gone
        self.assertEqual(room["events"], [])

    def test_leaving(self):
        visit.join(self.token, "Sam", "c1")
        self.assertEqual(visit.leave(self.token, {"client": "c1"})[0], 200)
        self.assertEqual(visit.get_room(self.token, None, None, 0, None)["visitors"], [])
        self.assertEqual(visit.leave(self.token, {"client": "c1"})[0], 403)
        self.assertEqual(visit.leave(self.token, {"client": "hc"})[0], 200)
        room = visit.get_room(self.token, None, None, 0, None)
        self.assertEqual((room["stage"], room["closed_by"]), ("closed", "host"))
        self.assertEqual(visit.join(self.token, "Sam", "c1")[0], 410)

    def test_long_poll_wakes_on_change(self):
        import threading, time

        room = visit.get_room(self.token, None, None, 0, None)
        got = {}

        def waiter():
            got["r"] = visit.get_room(self.token, room["v"], None, 5, None)

        t = threading.Thread(target=waiter)
        t.start()
        time.sleep(0.2)
        visit.join(self.token, "Sam", "c1")
        t.join(3)
        self.assertEqual(len(got["r"]["visitors"]), 1)


if __name__ == "__main__":
    unittest.main()
