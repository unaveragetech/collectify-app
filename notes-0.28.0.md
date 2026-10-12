## Collectify 0.28.0: Adventure mode

Android `.apk` and iPhone/iPad `.ipa`, same version, same features.

### 🧭 Take a Pokémon on a journey
- A new **🧭 Go** button on the island (and **Menu → Adventure**) opens the adventure hub. It unlocks at **island level 4**. Choose one Pokémon to take along, choose a place, and set out.
- The journey is a **tile-map world you explore freely**, like the old handheld games. Walk with the on-screen stick or the keyboard (arrows / WASD), or **tap anywhere on the map** and your trainer walks there. Tap **A** (or Enter) to talk to people, read signs and open chests. Your partner trots along behind you.
- **Five regions**, each with its own look, Pokémon and difficulty: **Meadow Trail**, **Pebble Hills**, **Tide Shore**, **Dream Grove** and **Ember Crater**. Each ends at a **Warden**; beating them opens the next region. The first journey starts with a short tour.
- **Walking through tall grass can start a wild battle.** About one step in eight, with a few safe steps after every battle. Trainers stand watching down a line of sight and challenge you when they spot you. **Chests** wait in side nooks. Trainers and chests come back **every day**, and the Wardens can be rematched.

### ⚔️ Battles
- **Turn-based, with types.** Water beats Fire, Fire beats Grass and Psychic, Grass beats Water and Rock, Rock beats Fire and Electric, Electric beats Water, Psychic beats Grass and Electric. Each move shows a **strong / weak** arrow against whatever you're facing. Wild Pokémon also include plain Normal types.
- **Moves grow with your bond:** a quick move from the start (never runs out), a **signature move at Bond 3** (drain, burn, paralyse, flinch, lower attack or defence, depending on the type) and a **heavy move at Bond 8**. Evolving unlocks all three. **Guard** blunts a big hit (it works less often if you chain it). You can **run from wild Pokémon** but not from trainers.
- **Your care counts:** a happy, well-fed Pokémon hits and defends better; a hungry, thirsty or bored one is weaker, and below a point it **won't set out at all**. Bond and evolution make it stronger and tougher.
- Wild shinies (about 1 in 80) show up with a ✨ and pay triple.

### 🩹 Health, and the Nursery ward
- **Health wears down** on a journey: a little every few steps, and a lot in battles. It can't kill your partner by walking.
- **Health only comes back in the Nursery ward on your island.** Open it from the Nursery, the Pokémon's page, or the adventure hub. **Rest** is free (a full recovery takes 4 hours, or 2 hours once you've built the Nursery) and keeps going while the app is closed. **Heal** does it at once for coins (about 6 coins for every 10 missing health points).
- If your partner runs out of strength it's **carried home**. You keep every coin, medal and item you earned; it just has to heal before the next trip. No Pokémon is ever lost.
- Before the Nursery is built (level 14) the ward is a simple healing tent, so you can start adventuring early.

### 🪙 Rewards
- **Coins** for every win: wild battles pay a little, trainers more, Wardens a lot (a big first-time bonus).
- **Packs for your Treasure Box:** about 1 in 5 trainer wins gives one, the first win over each Warden always does, and rare wild finds (and shinies) sometimes do. Later regions give pricier packs. A small daily limit keeps wild-battle packs from being farmed.
- **Bond** with your partner grows from wins (up to 14 points a day, so caring for your Pokémon on the island still matters most).
- **Medals** (10 of them, each with a coin prize) and a **field guide** that fills in as you meet species, with counts of how many you've met and beaten, shinies marked.
- Chests hold coins plus berries, food or essences.

### Also
- The Android **back button** opens the adventure menu instead of leaving the app.
- Your adventure progress stays on your phone; island visitors never see it.

### Tested, and what wasn't
- 26 automated tests cover the battle rules (types, damage, guard, status effects, running, moves unlocking), health and the ward (resting over time, paying, the nursery speed-up), every region's map (deterministic, every chest, trainer and Warden reachable, nobody can see you at the start, tap-to-walk paths), rewards (coins, the bond and pack daily limits, medals, the first-win bonus), daily resets, and the saved state. A balance check plays hundreds of fights per region.
- Tried in a browser at phone size: the hub, setting out, walking by stick and by tapping, wild and trainer battles, the Warden fight and region unlock, chests, a pack arriving in the Treasure Box, losing and being carried home, healing at the ward, the gate, and the menu. Also run against the Android app's own server on the emulator (the adventure state saves and loads).
- Not tested on a real phone, and I can't hear the sound effects (they're small synthesised blips like the island's). The level bands, health costs and ward speed are my reading of your request: tell me if they need changing. The very first fights cost a brand-new starter roughly a third of its health, which is deliberate.
