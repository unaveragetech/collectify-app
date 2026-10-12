## Collectify 0.30.0: a bigger island with room to breathe, real paths, and scenery you can change

Android `.apk` and iPhone/iPad `.ipa`, same version, same features.

### 🏝️ A new layout: more room, one or two buildings in view at a time
- The starter island is **much bigger** (about two and a half times the area), and everything now has its own corner:
  - **the farm** to the west, with proper aisles between the rows of plots,
  - **the workshop** to the north,
  - **the market** and the **maid station** to the north-east, a good walk apart,
  - **the yard** to the south-east, with the **food dish, water dish and toy box** well apart,
  - **a pond** to the south-west, and **the windmill** north of the farm in a **clearing of its own** (the trees that crowded it are gone),
  - **the plaza** in the middle, where every road meets.
- Walking is a little faster to match, and a long trip **follows the roads** instead of cutting across the grass.
- The island's zones (Meadow, Orchard, Ranch, Harbor, Summit) sit further out, with their own roads.

### 🛤️ Paths that connect everything, and grow
- Roads run from the **plaza** to the farm (down every aisle), the well, the workshop, the market, the yard and each food dish, water dish and toy box (their little paths **move with them**).
- **New roads appear as you unlock things:** the **maid station's road at level 12**, the **windmill's road** when you buy the windmill, the **Meadow's aisle** with the Meadow, and a road to each new area as the island grows (Orchard, Ranch, Harbor, Summit).
- The roads change as the island grows: **packed dirt, then lighter packed earth, then gravel**, with cobbles set into them. Lamp posts (if you've bought them) line the roads.
- A **signpost in the plaza** points to everywhere you can go, and adds a board for each new place.
- Some small touches: flower planters round the plaza, hay bales, crates and a wheelbarrow at the farm gate.

### 🌊 A pond, and no more walking on water
- A real **pond** with a sandy bank, lily pads, reeds and cattails, ripples that spread, and **fireflies at night**. Water-type Pokémon like to visit it.
- **You (and your Pokémon) can't walk across the pond**, or through trees, rocks, bushes and buildings any more: you slide round them. The Ranch's pond is solid too. If you ever get stuck on something, you sidestep it on your own.

### 🌳 Trees, rocks and bushes are yours to change (Menu → Build → Landscape)
- Every tree, pine, boulder and bush is now part of your island. **Plant** more where you want them (🌳 Oak 🪙40, 🌲 Pine 🪙40, 🪨 Boulder 🪙25, 🌿 Bush 🪙12) with a see-through preview that goes red where it can't go, or switch on **Clear mode** and **tap any tree, rock or bush to remove it** (you get a few coins back, and there's an **Undo**).
- Nothing grows on a **path or a building**, or in the clearings kept free for the places your island will grow into. The island starts out with a belt of forest round the edge and the middle left open.
- Visitors see your scenery as you've arranged it.

### If you already have an island
- **Your crops, buildings, Pokémon, coins and everything in your bag are untouched.** Everything has moved to its new place, with a notice when you open the island.
- The **food dish, water dish and toy box go back to their new default spots** (you can move them again in Decor → Furniture).
- **Decorations that would now sit on a building or a road are put in your Decor stock** (never lost): put them back wherever you like.
- The trees, rocks and bushes are made fresh for the new layout.

### Tested, and what wasn't
- Ten new automated tests (75 in all) check: that every building, plot and path is on the island, that the dishes and toys are apart, that paths appear only when they should and all join up to the plaza and reach every stand point (at every stage of growth), that route planning follows the roads, that the scenery never sits on a road, a building, the windmill's clearing or too close to other things, planting, clearing, refunds and undo, and the move for older islands (decorations put away, dishes reset, notice, only once).
- Tried in a browser at phone size: a brand-new island and a fully grown one from above and on the ground; walking from the start to the workshop, market, maid station, board, farm plots, dishes and the well, round the pond; planting a tree; and clearing a bush by tapping it.
- Not tested on a real phone. The island has many hand-built pieces, so older phones may feel the bigger world. If walking feels too slow or too fast, or something sits in an awkward place, tell me where.
