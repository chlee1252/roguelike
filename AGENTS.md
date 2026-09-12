# Repository Guidelines

## Project Structure & Module Organization

This is a Godot 4.7.2 GDScript project. `project.godot` launches `app/game.tscn`; scenes and the application icon live in `app/`. Core simulation, progression, audio, haptics, and shop code belongs in `game/`, while reusable drawing and theme helpers belong in `ui/`. Store fonts and generated audio under `assets/`. Headless GDScript suites are in `tests/`, and the isolated Python purchase-ledger prototype is in `server/`. Keep platform and validation scripts in `scripts/`, documentation in `docs/`, and generated logs, screenshots, exports, and packages in the ignored `build/` directory.

## Build, Test, and Development Commands

- `godot --path .` runs the game locally.
- `godot --editor --path .` opens the project in the Godot editor.
- `bash scripts/check-environment.sh` verifies the pinned engine version, imports resources, and smoke-tests scene loading. Add `--render` for a windowed rendering check.
- `bash scripts/test-game.sh` runs all headless gameplay suites. Add `--render` to capture and validate major screens.
- `python3 -m unittest server.test_ledger -v` tests receipt deduplication, concurrency, persistence, authentication, and pricing boundaries.
- `godot --headless --path . --export-debug macOS build/CatWalk.zip` creates a macOS debug export. Android and iOS procedures are documented in `README.md`.

## Coding Style & Naming Conventions

Follow existing Godot conventions: tabs for GDScript indentation, `snake_case` for variables and functions, `PascalCase` for classes/types, and `UPPER_SNAKE_CASE` for constants. Add static types and return annotations where practical, and use `:=` when inference is clear. Keep gameplay rules deterministic and separate from rendering so they remain headlessly testable. Python uses four spaces and standard-library style. No automatic formatter or linter is configured; match neighboring code and keep diffs focused.

## Testing Guidelines

Name GDScript suites `tests/<feature>_test.gd`. They extend `SceneTree`, report failures with `push_error`, exit nonzero on failure, and print a unique `*_TEST_OK` marker consumed by `scripts/test-game.sh`. Add regression coverage for behavior changes and run the full headless suite before opening a pull request. For UI or rendering changes, also run `--render` and review artifacts in `build/`.

## Commit & Pull Request Guidelines

History follows Conventional Commit subjects such as `feat:`, `fix:`, and `docs:`. Use an imperative, specific summary and keep each commit scoped to one concern. Pull requests should explain player-visible and technical effects, list verification commands, link relevant issues or design documents, and include screenshots for UI changes. Never commit `.godot/`, build outputs, signing files, keystores, local databases, tokens, or Apple team credentials.
