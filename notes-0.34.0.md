## Collectify 0.34.0: design your whole shop, a real character, staff with bodies, and customers who are people

Android `.apk` only (the iPhone version is paused until further notice).

### 🎨 A design studio for the inside of the shop
- **Every wall on its own** (Build, then **Walls & floor**): back, left and right can each be plain paint, stripes, polka dots, wood panels, brick, tiles, floral paper, planks, checks or concrete, in any colour (26 swatches or a colour picker), with a second colour for patterns.
- **Panelling** (wood, tile or planks) at a low, middle or high height in its own colour, **trim**, **skirting boards** and **crown moulding** in colours you pick.
- **Floors:** 16 patterns (new: parquet, hex tiles, flagstones, bleached oak, polished concrete, wine and teal carpet, sand) with an optional tint and a coloured border.
- **Windows** (big, small, arched, or none) with shutters in a colour you choose, and **wall lamps** in four styles or a light strip.
- The old one-tap themes still work and now set everything together. While you design, the sheet sits low so you can watch the shop change.

### 🔄 Turn the camera all the way round
- Drag to spin the view through a full circle, or use the **⟲ ⟳** buttons for a quarter turn. A wall between you and the room **fades away**, so you can look in from any side and see every wall.
- **Pieces turn too:** every piece can be turned in place (even rugs), and anything that hangs on a wall can go on the **back, left or right wall**: tap a wall to hang it there, or use **Next wall**. While you build, you see the real piece as a see-through copy (green where it fits, red where it doesn't), and you can cycle its style and colour before you buy.

### 🪑 35 new things to furnish with, and a colour for (nearly) everything
- **Inside:** armchair, corner sofa, coffee table, bookshelf, grandfather clock with a swinging pendulum, fireplace with flames, piano, coat rack, bean bag, globe, big plants, trading table with chairs, photo booth, claw machine, floor mats, big rugs and balloons.
- **Structure:** room dividers (solid, glass, half wall, wood slats, brick) that split the shop into areas while keeping everything reachable, pillars, and things that hang from the ceiling (chandeliers, pendant lights, a ceiling fan, a disco ball).
- **On the walls:** 8 kinds of framed art, mirrors, a wall TV, plant shelves, wall lamps and hanging flags. The neon sign now comes in six messages.
- **Outside:** trees (four kinds), hedges, a flag pole, a picnic table, a parasol table, snack carts, a street bin, a phone box, a bus stop and a lucky cat statue.
- Most pieces have several **styles**, and nearly all can be **recoloured** (any colour).

### 🧍 A character worth playing
- Rounded body, a **face with eyes, brows and a mouth** (6 eyes, 4 brows, 6 mouths), rosy cheeks and freckles, five builds, eight skin tones, **12 hairstyles** in 12 colours, **10 outfits** (T-shirt, hoodie, apron, vest, jacket, sweater, dress, overalls, suit, lab coat), five kinds of trousers and skirts, four kinds of shoes, **12 hats**, 10 extras (glasses, mask, backpack, bow tie, necklace...) and something to hold. **Outfit presets** and **Surprise me**. For the close-up your character steps into open floor.

### 👷 Staff with bodies
- Your **cleaner** walks to rubbish and sweeps it, your **stocker** walks to a display with empty spots and fills it, and your **guard** stands by the door, patrols, and runs after thieves (and gets the stolen item back). They wear uniforms (pick the colour), have names, and work while you watch.

### 🗣️ Customers are people
- Every customer has a **name, a face, hair and clothes** that match who they are, a **personality** (chatty, picky, bargain hunter, patient, impulsive, shy) and a **mood** that changes with what happens to them.
- **Tap a customer** (or walk up and press Talk): **say hello**, **chat** (you may hear something true about your own shop), **recommend** something (a good suggestion can win a sale they wouldn't have made) or **agree a discount** with a bargain hunter.
- **Regulars:** happy buyers can become regulars who come back as themselves; their visits and spending show on your website.
- **Reviews** now have a title, tags (Prices, Cleanliness, Staff, Parking, Atmosphere...), a "bought this" badge and mention what actually happened: what they bought, the queue, the rubbish, your pet, your staff, the car park, the weather, the theme. Reply with thanks, an invitation, an apology, a promise to fix it, or a **coupon** (🪙 25) to win an unhappy customer back.

### 💡 Also
- The guide has new steps (design your character, design your walls, talk to a customer, hang art), and the room look is carried through old saves.
- Fixed a crash when the room was redrawn after a wall style change, and a few things in the close-up view.

### Tested
- 204 automated JavaScript tests and 20 Python tests pass, including new ones for the design studio, walls on any side and ceiling lights, room dividers, the new pieces, the character, staff behaviour (cleaning, restocking, chasing thieves), customers' personalities, regulars, reviews, recommending and discounts. In a browser at phone size I built all 64 new pieces in one shop, designed walls and floors, turned the camera right round, tried 150 random characters, watched staff and customers walk the shop, and used the customer and design screens. Not tried on a real phone: this is a lot more to draw, so the 3D view will use more of the graphics chip (it lowers its own quality if the frame rate drops).
