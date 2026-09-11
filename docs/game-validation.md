# Playable alpha validation — 2026-09-11

## Automated checks

Run `bash scripts/test-game.sh --render` from the repository root.

- Combat: pool capacity and reuse, diagonal movement, automatic kills, XP pickup,
  upgrade pause, evolution prerequisites/cache consumption, damage invulnerability,
  and exact extraction timing.
- UI: deployment input, touch drag, finger ownership, emulated-mouse isolation,
  pause and countdown, early weapon offers, single upgrade consumption, maxed-build
  fallback choices, and restoring a saved pending upgrade without changing RNG state.
- Persistence: serialized round-trip at five minutes and byte-identical continuation
  after the next simulated step; malformed field types rejected.
- Full mission: seeded collection bot runs all ten minutes at 60 simulation steps
  per second, checks the boss event and entity caps, and completes weapon evolution.
  Invulnerability is enabled **only in this test** to exercise the entire schedule.
- Stress: 500 enemies plus 600 hostile projectiles, all three evolved weapons.
- Native graphics: captured and inspected briefing, combat, and upgrade screens.

The final seeded run reached level 28, 5,548 kills, and all three evolutions.
On the M2 Max, the 500-enemy/600-projectile stress scenario measured approximately
1.4 ms at the 95th percentile for simulation alone. Full-run timing varied under
concurrent simulator startup; scheduling outliers occurred. These are desktop
simulation measurements, not whole-frame or physical-mobile performance claims.

Logs and screenshots are under ignored `build/`. The test runner fails on script
errors, engine errors, missing success markers, or reported object leaks.

## Android

- ARM64 debug APK export and signature verification passed.
- Installed and launched on an API 33 ARM64 Pixel XL emulator using host GPU.
- Inspected landscape briefing and combat rendering.
- Tapped Deploy and dragged the floating joystick; confirmed movement and automatic
  kills, with the joystick visible in `build/android-touch.png`.
- Backgrounded the app, force-stopped it, relaunched, and selected Continue.
  The saved run returned paused with the previous elapsed time and kill count
  (`build/android-continued.png`).
- An API 37 development emulator initially suffered System UI hangs. Validation
  moved to API 33; that emulator problem is not treated as a gameplay test failure.
- Physical phones, thermal soak tests, and store AAB signing remain untested.

## iOS

- Generated Xcode project and built an unsigned x86_64 simulator app successfully.
- Created `LastCommando QA` on the installed iOS 18.4 runtime and booted it with
  `--arch=x86_64`. Installed and launched the app successfully.
- Captured and inspected the correctly rendered briefing in `build/ios-menu.png`.
- Interactive Simulator control was blocked while macOS Accessibility and Screen
  Recording permissions for the desktop automation tool remained pending; iOS touch/lifecycle behavior is **not** claimed as verified.
- Native ARM64 simulator linking is blocked by the installed official template:
  its xcframework advertises ARM64 simulator support, while the actual archive
  contains x86_64 objects. The corresponding upstream report is
  [Godot #118161](https://github.com/godotengine/godot/issues/118161).
- The x86_64 app cannot install into the normal ARM64 iOS 26.4 simulator. The
  iOS 18.4 x86_64 boot mode is the tested local workaround.
- Physical iOS devices, Apple team signing, and App Store packaging remain untested.

The simulator preset contains `0000000000` only as a placeholder required by the
exporter. It is not an Apple account/team. All local simulator builds disable code
signing. Replace that placeholder with a real team only when configuring a device
or distribution build.

## Known alpha limits

The complete core loop is playable. This is not a finished commercial release:
content/art breadth, human balance testing, persistent unlocks, localization, and
physical-device performance work remain. No files have been pushed or published.
