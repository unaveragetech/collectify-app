## Collectify 0.15.0

Installs over your existing Collectify (same signing key) - your binders, wishlist and trades are kept.

### Scanner: fewer nonsense names
- The old scanner read the whole card in one pass and guessed. It now reads several ways, matches the words against the real card names for the game, checks where on the card each word was found, reads collector numbers / set codes, compares the artwork, and combines that into a confidence.
- It says **Confident**, **Likely** or "couldn't read this card" - it no longer fills the list with unrelated cards when the text is unreadable.
- Takes the sharpest of a short burst of frames. OCR engine and English data are bundled, so scanning works offline.
- On our 54-card test set (simulated phone photos) it identified the right card about 65% of the time, against about 24% for the old scanner, with a handful of wrong answers. Real-world results depend on light and focus.
- Scans can take noticeably longer on slow phones than before.

### Camera
- The scanner now starts on the **rear camera**. Change it under the palette button, Preferences.

### Trade
- Rebuilt: one phone shows a QR, the other scans it, and both open the same live trade screen and see each other's cards. Either side can agree or leave; any change resets both agreements. Needs the same Wi-Fi or one phone's hotspot. Offline two-code trading is still there as a fallback.
- Tested here between an Android emulator and a desktop client; not yet tested between two physical phones.

### Treasure Box (new mini-game)
- Buy a pickaxe, upgrade it, pick booster packs/boxes into stone/iron/gold/diamond/obsidian blocks, mine them (tap or let it run), rip the pack with a swipe, flip each card and swipe keep or bin. Keep to a "Treasure Box" binder; dupes go to the dupes bin (recyclable for coins). Daily chest included.
- Game cards are for fun: they carry a 🎲 badge, never count toward your collection value and can't be traded. Coins are only for the game.

### Quality of life
- Undo after removing a card from a binder or wishlist.
- Find a card inside a binder and jump to its page.
- Haptics on/off and default camera in Preferences.
- Fixed an overlapping "Add cards" button on the trade screen.
