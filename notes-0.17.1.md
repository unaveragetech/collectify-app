## Collectify 0.17.1

Installs over your existing Collectify; your data is kept.

### Cards, rebuilt
The old "pop" effect (a clipped copy of the artwork shifted over the card) is gone. Cards are now drawn by a WebGL shader:

- **Layered parallax.** A depth map worked out from the card's own picture makes the art slide behind the frame as the card tilts, with nearer parts of the art moving more than the background. A soft shadow from the frame falls across the art as it moves. No clipped copies, no seams.
- **Real foil.** Rare cards get a view-angle rainbow with fine diffraction lines that follows the picture's own light and dark; ultra rares get gold foil and secret rares a cosmic rainbow with a slow aurora. Plus glitter, an etched-relief highlight and a rim light.
- **Finger-driven.** Where you touch is the light and the tilt. Holding your finger on a card deepens the parallax and strengthens the foil and sparkle, easing back when you let go. Ultra and secret rares also shimmer on their own.
- **Where it applies:** pack-opening cards and the full-screen card viewer (zooming in switches back to the sharp photo, so grading is unaffected). If a device can't do WebGL, the plain card with the older CSS foil is shown instead.

Tested on an Android emulator and a desktop browser, not on a physical phone.
