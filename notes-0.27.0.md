## Collectify 0.27.0 — Complete all, Pokémon evolutions and movable furniture

Android `.apk` and iPhone/iPad `.ipa`, same version, same features.

### ✅ Complete all
- A new green **All** button on the island (below the eye button) looks after the whole island in one go: it waters and harvests the crops (replanting them with the same crop, which you can switch off), picks the orchard, collects drops and finds, repairs worn toys, then feeds, waters, plays with and pets every Pokémon, and fills the food and water dishes with what's left. Water comes with the service, so you never need to run to the well first.
- **Price: 🪙 100, and 🪙 50 more for each further use within 24 hours** (100, 150, 200, 250 ...). 24 hours after the first use the price drops back to 100. The coins are taken first, then everything is done. It shows exactly what it will do before you pay, and charges nothing when there's nothing to do. Quests and streaks count as if you'd done it by hand.
- Prefer to play it yourself? Ignore the button; nothing else changed.

### 🌟 Pokémon evolutions
- **Bond now goes beyond 10** (up to 30). The old bond bonuses (market price, crop speed, drops, breeding) still top out at 10, so nothing you had got stronger or weaker.
- At **Bond 20** a Pokémon gets a **special quest**, shown on the island board (and on its own page): craft its **unique item** at the workbench (the recipe only appears once it's ready; each Pokémon has its own item, for example Verdant Seed Charm for Bulbasaur or Thunder Stone Shard for Pikachu), then **give it to the Pokémon**.
- **10 to 24 hours later it evolves**, whether or not the app is open: it sparkles while it waits, and you get a banner when it happens (and a reminder if you have reminders on). Pokémon you've named keep their name.
- **26 evolutions** from the roster: Bulbasaur, Charmander, Squirtle, Oddish, Bellsprout, Vulpix, Growlithe, Psyduck, Poliwag, Pikachu, Magnemite, Voltorb, Geodude, Onix, Rhyhorn, Abra, Drowzee and Exeggcute. The three-stage families (Bulbasaur, Charmander, Squirtle, Oddish, Bellsprout, Poliwag, Geodude, Abra) get a **second quest at Bond 30**. Evolution items can't be sold or given away.
- **Perks:** an evolved Pokémon's drops are worth 20% more per evolution, and it speeds up crops of its type a little more.

### 🪑 Movable furniture, and a better layout
- The **food dish, water dish and toy box can be moved** (Menu → Decor → Furniture, or the new Furniture tab): tap the ground or use the arrows, then Done. They keep a little room between them. Visitors see them where you put them.
- **New default places:** the food dish now sits by the bench, the water dish by the well, and the toy box stays in the yard, instead of all three being within a few metres of each other. If you haven't moved them, they move to the new places; "Put them all back" restores them.

### Also
- A Pokémon that evolved is rebuilt on the island where it stood, with a burst of sparkles.

### Tested, and what wasn't
- The rules for evolution quests, the unique items, the 10 to 24 hour timer (including while away), Complete all's price steps and reset, what it does and when it refuses, and the furniture limits have automated tests (19 pass in total).
- Tried in a browser: the Complete all sheet and its result; a Bulbasaur at bond 20 getting its quest, crafting, evolving and appearing as Ivysaur with the banner; moving the toy box (and being refused a spot that was in the way).
- Not tested on a real phone. The evolution times and the Complete all price are my reading of your request: tell me if they need changing. Sprites for the evolved forms come from the same set as the others.
