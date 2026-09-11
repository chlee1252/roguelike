# Last Commando

A playable 2D military survival alpha for Godot 4. Survive ten minutes with automatic
weapons, pixel-art infantry and vehicles, weapon evolutions, and touch movement.

Run `godot --path .`, then select **Deploy**. Use WASD/arrows, mouse drag, or the
floating touch joystick. Escape pauses. Settings include sound, joystick side, and
hit flashes. **Continue** restores your saved deployment.

See [gameplay and architecture](docs/gameplay.md) and [validation results](docs/game-validation.md).

## Toolchain

- Godot **4.7.2 stable**, standard build with typed GDScript.
- Compatibility renderer, landscape 640 × 360 reference viewport.
- macOS installation: `/Applications/Godot.app`; CLI: `godot`.
- Android: JDK 17, Android SDK platforms 35/36, build-tools 35.0.1.
- iOS: Xcode on macOS; matching Godot iOS templates are included in the template bundle.

The exact engine release is recorded in `.godot-version`. Homebrew installs the
current version, so for future machines use the
[4.7.2 release archive](https://godotengine.org/download/archive/4.7.2-stable/)
if Homebrew has moved ahead. Do not upgrade the engine without retesting exports.

## Open and test

```sh
godot --editor --path .
bash scripts/check-environment.sh
bash scripts/check-environment.sh --render
bash scripts/test-game.sh --render
```

The second command checks the pinned version, imports the project, loads the
bootstrap scene, and fails on engine/script errors. The third also opens a native
window, renders the bootstrap, saves `build/environment-smoke.png`, and exits.
Both require Godot's normal access to its Library data/cache folders; the graphics
test also needs access to the desktop session. Logs and builds are ignored by Git.

## Install matching export templates

Download `Godot_v4.7.2-stable_export_templates.tpz` and `SHA512-SUMS.txt` from the
[official release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable).
Then run:

```sh
python3 scripts/install-templates.py /path/to/templates.tpz /path/to/SHA512-SUMS.txt
```

The installer checks the official SHA-512 checksum before extracting into
`~/Library/Application Support/Godot/export_templates/4.7.2.stable`.
It uses Python 3.11 or later and needs permission to write to that Library folder.

In Godot Editor Settings → Export → Android, select your installed JDK 17 directory
and `~/Library/Android/sdk`. These paths are machine-local, not committed settings.
See the [Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

## Local exports

```sh
mkdir -p build
godot --headless --path . --export-debug macOS build/LastCommando.zip
godot --headless --path . --export-debug Android build/LastCommando.apk
```

The macOS preset uses ad-hoc signing for local testing. The Android preset produces
an ARM64 debug APK using prebuilt templates, without Gradle or a custom native
build. Neither is a store release. The package identifier is provisional.

iOS signing/team configuration and physical-device testing are separate steps;
no signing identity or credentials are stored here. See the
[iOS export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html).

See [environment validation](docs/environment-validation.md) for checks performed
on the development laptop.

The game test suite covers combat, touch ownership, upgrades, pause/resume, save
round-trips, a complete seeded ten-minute mission, and a maximum-capacity stress
scenario. Rendering tests save menu/combat/upgrade screenshots under `build/`.

## iOS simulator workaround on this laptop

The installed 4.7.2 templates contain an x86_64-only simulator archive despite
advertising ARM64. Use the installed iOS 18.4 runtime booted in x86_64 mode for
local testing; normal ARM64 simulator linking currently fails.

```sh
mkdir -p build/ios
godot --headless --path . --export-debug 'iOS Simulator' build/ios/LastCommando.zip
xcodebuild -project build/ios/LastCommando.xcodeproj -scheme LastCommando \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/ios-x86-derived ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO build
```

The export writes an Xcode project directory; the `.zip` output name is the Godot
export target name. The preset's team ID is a simulator-only placeholder, not a
configured signing account. Detailed platform results and limits are in
[game validation](docs/game-validation.md).
