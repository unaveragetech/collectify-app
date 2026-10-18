## Collectify 0.33.0: cars, car parks, card easels, a guide for all three big games, and a lot of polish

Android `.apk` only (the iPhone version is paused until further notice).

### 🚗 A living street (Card Shop)
- **Cars drive past your shop** in two lanes: hatchbacks, saloons, vans, taxis and the odd bus. They queue behind each other, turn their lights on after dark, and are fewer at night and more at rush hour. People stroll along the pavement.
- **Weather:** on a rainy day it really rains, the sky goes grey and fewer people come. Festival days fill the pavement with tourists.
- **Car parks you can buy:** Build, then Space. A tiny (4 spaces), corner (8), big (14) or mega (22) car park appears beside the shop, with painted bays, hedges, lamps and a P sign. Cars pull in, park for a while and drive out again. More spaces bring more customers (up to +55%) and cost a little each day, so it is a real choice. Switch to the street view 🏙️ to watch it.
- **A shop pet:** bring one of your island Pokémon to keep the shop company (Manage, then Shop pet). It wanders between the displays, customers love it, and it stays yours on the island.

### 🖼️ Viewable card stands
- **Card easel** (new display, shop level 3): two big cards stood up on a wooden easel with a little spotlight. Tap it and the camera glides in and the card fills the screen.
- **Look closely** works for anything on any display: a big picture that tilts and glints under your finger, with swipe-through to the other items on that display, and the price one tap away. The quick bar on a display has a 🔍 Look button.

### 💡 A guide so you never feel lost (Island, Treasure Box, Card Shop)
- A **💡 button** appears at the top in each of the three games. It shows your **next steps** (done, next, later, locked until a level) with a plain explanation of how and why, a progress bar, and a **How it works** page. Some steps have a **Show me** button that opens the right screen.
- A gentle **hint** shows when you open a game (at most every ten minutes; you can turn it off in the guide).
- The **first time** you finish each step you earn a few coins. Steps you had already done before this update pay nothing, so it only rewards new progress.
- **No more dark, empty mine:** when there is no block to mine, the Treasure Box now says so and gives you a big button to pick a pack (or open the Forge if you have no pickaxe yet).

### ✨ Polish
- Softer, more consistent buttons and chips (they press in and respond), a gentle top shade and vignette on the shop, nicer shadows on the headers and sheets, a glowing active tab, animated hints, and a clearer card viewer. Sheets and pills respect "reduce motion".
- The shop's price tags, rain, headlights and pavement people are drawn lightly: nothing runs while the street isn't in view.

### Also in the shop
- Parking upkeep is included in the bills screen, the bills are part of the daily cost, and the level-unlock list mentions the easel and the car parks.

### Tested
- 187 automated JavaScript tests and 20 Python tests pass, including new ones for car parks (gating, upkeep, extra customers), the easel, the shop pet and every step of the guide for all three games. In a browser at phone size I watched the street with traffic, queues, parked cars and rain, the easel and card viewer, the guide in the shop and the island, and the new Treasure Box empty state. Not tried on a real phone: the cars and rain add some work for the graphics chip, and the 3D view lowers its own quality if the frame rate drops.
