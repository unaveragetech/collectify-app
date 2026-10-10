## Collectify 0.19.3 — pickaxe reset, and a daily pack limit per set

Installs over your existing Collectify; your data is kept.

### Reset an over-powered pickaxe
Saves from before the pickaxe overhaul could carry upgrade levels that no longer fit the new balance.
- **The Forge has a Reset pickaxe button** (bottom of the upgrade list): it costs **5,000 coins** and puts every upgrade back to level 0. You keep the pickaxe itself, your remaining coins, packs, cards, tickets and prestige.
- **Once per prestige rank.** Ascending gives you another reset. It asks you to confirm and shows how many levels you are giving up.
- On first load, any upgrade level above today's cap is also pulled back to the cap.

### Daily pack limit per set
Buying lots of cheap packs, opening them and selling the dupes could produce unlimited coins.
- **You can buy 10 packs per set (series) per day with coins.** A whole box uses a set's full daily allowance. The limit resets at midnight.
- Pick packs shows a "🛒 3/10 today" counter on sets you've bought from, and the button is disabled with an explanation once you hit the limit. Other sets are unaffected.
- It applies to normal claims, Mystery Blocks (the set of the hidden pack counts) and Auto-queue (which now stops at the limit).
- **Not limited:** the free daily pack, hourly pack tokens and box tickets, which are already rationed by time.

### Tested, and what wasn't
Checked in a desktop browser: 12 buys from one set stopped at 10 while other sets and a box still worked, the counter rolled over on a new day, the row showed 10/10 and a disabled button, and the reset charged 5,000, zeroed 375 levels, kept the pickaxe and then disabled itself. Not tested: Mystery Block and Auto-queue at the limit, on a phone.
