## Collectify 0.22.0 — a pack for every set of every game

Android `.apk` and iPhone/iPad `.ipa`, same version, same features.

You can now mine and open a booster pack from **any card game in the catalog**, as long as you have the coins.

- **51 games, 3,300 sets.** Before, only sets that happened to have a "Booster Pack" product listed could be mined: 1,515 sets across the games that list one, and nothing at all for Dice Masters, Chrono Clash System and Kryptik TCG (and no packs for around half the sets of Magic, Yu-Gi-Oh!, Pokémon, Cardfight Vanguard and others). Now every set with at least 12 cards with pictures gets a pack of its own: **1,785 new packs**.
- **Real packs are still used where they exist.** The Pick packs list shows a game's real sealed packs first, then the generated ones. Generated packs have their own foil wrapper in a colour drawn from the set and game (no internet needed), are named "<Set> Booster Pack", and open into 10 cards from that set.
- **Price and difficulty:** a generated pack is priced from the set's own cards (2.5× their average market price, between $1.50 and $45), so a pack of a cheap set sits in soft rock and a valuable set in hard rock, like a real pack. It costs the same coins to claim.
- **Every game in the pickers.** The Pick packs menu, the free daily pack (new *More games…* menu) and Mystery Blocks now list every game, not just the nine that were hard-coded, and the daily pack falls back to generated packs for games with few real ones.
- **They work everywhere a pack does:** your packs inventory, stacking, trading unopened packs, Auto-queue, the 10-per-set daily purchase limit and prestige features all treat them like any other pack.
- **Better pulls in games with poor rarity data:** some games list no usable rarity. Their packs now rank cards by price instead, so they still have commons and a few chase cards.
- Not included: generated *boxes* (boxes still need a real "Booster Box" product), and accessories such as sleeves, deck boxes, playmats and Funko, which aren't card games.

### Tested, and what wasn't
- Checked in a desktop browser against the full catalog: every one of the 51 games offers a pack that rolls 10 cards; the new picker, the daily pack and Mystery lists work; the generated wrapper renders.
- The Android, iPhone and desktop servers answer the new requests identically (the iPhone code is tested against answers recorded from the Android server, including the wrapper images).
- Not tested on a phone, and not every one of the 3,300 sets was opened one by one: a handful of unusual sets may have odd rarity data.
