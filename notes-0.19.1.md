## Collectify 0.19.1 — no more impossible blocks, and a better-feeling pickaxe

Installs over your existing Collectify; your data is kept.

### The "4487 hours left" cliff
A block whose grade is above your pickaxe was slowed by ×0.6 for every grade it was short, with no floor. A high-grade block (especially a whole box, which is 12 blocks mined one after another) could therefore show a time of weeks or more. I couldn't reproduce your exact 4487 h figure from a fresh save, but the cause of a number like that is the missing floor, and it is fixed:
- **Gentler, bounded penalty:** ×0.7 per grade short, and never slower than ×0.2. A block is slow for a weak pickaxe, never effectively impossible.
- **See the time before you claim:** every block in Pick packs now shows an estimate (⏱ ~15m, ⏱ ~2 days) at your current pickaxe; anything over 6 hours is tinted orange.
- **A warning, not a trap:** claiming a block that would take over 24 hours asks for a second tap, and tells you how many more upgrade levels it takes to match its grade.
- **Clear estimates on the block itself:** long times read "5 days" or "30+ days" instead of thousands of hours, and a hint says how many upgrade levels would bring your pickaxe up to that block's grade.

### Forge
- A **pickaxe ladder** shows all 12 pickaxes, which one you hold, the level each needs, and which block grade it handles at full speed.
- "Next look" now says how many levels are left.
- The grade explanation matches the new numbers.

### Pickaxe look and feel
- New handle: wood grain, a stitched leather grip, a metal ferrule under the head and a pommel cap; later pickaxes get a tassel in their glow colour.
- The head now has a bevelled edge so it reads as thick metal.
- Hits land harder: a brief freeze on impact (longer for crits and heavy smashes) and the head kicks back off the block and settles.

### Tested, and what wasn't
Checked in a desktop browser: the estimate table for every grade at starter gear, the Forge ladder, the second-tap warning on a 2-day box, and the pickaxe rendering in the mining scene. **Not tested:** on a phone; the feel of the hit-freeze and recoil is something to judge on a real device.
