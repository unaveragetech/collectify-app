## Collectify 0.25.0 — visit friends' islands, and 91 decorations to make your own

Android `.apk` and iPhone/iPad `.ipa`, same version, same features.

### Island visits
- **Open your island to friends on the same Wi-Fi** (Island → Menu → Visit → *Open my island to visitors*) and show the QR code. A friend scans it from the same menu or from the Trade tab's scanner and walks around your island, seeing everything: plots, Pokémon, decorations, the weather and the time of day you've chosen. Up to four visitors at once, each shown on your island with a name tag.
- **Visitors can help:** water thirsty crops, harvest ripe ones (you keep the crops, they keep a small share), pick up drops and finds, pet and feed your Pokémon, and top up the food and water dishes. A *Ways to help* list shows what needs doing and walks them there.
- **They can leave something behind:** gifts from their bag (food, toys, berries, even decorations), coins (up to 2,000 per visit), a note in your **guestbook**, or a wave. Your phone shows everything as it happens, with a log of visits, helpers, gifts and hearts.
- **Souvenirs:** each island a visitor visits adds a postcard to their collection, and helping earns a little XP and coins (capped each day: 80 coins, 120 XP).
- **You stay in charge.** Your phone applies every request; a visitor can't touch your bag, your coins or your settings, every kind of help has a limit per visit, and you can ask anyone to leave or close the island at any time. Everything travels only between the two phones on your network.
- If the host never answers a gift or a donation (for example the connection drops), it is returned to the visitor after 45 seconds.

### Decorations (Island → Menu → Decor)
- **91 designs in 8 collections and 550 colourways:** paths and ground (cobble, boardwalk, mosaic tiles, picnic blanket, flower beds ...), fences and walls, lights, plants and trees (oak, pine, blossom, palm, willow, birch, orchard ...), furniture and garden (bench, hammock, swing, parasol set, market cart ...), water features (fountain, ponds, koi, bridge, stream), statues and fun (totem, snowman, sandcastle, wind chime, balloons, festive tree, trophy ...) and little buildings (tent, gazebo, cabin, lookout tower, greenhouse).
- **Place things anywhere:** buy a piece, tap the ground to move it, nudge it with the arrows, turn it and pick its colour, then place it. Move, recolour or store anything later; stored pieces can be sold for half.
- **They come alive:** lights glow at night, campfires and braziers flicker, the fountain splashes, balloons bob, flags, banners and chimes sway, koi swim and blossom trees shed petals.
- **Island looks:** eight ground colour schemes, falling petals / autumn leaves / snow / bubbles / starlight, and a sky that can stay at sunrise, midday, golden hour or night.
- Room for 22 pieces at level 1, growing with your level and island expansions (110 at level 25 on the full island). A **charm** score shows how lovely your island is; visitors see it.
- The five original decorations (lanterns, flower garden, bench, bunting, windmill) are unchanged.

### Also
- New website pages cover decorating and visiting.
- Fixed the trade scanner so it also accepts island-visit codes.

### Tested, and what wasn't
- The visit server (the small relay in the app) has the same checks in all three versions (desktop, Android, iPhone): 26 HTTP checks pass against the desktop server and the Android app on an emulator; the iPhone server is tested in CI. The game rules for decorating, visiting, gifts, caps and rewards have their own tests (10 pass).
- Ran a full visit between two browser sessions: joining, watering/foraging/petting, a donation, a guestbook note, a wave, the host seeing it all and the visitor receiving rewards.
- Every decoration was checked visually in a desktop browser. **Not tested: a visit between two real phones**, and the 3D scene on a real iPhone. Visiting needs both phones on the same network; on iPhone, Local Network access must be on.
