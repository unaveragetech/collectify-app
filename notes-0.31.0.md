## Collectify 0.31.0: the Card Shop, binder tags, reliable trades and pulls, and more ways to earn

Android `.apk` and iPhone/iPad `.ipa`, same version, same features.

### 🏪 The Card Shop (new tab)
A 3D shop where everything you collect can earn you coins.
- **Build it your way.** Wall shelves, pack racks, card tables, curio tables, glass cases, Pokémon habitats, binder stands, trophy cases, plants, rugs, posters, a neon sign and lamps. Choose floors and walls, name the shop, and expand from a corner shop up to a flagship store. Tap the floor to place, turn and move.
- **Stock it from the whole game:** booster packs from the Treasure Box, cards you pulled, graded cards (a better grade sells for much more), hatchlings you bred in the nursery, and potions, essences, food, toys and sleeves from the island. Real binder cards can be sold once you tag them 🔁 Tradable, and only leave the binder when they sell. Trophy cases and binder stands show things off, not for sale, and raise your reputation.
- **Customers you can watch:** kids, collectors, trainers, flippers, graders and tourists walk in, browse what suits them, carry it to the counter, queue and pay. Set prices (or tap **Best price**); too high and they walk, a bargain and it flies.
- **Events and orders:** thieves sneak off with things (tap them to catch them for a reward; glass cases are safe, and real cards are never stolen), VIPs want your best card, daily orders pay a bonus, and collectors bring **buy-in offers**: buy a card for less than it's worth, shelve it, sell it for a profit.
- **It earns while you're away.** Up to 8 hours (more with Late opening) of sales while the app is closed; coins wait in the till, and a Cashier empties it for you. Upgrades: marketing, display lighting, fast register, security, cashier, late opening; ad campaigns and a free rush hour bring crowds.

### 🏷️ Binder tags
- Tag cards **Tradable, Gradable, High value, Duplicate, Wishlist** or your own. Badges show on every card in a binder and in the card viewer.
- **Filter inside a binder**, or open the **Tag manager** on the Binders tab: every card from every binder, filtered by tag (any/all) and sorted by **binder, tag, page, rarity or condition** (or value/name). ✨ Smart tagging finds duplicates, high-value and gradable cards. The trade pickers get a **Tradable only** switch, and the binder sorter gains condition and tag.

### 🛡️ Trades and pack pulls you can trust
- **Trades are all-or-nothing:** every card you give is checked against what you offered, then adds and removals happen in one transaction with a retry-safe key, and your binders are read back to confirm. Offered cards are **locked** (🔒) until the trade ends.
- **Opening lots of packs can't lose cards:** every pull is written down first, saved in safe batches, verified, and anything that can't be saved goes to the dupes bin instead. New-versus-duplicate is checked fresh every time, quick-open works on any stack of packs, and the game save now keeps the newest copy if a save to the server was lost.

### 🖼️ Pictures
- Variant printings with no picture of their own (Cracked Ice Holo, Master Ball Pattern and friends, e.g. Dewott 29/114) now show the right art: about **5,600 pictures repaired** in the catalog (v14), and the app repairs any it meets on the fly and once per version walks your binders to fix older entries.
- Cards in your binders survive catalog updates: a card that left the catalog keeps its place, and one that was renumbered is re-pointed at the same card.

### 💰 More ways to earn
- **Four daily tasks** with a bonus for finishing all of them and a streak; **pet upkeep** coins while you're away; **sell duplicates** in one tap (Treasure Box extras and the dupes bin; real, graded and Tradable cards are never sold by accident); and a small **hint when you're idle**: explore the island, care for pets, sell duplicates, restock the shop.

### Tested, and what wasn't
- 123 automated JavaScript tests (shop rules, simulation, glue, tags, income) and 20 Python tests (including the all-or-nothing collection changes and the catalog merge SQL, run against the very statements the apps use) pass; the shop was walked through in a browser at phone size, including building, stocking, selling and a flagship-size shop.
- The Swift (iPhone) side is built and tested by the iOS workflow; the Android Kotlin code is built here. **Not tested on real phones**: the 3D shop may feel heavy on older ones (there is a lite mode), and the numbers (prices, customer counts, upgrade costs) are my best first guess: tell me what feels too slow or too generous.
