## Collectify 0.19.0 — packs you own, bigger binders, Prestige, and a livelier island

Installs over your existing Collectify; your data is kept. The first launch after updating refreshes the card catalog (about a minute) — that is what fixes the missing sets below.

### Packs: yours the moment you mine them
- **Pack inventory** (Treasure → 📦 Packs): every unopened pack, stacked by product with a count, searchable, filterable by game, sortable. Open one, or offer it in a trade.
- **Trade unopened packs.** In a live trade, ＋ Add → **📦 Packs** lets you offer any quantity of a stack (boxes too). Packs travel as digital items; the receiver gets them in their inventory. Both phones need this version.
- **Keep as many as you like.** Identical packs stack into one entry, nothing ever forces you to open one to make room, and the save limit went from 2 MB to 8 MB.
- **The 30th Celebration packs (and any set that "wasn't there").** Cause: TCGplayer renamed that pack after the catalog we shipped was built, and people only saw it if they had synced. Fixes: a full catalog refresh ships in this release (existing installs merge it on first launch), the pack filter also recognises "Celebration" and "Anniversary" packs, and Pick packs has a **Missing a set? Update this game's catalog** link.
- **Black cards on a pull:** the card renderer now checks its own output and falls back to the normal card picture if a frame comes out black; a card picture that fails to load shows a proper card face instead of a black rectangle. I couldn't reproduce a black card here, so this is a guard against every cause I could find rather than a fix of one confirmed cause.

### Binders: 3×3 and real control
- New binders and the starter binder are **3×3**. (The starter binder is converted once; your cards keep their order, pages just regroup.)
- **⚙ Binder settings:** any columns × rows (2–6 × 1–8), eight page styles (Midnight, Leather, Felt, Navy, Parchment, Rose, Carbon, Sky), pocket shapes, spacing, show/hide names, rename, and tie a binder to one game.
- **Organize:** sort by set and number, name, rarity, value or newest (optionally starting each set on a new page), or close the gaps.
- **☑ Select mode:** tick cards, then move them to another binder, to a page, or remove them.
- **A game-specific binder only takes that game's cards** (the app tells you why when it refuses). Kept pulls and trade results pick a binder that can hold them.
- **Wishlist:** no duplicates, "✓ you have this" badges, an **Add to a binder** button on each wish, and a card is crossed off automatically when you add it.

### Treasure Box: depth and Prestige
- **12 pickaxes** (new: Emerald, Ruby, Mythril, Celestial, Eternal), each with its own head design, swing animations (heavy smash, spin on big combos, triple slash) and particle effects.
- **11 upgrades** (new: Critical Eye, Crit Power, Armor Piercing, Salvage, Haste, Fortune), higher level caps, and **two new block grades** (Mythril, Celestial).
- **Coins from mining are slower**: smaller break bonuses, a tap coin only every 20 taps, half pay while the app is closed.
- **🏆 Prestige.** Spend your upgrades to ascend: coins and upgrade levels reset; packs, cards, tokens, tickets and everything you own stay. Every rank gives a **special badge**, **+30% damage**, 4% cheaper upgrades, a pickaxe head start and **one new feature**:
  1. Geodes · 2. Auto-Queue · 3. Mystery Blocks (+ Mythril) · 4. Ticket Veins · 5. Guardians (+ Celestial) · 6. Double Strike · 7. Golden Slot (a bonus card in every pack) · 8. Time Warp · 9. Master Forge (+5 levels on every upgrade) · 10. Mythic Aura (extra plot, rainbow badge). Ranks past 10 keep adding damage.
- **Specialty blocks**: Geodes, Ticket Veins and Guardians appear while you mine as bonus plots that don't use a slot and crumble if ignored; Mystery Blocks hide a random pack from the game you pick.

### Island: a world that moves
- Pokémon now **roam the whole island**: they head to their food and toys when needy, visit places their type loves (trees, shore, windmill, rocks…), follow you, chase butterflies and play with each other.
- **Foraging:** berries, shells, mushrooms and glow crystals appear around the island to pick up (and a daily quest for it).
- **Weather:** sunny, cloudy, rain and thunderstorms, plus rainbows after rain. Rain waters your crops and tops up the water dish.
- **Accessories** earned through bond: a bow, a flower crown, then a golden crown.

### Fixes
- Saving a binder's layout now works on Android (the phone's server doesn't read PATCH bodies; the app uses PUT).
- The shipped catalog no longer includes a developer's game saves, and carries only today's prices.

### Tested, and what wasn't
Played through on an Android emulator and a desktop browser: the new binder tools and TCG restriction (API and screens), pack inventory, pack trading logic and the live-room server with pack entries on the phone's server, prestige including ascending, specialty blocks, roaming and foraging. **Not tested:** a real two-phone trade with packs, physical-phone performance, how the new sounds and animations feel on a phone. I did not play the late prestige ranks for real; their numbers are arithmetic.
