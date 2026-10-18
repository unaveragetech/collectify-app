## Collectify 0.35.0: set any price, see how it is worked out, nine new displays, and a binder you can flip through

Android `.apk` only (the iPhone version is paused until further notice).

### 🐞 Fixed: binder covers looked zoomed in
- Cards and stickers on a binder cover you designed were drawn far too big and cut off. The card viewer in the shop (added in 0.33.0) shared two style names with the cover editor and overrode them. They are separate now, so every cover looks the way you made it. A test now guards against it happening again.

### 🏷️ Pricing you can understand and control
- **Any price for anything for sale.** Type it, drag the slider (¼ to 4× the fair price), or tap a quick one: ♻️ bin rate, fair, −10%, +10%, +25%, ×2, 📏 your rule, ✨ best. There is no longer a limit of 40% to 220%; the only limits are a coin and 🪙 999,999, so a typo can't break the till.
- **Who would buy it?** As you change the price you see how likely each kind of shopper (kids, collectors, trainers, flippers, graders, tourists) is to buy it, and "about N in 100 shoppers who look at it would buy it". A kid can't afford a 5,000 coin card, and it says so.
- **How is this priced?** Every item shows its working: the card's market value, × 6 coins per $ (the dupes-bin rate), × the shop markup, × the grade multiplier for graded cards, the minimum, and your own rule. You also see what recycling it would pay, and how much more (or less) the shop earns.
- **A price you typed stays put** when the card's market value moves; a price set as a share of fair follows the market. Switch between them any time.
- **Price rules.** *Manage → Pricing* sets how new stock is priced (a share of fair for cards, graded, packs, boxes, lots, Pokémon and curios, rounded to 1, 5, 10 or 25), explains how prices work in plain words, lists what each shopper will pay, and re-prices everything on the shelves in one tap (my rules, fair, best, ±10%, a sale).
- **Price lists.** The new 🏷️ *Prices* button on a display opens every price on it in one list: edit them one by one or all together. In select mode you can set one price for everything you picked.
- **Sales.** Put an item on sale (−10%, −25% or −40%): a red SALE tag shows in the shop, the old price is kept, shoppers can't resist a deal, and *End sale* puts it back.
- **Put a display piece up for sale.** Cards in a trophy case or on a pedestal can be given a price and sold (real cards only if you tagged them Tradable); a binder always stays on show.
- When you stock a card the picker now shows its market value, the fair price and the price your rules will give it.

### 📖 Flip through a binder like the real thing
- A binder on a stand, a lectern, or a binder lot on a shelf opens as a book. It starts on the cover you designed, with a tap or a swipe to open it.
- Every page has the layout, sleeves, page colour and card shape of the real binder (3×3, 3×4, 6×6, whatever you chose), with each card's value in coins (switch them off with 🪙 Values).
- **Swipe a page and it follows your finger and turns about the rings**, or use the arrows or the page slider. The back of a turned page shows the sleeves from behind. Tap a card to look at it big, with the shine that follows your finger.
- Binders on a shelf now wear their real cover colour, and show the card you put on the cover.

### 🧱 Nine new displays (Build → Displays)
- 🎡 **Spinner rack** (level 4): twelve cards on four faces, with a turning cap. Pulls kids and flippers.
- 📌 **Pegboard wall** (level 2): eight packs or curios on a wall.
- 🍬 **Impulse rack** (level 3): small things by the till; kids and tourists can't resist.
- 🏬 **Tall shelf** (level 6): twelve spots in four tiers, and one more tier with an upgrade.
- 🧱 **Box wall** (level 6): sealed boxes on rails. Pulls collectors and flippers.
- 🔦 **Spotlight pedestal** (level 6): one star piece under a glass dome and a beam of light that slowly turns it; draws everyone.
- 🪟 **Slab wall** (level 7): graded slabs lit on the wall behind glass; graders and collectors love it.
- 🎰 **Pack vending machine** (level 8): packs behind glass, safe from thieves.
- 📖 **Binder lectern** (level 5): an open binder on a stand that you can flip through.
- Most come in several styles, many can be recoloured, and wall displays keep the cells in front of them clear for customers. Each display says whom it pulls in, on its price screen.
- The guide has new steps (set a price, read how prices work, run a sale, try a new display, flip through a binder).

### Tested
- 215 automated JavaScript tests and 20 Python tests pass, including new ones for the price explanation (every kind adds up to the fair price), price rules and rounding, free pricing and its ceiling, quick re-pricing, demand falling as the price rises, sales (and a typed price ending one), putting display pieces up for sale, the nine displays (what they hold, wall placement, front cells, tiers, spotlight glass) and the way impulse racks and pedestals pull shoppers, and the cover-editor class names.
- In a browser at phone size: a binder opened from its cover, pages turned by button, drag and slider in both directions, card zoom, the values toggle, a binder lot with a price button, the price sheet typed, dragged and tapped, the price list edited inline, the Pricing sheet, putting a trophy-case card up for sale and back, the quick bar, the Build menu with all nine displays, and every new display built, stocked and seen from the front (including the slab wall and the lectern).
- Not tried on a real phone: more to draw in the shop, so the 3D view uses a little more of the graphics chip (it lowers its own quality if the frame rate drops).
