## Collectify 0.20.0 — a growing island: maids, a real windmill, breeding, new places

Installs over your existing Collectify; your island and everything else is kept.

### Fixes you reported
- **Maids now have models.** Each maid is a character in her own dress, hair and frilly cap. She really walks around the island to do her job: waters a dry plot, picks a ripe one, hauls water from the well to the dish, carries food, plays ball with a Pokémon, collects drops, mends toys, and picks fruit. With nothing to do she sweeps or fusses over a Pokémon. When her salary isn't paid she sits on her stool; at night she goes indoors.
- **The windmill is fixed.** The sails were turning about the wrong point. They now spin around a proper hub, faster in wind and rain, and the mill moved off the shoreline. A built Windmill now also makes every crop grow 5% faster.

### The island grows (Build → Island expansion, five steps)
Each step adds land and something to do (costs 2,500 · 5,000 · 9,000 · 14,000 · 22,000, from levels 8, 11, 14, 17, 20):
1. **The Meadow:** a second garden with a scarecrow (+3 plots). Replaces the old floating islet; if you had already expanded, you keep your plots and get the bigger island.
2. **The Orchard:** fruit trees that ripen about one fruit an hour (+2 plots). Fruit is a Pokémon treat and a breeding ingredient.
3. **The Ranch:** pasture, a pond with ducks and the Nursery site.
4. **The Harbor:** a dock and a trader's boat (in at 8:00, out at 19:00) that pays 20% more for hatchlings (+2 plots).
5. **The Summit:** a hill with a lighthouse whose beam sweeps at night, and a wishing shrine with a daily blessing (+2 plots).
Pokémon visit the new places, each in its own way: grass types munch fruit in the orchard, water types splash in the pond, electric types charge up at the windmill, others gaze from the summit.

### Breeding (Nursery, level 14, needs the Ranch; 3,000 🪙)
- Pick two Pokémon of the **same type** that are **happy and well fed (every need above 70) and at Bond 7+**. A Hearty Meal (craft: 2 🍎 + 2 berries) and a 150 🪙 fee start the incubation (6 hours).
- While they wait they must stay comfortable; if either gets hungry, thirsty or bored the egg pauses. Then the egg hatches (3 hours).
- A hatchling's **potential (1–5 ★)** depends on the parents' bond and mood; there is a small shiny chance. The offspring is one of the parents' species, or occasionally another of that type.
- **Sell hatchlings at the market** (or for more at the harbor). They're worth most after a day. The parents rest for 12 hours. Upgrade the Nursery for a second incubator.

### Farming depth
- **Crop mastery:** each harvest teaches you the crop (5 levels per type): faster growth, bigger harvests, and a chance of a ✨ golden crop with bonus essence and coins. See ☰ → Farm.
- Orchard fruit, Hearty Meals and the Windmill bonus (above).

### Polish
Birds circling the island, chimney smoke, windows that glow at night, stone paths to the new places, a pond with lilies and reeds, a rope-and-lantern dock, hay bales, a picnic blanket, and the island camera can pull back further as it grows.

### Tested, and what wasn't
Checked in a desktop browser and booted on an Android emulator with an existing save: each expansion step and zone, maids walking to and working a plot, the Nursery sheet and starting a breeding pair, the Build and Farm tabs, and the island at night. The rules (expansion, plots, orchard, mastery, breeding including neglect pauses, hatching, selling, and old-save migration) were run in a test script. **Not tested:** a full breeding cycle in real time, a long play session on a phone, performance on older phones with all five expansions built.
