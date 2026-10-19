## Collectify 0.36.0: worker priorities, deeper reviews and replies, more stores, and one-tap order sourcing

Android `.apk` only (the iPhone version is paused until further notice).

### 👷 Workers do what you tell them
- **Worker Priority menu** (Manage → *Workers & bills*): every worker has one priority, and the moment you change it they stop what they were doing and start the new job. Seven priorities: **Stock shelves**, **Clean store**, **Handle customers**, **Manage storage**, **Decorate**, **Process orders**, **Deliver goods**. Their name tag shows what they are doing.
- **Nobody wanders.** The old cleaner and stocker no longer stroll about the shop. Each priority has a station (behind the till, the supply corner, the stockroom...) and a worker waits there when there is nothing to do. Two workers with the same priority take different stations.
- What each one does, while you watch **and** while you are away:
  - *Stock shelves* walks to a display with empty spots and fills it.
  - *Clean store* walks to rubbish and sweeps it, and keeps the grime down.
  - *Handle customers* works the till (faster checkout, shorter waits, better service scores) and walks over to shoppers who are still looking: it lifts their mood and often turns a "no" into a sale.
  - *Manage storage* goes round the displays, worst first, repairing them for free and keeping your sort order.
  - *Decorate* tends the decor: a better atmosphere and curb appeal (and a sparkle).
  - *Process orders* accepts contracts your shelves can fill and hands them over for you.
  - *Deliver goods* carries things: transfers between stores are free and sourced orders are handed over at once (and sourcing is 10% cheaper).
- Hire from shop level 3; the number of workers grows with the shop (up to 8). Each costs more than the last. **Balance for me** spreads the crew over what needs doing; **Everyone on…** sets them all at once. Every worker looks like their job (broom, box, tablet, garland, parcel...). Old saves keep their cleaner and stocker as workers. The guard stays a guard at the door.

### 📝 Reviews that sound like people, and a choice of replies
- Reviews are now written from what actually happened to that person: how long they waited, how crowded it was, who helped them, a gruff worker or nobody on the till, the layout, the decor they noticed, what they bought and **where it stood** ("the glass case by the back wall"), a sale tag, the spotlit piece, parking, weather, the region.
- Every observation has several ways of being said, and the way they write follows their personality (chatty, picky, bargain hunter, shy, impulsive, patient). The shop remembers what it has recently said, so the same lines and the same openings don't come round again.
- **Three to six ways to answer every review**, chosen by how it reads: warm thanks, a professional apology, polite but firm, light-hearted, make it up to them (costs coins), explain what happened (uses what really went wrong), ask for more details, mention an offer, invite them back. Each shows its text before you post it, its cost and how it is likely to land: a joke to an angry customer backfires, arguing when they had a point goes badly, and a good answer can make an unhappy customer raise their rating.

### 🏬 More stores
- **Store 2 (Harbour Market)** unlocks at **500,000 🪙** of lifetime sales across your stores, **Store 3 (Neon Mall)** at **1,000,000 🪙**. Build them from *Manage → Locations*.
- A new store has a **construction phase** (2 and 4 hours, or rush it with coins), then pays its own **daily tax** on top of rent (it shuts if unpaid, without touching your other stores). Shoppers there pay more (+12% / +25%) and goods you source cost more too.
- Each region has its own **people** (sailors and importers; streamers and investors), its own **decor** (ship's wheel, cargo crates, buoy lamp; LED video wall, hologram globe, neon arch) and its own idea: the harbour has bigger freight contracts that pay a quarter more, and the mall has a hype wave that a streamer's visit sets off.
- **Locations menu**: switch store, see earnings per store (total, today, till, level, stars), pay each store's taxes, assign workers per store, collect every till, see **who walks into the store you are in** (visits, buy rate by kind of customer), and customize each store's decor on its own. Stores you are not in keep trading in the background.
- **Move stock** between stores (4% shipping, free with someone on Deliver goods).
- **Promotions** (with two or more stores): send high spenders, decor enthusiasts, bargain hunters or tourists from one store to another for 30 minutes. The store they go to gets busier and leans towards that kind of shopper; the one they leave is a little quieter. A new **decor fan** customer comes everywhere and loves a pretty shop.

### 🧾 Source all goods
- On an accepted order, **Source all goods** shows the total cost of what is still missing, takes the fee and delivers all of it to the store at once; then hand it over (or have a worker do it). Cost is a little over what the goods are worth, more in costlier regions, less with a worker on Deliver goods.

### 💡 Also
- The Guide has new steps (give a worker a priority, source an order, open your second store).
- The shop no longer waits on a slow list of packs when it opens (on a phone with a big card catalogue that query could hold up everything for a long time).
- The event chip no longer overlaps the "Open" pill on narrow phones, and a missing space in the day report is fixed.

### Tested
- 246 automated JavaScript tests and 20 Python tests pass, including new ones for each worker priority (walking, working, staying put, changing at once), the crew rules and wages, the company (milestones, building and rushing, taxes per store, saves, background trading, promotions, transfers, demographics, regional customers and decor), the review writer (memory, context, style), every reply option and its effect, and order sourcing.
- In a browser at phone size: the Worker Priority menu and an instant priority change, the Locations menu, building and entering a store, its decor, switching back, moving stock, a promotion, the reply picker and sourcing an order. On an Android emulator the app opens an existing save without errors.
- Not tried on a real phone. The visual walking of workers was checked by the automated tests rather than watched in real time.
