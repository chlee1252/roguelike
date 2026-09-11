# Last Commando

Godot 4 environment baseline for a 2D mobile survival game. This commit contains
only project setup and environment checks; gameplay is not implemented yet.

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
