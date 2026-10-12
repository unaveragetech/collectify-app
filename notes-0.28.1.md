## Collectify 0.28.1: A proper Build menu, and the Nursery at level 10

Android `.apk` and iPhone/iPad `.ipa`, same version, same features.

### 🏗️ The Build menu now shows what everything needs
- **Menu → Build** is now a purchase menu for the whole island. Every **area**, **building** and **upgrade** is a card with a checklist: the **island level** it needs, the **building or area before it**, and its **coin cost**. Each line has a tick when you meet it, and shows what's missing ("you're level 9", "2,500 more"). What you can't have yet is **locked**, and the button says why (**Locked**, **Save up** or **Build**).
- **How to get new areas** is explained right at the top: the island grows in five steps, one after the other (the Meadow, the Orchard, the Ranch, the Harbor, the Summit), each needing a level, the area before it and coins. Your **next area** is highlighted, a line tells you when something is **ready to build**, and a **Coming up** list shows the next level unlocks.
- When you reach a level that makes something buildable, you get a message pointing you to the Build menu.

### 🥚 The Nursery opens at level 10
- The **Ranch and the Nursery now open at level 10** (the Nursery stands on the Ranch, so the Ranch comes first). To make that work the island's areas moved earlier: **Meadow level 6, Orchard level 8, Ranch level 10**, then the Harbor at 14 and the Summit at 18. The Nursery's second incubator is at level 15. The Hearty Meal recipe (used for breeding) is level 10 too.
- Coin costs haven't changed. If you've already built something, nothing is taken away; the new levels only decide when you can build the next thing.
- The adventure healing ward still works from level 4 (a simple tent), and becomes faster once the Nursery is built.

### Tested, and what wasn't
- Automated tests check the new levels, that each area needs the one before it, that the Nursery needs the Ranch and level 10, the status of every entry (built, ready, saving up, locked), and buying in order (54 tests pass in total).
- Tried in a browser at phone size: the areas, the buildings and upgrades, locked and ready states, and buying the Nursery.
- Not tested on a real phone. How quickly the earlier levels arrive depends on how fast you earn XP and coins: tell me if the coin costs should change too, since coins (about 16,500 for the three areas, then 3,000 for the Nursery) are now the main thing between you and the Nursery at level 10.
