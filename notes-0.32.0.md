## Collectify 0.32.0: walk round a Card Shop you have to look after, update notices, and pack-opening mistakes you can fix

Android `.apk` only. **The iPhone version is paused until further notice and won't be updated** (the last iPhone build is 0.31.0).

### 🔔 Update notices (opt-in auto update)
- When you open the app it quietly checks whether a newer version is out and shows a banner with the release notes. Tap to see what's new and install it; nothing downloads on its own unless you ask.
- **Opt in to auto update** in About: it downloads new versions in the background (Wi-Fi only by default, and you can allow mobile data), checks the file's checksum, and then just asks you to tap Install. Android always asks before installing, and your data stays.

### ↶ Pack-opening mistakes you can fix
- Sent a card you wanted to the bin? **Take it back with ↶** while you're still going through the pack, change your mind on the summary screen, or, once you have collected, **rescue cards from the dupes bin into any binder** (one copy at a time, added first and removed from the bin only after it is safely in the binder).

### 🚶 Walk round your shop, as your own character
- **A character you design:** skin, hair and colour, top and colour, trousers, hat, glasses, scarf, headphones, a name tag. Dress them in a close-up view, or tap 🧍 any time.
- **Walk with a stick** (or WASD on a computer) or **tap the floor** to walk there round the furniture. Go out of the door onto the pavement and the camera follows you; 🏙️ shows the shop front from the street.
- **Things to do in the shop:** walk over rubbish to sweep it up, stand by the till to serve customers faster, run into a thief to catch them, and tap **Use** on whatever is next to you (a display, the till).

### 🔨 Decorate it, inside and out
- **Inside:** 15 new things (couch, trailer TV, arcade cabinet, capsule machine, vending machine, fish tank with swimming fish, giant plush, standee, statue, wall clock that tells the real time, banners, string lights, a bargain bin, a box pallet and a binder shelf), more floors (dark planks, marble, blue tiles, pink carpet), more walls (mint, plum, wood panels, candy stripes), **lighting moods** (warm, cool, neon, sunset, party) and **one-tap themes**.
- **Outside:** pick the shop front (brick, wood, stucco, stone, teal, pink), awning colour and style, door (glass, wood, double, arched), the sign (board, neon, hanging, marquee) and its colours, string lights, even the street. Put benches, flower boxes, street lamps, an A-frame sign, bunting, a bike rack, a mailbox and a fountain on the pavement. A **sidewalk rack** or **market stall** out front sells to passers-by without them coming inside.
- Decorations add **atmosphere**, and a good-looking shop front adds **curb appeal**; both change what customers think of you.

### 📐 Buy more space
- Make the shop **wider** (two columns at a time) or **deeper** (a row at a time), up to a big flagship store, one strip at a time. The door and counter stay in the middle and your furniture is tidied automatically.

### ✏️ Edit any display, like a binder
- Hang a **name sign** on it, choose its **finish** and **trim colour**, change its **style**, **add shelf tiers** (shelves, racks, trophy cases, pallets), **sort** it (value, price, A to Z, kind, rarity), and **select several items** to move them to another display, reprice them, take them off or feature one on your website. **Move any item to another display** from its price screen.

### 🧰 A shop you have to look after
- **Open and close:** set your opening hours (or open and close by hand). Closed shops get no customers; busy hours are lunch and after school; a **daily event** (Pack Day, Collector's Fair, rain, tournament, street festival) changes who comes.
- **Upkeep:** busy displays **wear out** and stop working until you repair them; customers drop **rubbish** and the shop gets dirty, which earns bad reviews. Sweep, repair, deep clean, or hire a **cleaner**.
- **Bills and staff:** rent and wages come due daily after a few free days; fall too far behind and the shop shuts until you pay. Hire a **cleaner**, a **stocker** (refills empty spots for you) or a **guard**. Autopay is optional.
- **Reputation:** customers leave **reviews** on **your shop's website**, which also shows your rating, what customers think (clean, value, selection, service, atmosphere), your **ranking against rival shops in town** and your visitors. Reply to reviews, feature an item, pick a theme and a tagline.
- **Sell more kinds of things:** sealed **booster boxes**, whole **binders as one lot**, **adult Pokémon**, **eggs**, packs, goods, cards and graded slabs.
- **Contracts:** customers ask for bigger orders (like ten of one pack, a graded card, a Pokémon, a box or a binder lot) and pay well above shelf price if you deliver in time. Accept up to two at once and hand over from your shelves or from what you own.
- **Goals** with coin rewards and a **day report** with an hour-by-hour chart of yesterday's takings. On Android a gentle reminder nudges you when the till is full, bills are due or a contract is running out.

### Tested, and what wasn't
- 173 automated JavaScript tests and 20 Python tests pass (shop rules, simulation, walking and collisions, bills, contracts, reviews, display editing, the all-or-nothing collection changes). The shop was walked round in a browser at phone size, including the shop front, decor, themes, walking out to the street, and opening every new menu.
- **Not tested on a real phone:** the walking controls, the update installer, and how the bigger 3D shop runs on older devices (it lowers its own picture quality if the frame rate drops). The numbers (rent, wages, contract rewards, review frequency) are a first guess: tell me what feels too stingy or too generous.
