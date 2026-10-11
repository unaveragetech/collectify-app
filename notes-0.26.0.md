## Collectify 0.26.0 — much faster tapping, island visit fixes, optional joystick and auto camera

Android `.apk` and iPhone/iPad `.ipa`, same version, same features.

### Tapping blocks (Treasure Box)
- **Every tap now lands the instant your finger does.** Before, a tap only did damage when its swing animation reached the strike, and each new tap restarted the swing, so tapping faster than about 6 a second landed nothing at all. Now there is no wait, and the pickaxe swings as fast as you tap.
- **You can tap as fast as you can.** Bursts of up to 18 taps a second count, about 11 a second for ten seconds, 7 a second for a minute and 6 a second for five minutes. That is roughly three times the old best pace.
- **What a person can't do is refused:** a metronome-perfect rhythm (an auto-clicker), the same pace for minutes on end, and taps sent by a script instead of a finger. A refused tap does nothing; the next one counts again as soon as the pace allows. The "+1 coin every 20 taps" bonus only counts a human pace (under 8 a second).

### Island visits
- **Visitors can now see the host.** The host's character walks around on every visitor's screen (it was only the other way round before).
- **No more lag building up.** Every update used to carry every answer ever given and everyone else's requests, which grew until phones struggled. Updates now carry only what's new (a typical one went from about 6 KB to 0.7 KB after 50 actions), the host's Visit tab no longer redraws itself every time someone moves, and a visitor's position is only sent when the last one has arrived.
- **The Leave button works.** Its confirmation was appearing underneath the visit screen, so it looked dead. It now asks inside the visit screen (Stay / Leave), and Android's back button does the same.

### Island controls (Island → Menu → Settings, and ⚙️ while visiting)
- **On-screen joystick (optional):** drag the stick bottom-left to walk, in first or third person; tapping the island still works.
- **Auto camera (optional):** the camera swings round to look the way you're walking, whether you use the stick or tap to walk. While you hold the stick its directions stay fixed so you don't end up walking in circles. Dragging the screen to look around always wins.

### Tested, and what wasn't
- Tap limiter: 8 automated tests, plus live in a browser: 45 human-paced taps at about 13 a second all landed; 150 perfectly even taps at 15 a second landed 29.
- Visit server: 28 HTTP checks pass on the desktop server and on the Android app (emulator); the iPhone server's tests run in CI. Ran a full visit in two browser sessions: the visitor saw the host, the Leave dialog appeared and left.
- Joystick and auto camera checked in a browser (stick moves the character; the camera follows only with auto camera on).
- Not tested on a real phone. How the tapping feels on a real touchscreen, and whether the limits suit your fastest tappers, are worth a try: tell me if a fast tapper still gets refused.
