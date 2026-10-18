## Collectify 0.32.2: island, game and shop progress can no longer be rolled back by a lost save

Android `.apk` only (the iPhone version is paused until further notice).

### What this fixes
When the app goes to the background it saves the island, the game and the shop at the same moment. The browser only allows about 64 KB of "keep this request alive" saves at once, and a save that goes over that is simply refused. As the shop was added, the three saves together could pass the limit, so the island's save could be lost while the copy on the phone had it. The next time the app opened it took the older copy from the server, which looks exactly like island progress, layout and spacing being thrown away.

- The three saves now share the allowance, and anything that doesn't fit is sent as a normal request.
- The island now works like the game and the shop already did: it keeps a timestamped copy on the phone, and if that copy is newer than the one on the server it is used and sent up again. A save the server refuses is retried until it goes through.

### Nothing else changed
The island's code (layout, paths, nature, adventure, progression rules) is byte for byte the same in 0.30.0, 0.31.0, 0.32.0 and 0.32.1; this release only changes how its progress is saved and loaded. If your island still looks different from before, tell me what (a screenshot helps) and which version you last saw it right.

### Tested
- 177 automated JavaScript tests pass. In a browser I checked that a newer local island copy is picked over an older server one, sent up, and that a normal save still reaches the server. Not tried on a real phone.
