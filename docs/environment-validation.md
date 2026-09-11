# Environment validation

Validated on 2026-09-11 before gameplay development.

## Laptop and installed tools

- Apple Silicon Mac, Apple M2 Max.
- Godot `4.7.2.stable.official.ed1daf0bf`, installed through Homebrew.
- Standard GDScript editor at `/Applications/Godot.app`, with CLI launcher on PATH.
- Matching `4.7.2.stable` export templates installed after SHA-512 verification
  against the official release checksum file.
- Xcode 26.4, build 17E192, already installed and selected.
- Existing Android SDK and JDK 17.0.6 configured in Godot's local editor settings.
- Android build-tools 35.0.1 installed; SDK platforms 35 and 36 already present.

## Checks

| Check | Result |
| --- | --- |
| Pinned engine version | Passed |
| Headless editor import and GDScript parsing | Passed |
| Bootstrap scene load and visible status node | Passed |
| Native macOS Compatibility renderer | Passed on Apple M2 Max |
| Rendered screenshot | Inspected; centered bootstrap status rendered correctly |
| macOS debug ZIP export | Passed |
| Exported macOS application startup | Passed; ran 120 frames and exited with code 0 |
| Android ARM64 debug APK export | Passed |
| APK signature verification | Passed with v2 and v3 signatures |
| APK metadata | `com.lastcommando.prototype`, landscape, ARM64, target SDK 36 |

Repeat startup/render checks with `bash scripts/check-environment.sh --render`.
Export commands are in the README. Local logs, screenshot, ZIP, APK, and extracted
macOS app are under `build/`, intentionally excluded from Git.

Initial sandboxed startup could not write Godot's standard Library directories.
Checks passed with normal application access. Export validation also identified
the required ARM texture import setting and project icon; both are configured.

## Scope

This validates the development environment and an empty bootstrap, not gameplay
performance. No game features are implemented. Android device/emulator runtime,
iOS export/signing/device runtime, store packaging, custom native builds, and
swarm performance have not been tested. iOS templates and Xcode are available,
but no Apple team or signing credentials have been configured for this project.
