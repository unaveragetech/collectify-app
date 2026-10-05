## Collectify 0.17.3 - performance pass

Installs over your existing Collectify; your data is kept.

The effects added in the last few releases were too heavy for many phones. This release removes the biggest costs:

- **No more backdrop blurs.** Dozens of panels, rows and bars were blurring whatever was behind them, every frame, on top of an animated background. They now use solid translucent backgrounds (the look is nearly identical).
- **Background shader is cheap.** It now renders at a fraction of the resolution, at about 15 fps, and stops completely while a sheet, the game, the camera, the card viewer or pack opening is on screen.
- **The mine only draws when it's visible.** It pauses while a sheet (like *Pick packs*) or the pack opening covers it, runs at 30 fps when nothing is moving, and uses pre-rendered glows, crystals and pickaxe instead of re-computing gradients and shadows every frame. The progress text updates in place instead of rebuilding the panel.
- **Pick packs list:** thumbnails load lazily and off-screen rows aren't painted.
- **Pack opening:** removed the big animated blur and masks, simplified the foil wrapper, fewer floating orbs, and the particle layer only runs while particles exist.
- **Holographic cards:** the shader eases to 30 fps when only shimmering, skips the heaviest noise on lower rarities, and renders at a capped resolution.
- **Decorative loops** (button shimmer, coin shine, vault bobbing, spinning frame, binder foil shimmers) are off by default.
- **New "Effects" setting** (palette button): *Auto* measures your phone a couple of seconds after launch and switches to smooth mode if it can't hold ~30 fps; *Full effects* turns everything back on; *Smooth mode* forces the lightest settings.

I could only test this on an emulator, so I can't promise exact frame rates on your phone. If it's still not smooth, set Effects to *Smooth mode* and tell me which screen is slow.
