## Collectify 0.29.0: a 3D adventure world, potions and deeper battles

Android `.apk` and iPhone/iPad `.ipa`, same version, same features.

### 🌍 The adventure world is now 3D
- The trails are a little **3D world in the island's own style**: rolling ground with soft colour blending, low-poly trees, and **grass made of real blades** that sway in the wind and **part around your trainer and your partner** as you walk through. Water moves, and **lava glows**.
- **Each region has its own look**, not just its own colours:
  - **Meadow Trail:** round trees, haystacks, flowers, mushrooms, drifting pollen.
  - **Pebble Hills:** snow-capped pines, crystal clusters and boulders, cobbled paths, dust on the wind.
  - **Tide Shore:** palms, a wooden boardwalk, beach umbrellas and giant shells, sea spray.
  - **Dream Grove:** giant glowing mushrooms, runestones and glowing crystals, stepping-stone paths, fireflies.
  - **Ember Crater:** lava lakes, ash-red grass, dead trees with glowing tips, obsidian spires, basalt slabs, rising embers.
- **Lighting follows your clock:** sunrise and sunset tint the world, and at night it goes dark with stars and a lantern that follows you. Shadows fall from trees and people.
- **Characters are 3D too**: your trainer, the other trainers (each with their own look) and the Wardens (crown, cape and a glowing ring) walk and swing their arms. You can **see where a trainer is looking**: a faint lit strip shows the line of sight. Chests glow until you open them and their lids swing open. Tap a person or a chest to go and talk to them.
- If your device can't do 3D, the flat map is used instead. On slow phones the scene lightens itself.

### 🧪 Potions: brew them, carry them, augment your partner
- **Ten potions**, brewed at the workbench from your berries (each from its own type's berries, unlocking as you do): **Health Potion** (35%), **Super Potion** (75%), **Cure Tonic**, **Power Tonic** (+25% attack), **Iron Tonic** (+25% defence), **Swift Tonic** (+30% speed), **Shield Elixir** (a shield of 25% health), **Stamina Draught** (no weariness for 150 steps), **Fortune Brew** (+50% coins, double chance of packs and potions) and **Vitality Vitamin** (permanently +4 max health, up to 10 per Pokémon).
- Tonics, elixirs and Fortune Brew last for your **next 5 battles**; what's active is shown on the screen while you walk. Use potions from the adventure hub, from the ☰ menu on the trail, or (health potions and Cure Tonics) in the middle of a battle.
- **A chance of a health potion at the end of a battle:** about 1 win in 5 against wild Pokémon, 1 in 3 against trainers (who sometimes leave Super Potions and tonics too), and every Warden gives you a Super Potion and two Health Potions. Potions are listed in your bag. They can't be sold.

### ⚔️ Deeper battles
- **Bond Burst:** from Bond 6 (or after any evolution), once per battle, your Pokémon unleashes a sure-hit finisher in its own type, with its own name and effect.
- **Every type has an ability:** Grass heals a little each round, Fire hits harder under a third of its health, Water takes 10% less damage, Electric may paralyse whoever hits it, Rock hangs on with 1 health once, Psychic crits more, and Normal is a little faster. Shown on each Pokémon's card.
- **Weather in each region:** sun, dust wind, rain, mist and ashfall each power up one type by 20-25% and weaken another. It's shown in battle and next to each move.
- **Potions in battle**, with a turn cost, and **trainers drink a potion too** when they're nearly beaten (Wardens carry two).
- A new **battle scene**: a themed backdrop for each region with moving weather (sun rays, rain, mist, ash), a platform for each side, effects in the attacker's type that fly across and burst on the target, a screen shake on big hits, ability chips and a shield meter on each Pokémon's plate.
- A **type chart and the abilities** are now in the field guide.

### Also
- The hub shows each Pokémon's ability, whether its Bond Burst is ready, and each region's weather.
- Vitamins taken show beside a Pokémon's health.

### Tested, and what wasn't
- The 37 adventure tests (65 tests in all) now also cover: every potion's recipe and ingredients, crafting one, using each kind on the trail (healing, buffs that don't stack, stamina, vitamins and their cap), buffs changing the fighter and wearing off after 5 battles, the shield, potions and refusals in battle, Bond Burst (once, never misses, hits harder), each ability, weather, trainer potions, and the drop odds (including Fortune Brew).
- Tried in a browser at phone size: all five regions in 3D, tapping and walking, fights in a few regions, potions on the island, in the adventure menu and in battle, Bond Burst, the new result panel, and the flat-map fallback when WebGL is off.
- **Not tested on a real phone**, so I can't promise the frame rate: the scene is lighter on phones (fewer blades and trees), and it's about 150,000 triangles on the biggest map, which a recent phone should handle but an old one may not. If it's slow, tell me which phone. I also can't hear the sound effects.
