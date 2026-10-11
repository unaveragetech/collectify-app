## Collectify 0.24.0 — My Little Pony cards, and at least 10 packs to open in every game

Android `.apk` and iPhone/iPad `.ipa`, same version, same features.

### My Little Pony CCG
- The catalog source (tcgcsv.com) lists the My Little Pony CCG's sealed products but none of its cards, so its packs could never be opened. **2,234 cards in 15 sets** (Premiere, Canterlot Nights, Rock n Rave, Celestial Solstice, The Crystal Games, Absolute Discord, Equestrian Odysseys, High Magic, Marks in Time, Defenders of Equestria, Seaquestria and Beyond, Friends Forever, GenCon, Primer Deck, General Fixed Set) now come from the fan-run [MLP CCG Cards Database](https://data.mlpmerch.com/ccg/). Only names, sets, numbers and rarities are stored; each card picture loads from where that site hosts it.
- All **8 real MLP booster packs** (Premiere to Defenders of Equestria) can now be opened, and the sets with no sealed pack get generated ones: **14 packs** in total. Foil, Ultra Rare, Super Rare and Royal Rare cards rank as the better pulls. No prices exist for these cards.
- Not found anywhere usable: a set called "Sands of Time" (only an empty filter on one site), so it isn't included.

### At least 10 packs in every game
- Every game with cards now has **at least 10 packs**. Games with fewer than 10 sets (17 of them, such as Zombie World Order, Chrono Clash System, Bakugan, Palworld, Kryptik, Godzilla and Cyberpunk) get **Mixed Packs**: each one draws on a different slice of that game's cards, priced from those cards. They show up in Pick packs, the free daily pack, Mystery Blocks and trades like any other pack. Pick packs now shows each game's pack count.
- **54 games, 3,580 packs** in total (it was 53 games, 3,492 sets).
- Still without packs, because the catalog has no (or almost no) single cards for them: **KeyForge** (decks only), **Alternate Souls** (sealed products only) and **Naruto Card Game** (2 promo cards). No bulk card source for these was found; they can be added if one turns up.

### Catalog
- Catalog version 13: the 2,234 MLP cards, and four new MLP sets. Installed apps merge it on first launch (it can take a minute).

### Tested, and what wasn't
- Every game was checked to list 10 or more packs; the desktop, Android and iPhone code give the same answers (the iPhone code is tested against answers recorded from Android, including the new mixed packs and MLP data). MLP card pictures need an internet connection and are served by a third-party site, so they can be slow or missing if that site moves them.
- Not tested on a real phone.
