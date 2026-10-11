## Collectify 0.23.0 — more packs, a safer pack opener, a fresh catalog and a proper install guide

Android `.apk` and iPhone/iPad `.ipa`, same version, same features.

### Packs
- **Every pack you can mine can be opened.** Before, a stack whose set couldn't be found in your catalog (an older pack, a pack received in a trade from a phone with a different catalog) showed "Couldn't load that set's cards". Now the app looks the set up again; if it truly isn't there, the stack is swapped for a pack from the same game that does have cards, with a message. A set is also only offered as a pack if it has pictures for enough of its cards.
- **More packs.** A set now needs 8 cards with pictures (it was 12): **3,492 sets across 53 games** can be opened (it was 3,300 across 51).
- **Sorcery: Contested Realm** lists its 3,100+ cards without collector numbers, so none of its sets could be opened. Sets with too few numbered cards now also use cards that have a rarity and aren't named like sealed product (decks, boxes, kits). Sorcery now has all four real booster packs plus generated packs, and its Ordinary / Exceptional / Elite / Unique rarities rank the pulls.
- **My Little Pony:** the catalog source (tcgcsv.com) lists the My Little Pony CCG's 8 booster packs and boxes and 12 sets, but **no single cards at all**, and there is no "My Little Pony" card game entry besides it. A pack can only open into cards, so those packs can't be opened yet. They will work the moment the source adds the cards; nothing was invented to fill the gap.

### Catalog
- Pulled a fresh catalog and prices from tcgcsv.com for every category (511,936 products, 54 games with cards). The source had no new sets since the last pull, so what changed is prices (a few groups errored upstream and keep their previous prices). Installed apps merge it on first launch (it can take a minute).

### iPhone install guidance
- The About panel now says plainly how long the install's signature has left (read from the signing profile AltStore or Sideloadly add), turns amber and then red as it runs out, and links to a new step-by-step page: **How to install**.
- New website pages: install guide for Android and iPhone (Sideloadly, AltStore, TrollStore, weekly refresh, Developer Mode, common problems), features (with the full list of supported games), a searchable changelog and an about/privacy/FAQ page.

### Ads groundwork (switched off in this release)
- The Android app contains the groundwork for AdMob: an adaptive banner under the app that steps aside while you open packs or use the camera, one app-open ad on a cold start at most every 3 hours and never in the first launches, Google's consent form where the law requires it, and a one-time "remove ads" purchase through Google Play. **None of it runs in this build: there are no ads.** It needs AdMob credentials and a Play listing first, and the website's privacy page will be updated when it does.

### Tested, and what wasn't
- Every one of the 3,492 pack sets was checked to have a usable card pool, in the desktop catalog; the Android server was checked on an emulator to give the same totals; the iPhone code is tested against answers recorded from the Android server (recorded again for this catalog).
- Not tested on a real phone. The pack swap and re-link path was written for situations that couldn't be reproduced from the catalog data here, so it is a safety net rather than a fix for a known cause: if you still see an unopenable pack, tell us which game and set.
