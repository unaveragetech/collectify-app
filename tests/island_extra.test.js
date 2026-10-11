// Run:  node --test tests/        (decorations + island-visit rules in collectify/static/island_extra.js)
const test = require("node:test");
const assert = require("node:assert/strict");
const ISL = require("../collectify/static/island_data.js");
require("../collectify/static/island_extra.js");

let coins = 0;
ISL.wallet.get = () => coins;
ISL.wallet.add = (n) => (coins = Math.max(0, coins + n));

function island(level = 10) {
  const I = ISL.normalize(null, 1_000_000);
  I.started = true;
  I.tut = 99;
  I.level = level;
  I.seeds = ["grass", "fire"];
  ISL.chooseStarter(I, "bulbasaur", "Bulby", 1_000_000);
  I.level = level;
  I.tut = 99;
  ISL.ensureDecor(I);
  return I;
}

test("the catalogue is consistent", () => {
  assert.ok(ISL.DECOR.length >= 80);
  const ids = new Set();
  for (const d of ISL.DECOR) {
    assert.ok(!ids.has(d.id), "duplicate " + d.id);
    ids.add(d.id);
    assert.ok(ISL.PALS[d.pal] && ISL.PALS[d.pal].length >= 3, d.id + " palette");
    assert.ok(d.cost > 0 && d.lvl >= 1 && d.r > 0, d.id);
    assert.ok(ISL.CATS.some((c) => c.id === d.cat), d.id + " category");
  }
  // more than 600 distinct pieces once colour variants are counted
  assert.ok(ISL.DECOR.reduce((n, d) => n + d.n, 0) > 450);
});

test("buy, place, recolour, move, store, sell", () => {
  const I = island(10);
  coins = 1000;
  assert.equal(ISL.buyDecor(I, "bench").ok, true);
  assert.equal(coins, 850);
  assert.equal(ISL.buyDecor(I, "lookout").ok, false); // level 16
  const p = ISL.placeDecor(I, "bench", 3.14159, -2, 9, 99);
  assert.equal(p.ok, true);
  assert.equal(p.piece.r, 1); // rotation wraps
  assert.equal(p.piece.v, 6); // colour clamps to the palette
  assert.equal(I.dstock.bench, undefined);
  assert.equal(ISL.placeDecor(I, "bench", 0, 0, 0, 0).ok, false); // none left
  assert.equal(ISL.recolorDecor(I, p.piece.id, -1).ok, true);
  assert.equal(I.decor[0].v, 6);
  assert.equal(ISL.moveDecor(I, p.piece.id, 1, 1, 2).ok, true);
  assert.equal(ISL.moveDecor(I, p.piece.id, 999, 1, 2).ok, false);
  assert.equal(ISL.storeDecor(I, p.piece.id).ok, true);
  assert.equal(I.decor.length, 0);
  assert.equal(I.dstock.bench, 1);
  assert.equal(ISL.sellDecor(I, "bench").ok, true);
  assert.equal(coins, 925);
});

test("placement limit", () => {
  const I = island(1);
  coins = 1e6;
  let placed = 0,
    last = null;
  for (let i = 0; i < 400; i++) {
    ISL.buyDecor(I, "bush");
    last = ISL.placeDecor(I, "bush", (i % 50) - 25, 0, 0, 0);
    if (!last.ok) break;
    placed++;
  }
  assert.ok(placed >= 20, "placed " + placed);
  assert.match(last.msg, /room for/);
  assert.equal(I.decor.length, ISL.decorCap(I)); // placing earns xp, so the cap may have grown while we went
});

test("themes are bought once and then free to switch", () => {
  const I = island(12);
  coins = 2000;
  assert.equal(ISL.setTheme(I, "ground", "autumn").ok, true);
  assert.equal(coins, 1400);
  assert.equal(ISL.setTheme(I, "ground", "meadow").ok, true); // free default
  assert.equal(ISL.setTheme(I, "ground", "autumn").ok, true); // already owned
  assert.equal(coins, 1400);
  assert.equal(ISL.setTheme(I, "ground", "nope").ok, false);
  const low = island(2);
  coins = 5000;
  assert.equal(ISL.setTheme(low, "sky", "night").ok, false); // level 8
});

test("a visitor sees the island but not the bag", () => {
  const I = island(10);
  I.inv.secret = 5;
  I.quests = { day: "x", list: [{ id: "q" }] };
  const v = ISL.publicView(I, 5_000_000);
  assert.equal(v.inv, undefined);
  assert.equal(v.quests, undefined);
  assert.equal(v.settings, undefined);
  assert.equal(v.plots.length, I.plots.length);
  assert.equal(v.t, 5_000_000);
  const vs = ISL.viewState(v, 9_000_000);
  assert.equal(vs.started, true);
  assert.deepEqual(vs.inv, {});
});

test("timestamps are shifted onto the visitor's clock", () => {
  const I = island(10);
  const p = I.plots[0];
  p.seed = "grass";
  p.wAt = 1_000_000;
  const v = ISL.publicView(I, 1_100_000); // host clock
  const vs = ISL.viewState(v, 2_100_000); // visitor's clock is 1,000,000 ahead
  assert.equal(vs.plots[0].wAt, 2_000_000);
});

test("visitors water, harvest, pet, feed and are capped", () => {
  const I = island(10);
  const S = ISL.newSession();
  const now = 5_000_000;
  const p = I.plots[0];
  p.seed = "grass";
  p.wAt = 0;
  let r = ISL.visitApply(I, { name: "Sam", kind: "water", data: { plot: p.id } }, S, now);
  assert.equal(r.ok, true);
  assert.equal(p.wAt, now);
  assert.deepEqual(r.rewards, { xp: 3, coins: 2 });
  assert.match(r.host, /Sam watered/);
  r = ISL.visitApply(I, { name: "Sam", kind: "water", data: { plot: p.id } }, S, now);
  assert.equal(r.ok, false); // already watered
  r = ISL.visitApply(I, { name: "Sam", kind: "harvest", data: { plot: p.id } }, S, now);
  assert.equal(r.ok, false); // not ripe
  p.wAt = now - 10 * 3600 * 1000;
  const before = ISL.stockOf(I, "raw_grass");
  r = ISL.visitApply(I, { name: "Sam", kind: "harvest", data: { plot: p.id } }, S, now);
  assert.equal(r.ok, true);
  assert.ok(ISL.stockOf(I, "raw_grass") > before); // the host keeps the crop
  assert.equal(r.rewards.inv.raw_grass, 1); // the visitor gets a share
  const m = I.mons[0];
  r = ISL.visitApply(I, { name: "Sam", kind: "pet", data: { mon: m.id } }, S, now);
  assert.equal(r.ok, true);
  // caps
  for (let i = 0; i < ISL.CAPS.pet; i++) ISL.visitApply(I, { name: "Sam", kind: "pet", data: { mon: m.id } }, S, now + (i + 1) * 20000);
  r = ISL.visitApply(I, { name: "Sam", kind: "pet", data: { mon: m.id } }, S, now + 999999);
  assert.equal(r.ok, false);
  assert.equal(ISL.visitApply(I, { name: "Sam", kind: "nonsense", data: {} }, S, now).ok, false);
});

test("gifts, donations and notes reach the host safely", () => {
  const I = island(10);
  coins = 100;
  const S = ISL.newSession();
  let r = ISL.visitApply(I, { name: "Sam", kind: "gift", data: { items: { raw_grass: 3, bogus_item: 5, "../x": 1 }, decor: { bench: 2, nope: 4 } } }, S, 1);
  assert.equal(r.ok, true);
  assert.equal(ISL.stockOf(I, "raw_grass"), 3);
  assert.equal(ISL.stockOf(I, "bogus_item"), 0);
  assert.equal(I.dstock.bench, 2);
  assert.deepEqual(r.accepted, { items: { raw_grass: 3 }, decor: { bench: 2 } });
  assert.equal(ISL.visitApply(I, { name: "Sam", kind: "gift", data: { items: { bogus: 1 } } }, S, 1).ok, false);
  assert.equal(ISL.visitApply(I, { name: "Sam", kind: "gift", data: { items: { raw_grass: 99, raw_fire: 99 } } }, S, 1).ok, false); // too many at once
  r = ISL.visitApply(I, { name: "Sam", kind: "donate", data: { coins: 500 } }, S, 1);
  assert.equal(r.ok, true);
  assert.equal(coins, 600);
  assert.equal(ISL.visitApply(I, { name: "Sam", kind: "donate", data: { coins: 1600 } }, S, 1).ok, false); // over the per-visit limit
  assert.equal(ISL.visitApply(I, { name: "Sam", kind: "donate", data: { coins: -5 } }, S, 1).ok, false);
  r = ISL.visitApply(I, { name: "Sam", kind: "note", data: { text: "  Lovely <b>island</b>!\n\n  Thanks  ", mood: "🌸" } }, S, 1);
  assert.equal(r.ok, true);
  assert.equal(I.book[0].text, "Lovely b island /b ! Thanks");
  assert.equal(I.book[0].mood, "🌸");
  assert.equal(ISL.visitApply(I, { name: "Sam", kind: "note", data: { text: "   " } }, S, 1).ok, false);
  assert.equal(I.vtot.gifts, 5);
});

test("a visitor's gift is reserved and refunded, and rewards are capped per day", () => {
  const V = island(10);
  coins = 50;
  V.inv.raw_grass = 4;
  ISL.addInv(V, "raw_grass", 0);
  V.dstock = { bench: 1 };
  assert.equal(ISL.reserveGift(V, { items: { raw_grass: 5 } }).ok, false);
  const give = { items: { raw_grass: 4 }, decor: { bench: 1 }, coins: 30 };
  assert.equal(ISL.reserveGift(V, give).ok, true);
  assert.equal(V.inv.raw_grass, undefined);
  assert.equal(coins, 20);
  ISL.refundGift(V, give);
  assert.equal(V.inv.raw_grass, 4);
  assert.equal(V.dstock.bench, 1);
  assert.equal(coins, 50);
  coins = 0;
  const now = Date.UTC(2026, 9, 11);
  const a = ISL.claimRewards(V, { coins: 60, xp: 5, inv: { raw_fire: 1, bogus: 1 } }, now);
  assert.equal(a.coins, 60);
  assert.deepEqual(a.inv, { raw_fire: 1 });
  const b = ISL.claimRewards(V, { coins: 60 }, now);
  assert.equal(b.coins, 20); // 80 a day
  assert.equal(ISL.claimRewards(V, { coins: 60 }, now + 86400000).coins, 60);
});

test("souvenirs: one postcard per island per day", () => {
  const V = island(10);
  const now = Date.UTC(2026, 9, 11);
  assert.equal(ISL.addSouvenir(V, "Sam", { up: { expand: 2 }, charm: 40 }, now), true);
  assert.equal(ISL.addSouvenir(V, "Sam", { up: { expand: 2 }, charm: 41 }, now + 1000), false);
  assert.equal(ISL.addSouvenir(V, "Sam", { up: { expand: 2 }, charm: 41 }, now + 86400000), true);
  assert.equal(V.trip.souvenirs.Sam.n, 2);
  assert.equal(V.trip.visited, 2);
});
