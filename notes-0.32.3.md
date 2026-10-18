## Collectify 0.32.3: much faster binders, packs and everything else

Android `.apk` only (the iPhone version is paused until further notice).

### What was slowing the app down, and what changed
- **Card pictures were downloaded again every single time.** The app was told never to keep anything it had downloaded, so every binder page and every pack re-fetched its pictures. Pictures are now kept on the phone, while your data and the app's own files are still never kept.
- **A background picture check ran at every launch.** The repair from 0.31.0 re-checked up to 600 card pictures after every update, and for bigger collections never finished, so it started over every launch. It now looks only at variant printings (the only ones that ever had missing pictures), 60 at a time, waits 45 seconds after launch, goes easy on the phone, and finishes once in total.
- **The whole collection was loaded again and again.** Opening one pack read every card you own twice, the idle hints read it every few minutes, and the shop read it each time you opened the stock list. Screens now share one copy until something in your collection changes.
- **Binders did far more work than needed.** The binder list built every card of every binder just to count them, and opening a binder page read the whole binder to show nine cards. Both now read only what they show. Loading the collection also did all its work twice; that is gone.
- **Every card in a binder checked a stored list of locked cards**, parsing it each time, which got slow once the shop had cards on shelves. It's read once a second now.
- **Graphics memory is given back.** The shop's and the island's 3D views kept their graphics memory after you left them, which slowed down opening packs. They are released if you stay away for 20 to 25 seconds and rebuilt when you return (the first look takes a moment longer).

### Tested
- 177 automated JavaScript tests pass. Checked in a browser at phone size: the shared collection copy, its refresh after a change, the faster lock check, and the shop and island rebuilding after a long absence. The new Android server code was built and run on the emulator: binder totals, pages and the whole collection give the same numbers as before, and the headers are right. I could not measure real speed on a phone, so tell me if anything is still slow, and where (which screen, how big your collection is).
