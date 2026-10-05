## Collectify 0.17.4

Installs over your existing Collectify; your data is kept.

### Pick packs: no more disappearing packs or redraws
- **Cause:** the 0.17.3 performance pass had set long lists to "paint only what's on screen" and to lazy-load thumbnails, which makes Android's WebView leave blank rows and re-draw them while you scroll. On top of that, the whole list was being rebuilt every time you claimed a pack or loaded more.
- **Fix:** those two settings are removed. The list now keeps its rows: *Load more* only adds the new rows at the bottom, and claiming a pack just updates the buttons in place, so your scroll position never jumps and nothing flickers. Thumbnails have a fixed size so rows don't shift as they load, and the per-row shadows, press animations and transitions that caused extra redraws are gone.
- The same blank-row risk is removed from the shop, trade and binder-search lists.

Tested by scrolling the list on an Android emulator and in a desktop browser, not on a physical phone.
