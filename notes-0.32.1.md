## Collectify 0.32.1: selling fixes, and shop displays are easier to tap and change

Android `.apk` only (the iPhone version is paused until further notice).

### 🐞 Fixed: cards that were paid for but never left the binder
- **Shop sales:** when two customers paid in the same instant, the second card's removal was mistaken for a repeat of the first and skipped. You were paid, the card stayed in the binder, and it could be put on a shelf and sold again after reopening the app. Every sale now has its own removal, and the same goes for thefts, whole binder lots and contract hand-overs.
- **Sell extra copies (Earn coins):**
  - Copies that were on a shelf or held for a trade were skipped but still paid for. Now they stay put and are never counted.
  - You are only paid after the app reads your binders back and confirms the cards really left, and a double tap can't sell the same cards twice.
- **Other double taps:** rescuing cards from the dupes bin, handing over a contract, accepting a buy-in offer, filling shelves automatically and opening the daily chest each ignore a second tap while the first is still being saved.
- **"Stock" on a new display:** the Stock button and the "next empty spot" step said every spot was full on a freshly built display. Fixed.
- The dupes bin recycling now saves right away too.

### 👆 Displays are easier to tap and change
- **Tap a display once** and a small bar appears with what you do most: **Stock**, **Fill**, **Best prices**, **Repair**, **Style**, **Edit**, **Move**. No more hunting through a big menu for the common jobs.
- **Bigger tap targets:** each spot is larger, and a tap that lands just beside a display still picks it (the nearest one within a fingertip).
- Tapping the floor closes the bar. While you are walking the shop, taps on the floor still walk you there.

### Tested
- 177 automated JavaScript tests and 20 Python tests pass, including new ones for the settlement keys, the first-empty-spot rule, locked duplicates and "paid only for what left the binder".
- Tried in a browser at phone size. Not tried on a real phone.
