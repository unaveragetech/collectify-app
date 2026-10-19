## Collectify 0.36.1: staff and customers that keep moving, a floor that really gets cleaned, building where there is room, and a clearer island

Android `.apk` only (the iPhone version is paused until further notice).

### 🚶 Staff walk the shop and do their jobs
- **No more standing at stations.** Workers spend the day on foot: each job has a *round* (a loop of stops with a short look about at each one) and they walk it whenever nothing urgent needs doing.
  - **Clean:** sweeps rubbish and mops stains, then walks the floor looking for more.
  - **Stock:** fills displays with empty spots, and checks the rest of the displays in between.
  - **Handle customers:** does laps of the floor, comes back to the till now and then, and walks over to help shoppers who are still looking.
  - **Manage storage:** goes round the worn displays, repairing them (and the floor in between if there are only a few).
  - **Decorate:** tends each piece of decor, with a walk round the shop between pieces.
  - **Process orders:** counter, back room, counter.
  - **Deliver goods:** runs out to the doorstep with a parcel and back, and makes rounds of the door, the sidewalk and the back room.
- **The guard patrols**: through the shop, the doorway, along the **sidewalk** and, if you have one, round the **car park**, and still chases thieves.
- A change of priority still takes effect at once.

### 🧽 The cleaners keep the shop clean, and you can see what they are cleaning
- **Why customers complained about a dirty floor with nothing to clean:** the grime that builds up as people walk through was a hidden number, and the cleaners' sweeping happened out of sight in a single step. Now **grime shows up as dark stains on the floor**, one for every few points of it, and your cleaners walk to them and **mop them one at a time** (a stain takes its grime with it). What customers judge the floor by is now exactly what you can see: rubbish plus stains.
- You can tap a stain yourself to mop it. Away from the shop (or in a store you are not in) the cleaning is still counted for you, and a deep clean still clears everything.

### 🧍 Customers and staff no longer get stuck
- Everyone **plans their walk again** when furniture is built, moved or sold, if they stop making progress, or if the way is closed. Somebody standing where a piece of furniture was put down steps out of it. A customer who can't get anywhere heads for the door instead of standing there for ever, and a worker who is lost goes back to the door and starts their round again.
- The **queue at the till** bends round furniture instead of running in a straight line that one table could cut short.

### 🔨 Building inside the shop
- **"It can't go there" even with plenty of room:** the rule insisted that *every* display in the shop could be reached, so if one display had ever been cut off (an old layout, a room that changed) nothing else could be built anywhere. Now a piece is only refused if it **cuts off something that could be reached before**, or if it couldn't be reached itself, and the message names what it would cut off.
- A wide display (a table, a shelf) now needs **any** free cell along its front, not just the middle one, and customers use the free cell next to a plant or a rug.

### 🏝️ A clearer island
- Solid decorations can no longer be put on a **walking path, the plaza where the paths meet, or a building**. (Flat things like cobbles, mats and rugs can still go anywhere.)
- Islands that had filled up are **tidied once**: every decoration in the way moves to the nearest free spot (never under a tree or on top of another piece), and any that has nowhere to go goes into your Decor stock. A **🧹 Clear the paths** button in the Decorate screen does the same whenever you like, and warns you how many pieces are in the way. Nothing is ever lost.

### 🔧 Also
- The flaky "Complete all" test is fixed (the test, not the game).

### Tested
- 259 automated JavaScript tests and 20 Python tests pass, including new ones for: every kind of worker keeping on the move and visiting several places, the guard reaching the sidewalk and the car park, cleaners mopping every stain until the dirt reads zero, workers recovering when walls go up across their path or furniture lands on them, customers never standing still while a divider wall goes up, the queue bending round a plant, a cut-off display not blocking other building, and a crowded island being tidied without losing anything.
- In a browser at phone size the stains show on the floor, and on an Android emulator an existing save opens with its old grime shown as stains. Not tried on a real phone, and the staff walking was checked by the automated tests rather than watched in real time.
