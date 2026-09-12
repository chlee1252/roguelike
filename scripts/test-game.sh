#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
touch build/.gdignore
godot_bin="${GODOT_BIN:-godot}"
expected="$(cat .godot-version)"
actual="$("$godot_bin" --version)"
[[ "$actual" == "$expected".* ]] || { echo "Expected $expected, got $actual" >&2; exit 1; }
"$godot_bin" --headless --path . --editor --import > build/game-import.log 2>&1
if grep -E 'SCRIPT ERROR:|ERROR:' build/game-import.log; then exit 1; fi
for suite in combat_test cat_test shop_test adventure_test ui_test feedback_test haptics_test audio_mix_test full_run_test; do
  "$godot_bin" --headless --path . --script "tests/$suite.gd" > "build/$suite.log" 2>&1
  if grep -E 'SCRIPT ERROR:|ERROR:|leaked at exit' "build/$suite.log"; then exit 1; fi
  case "$suite" in
    combat_test) marker=COMBAT_TESTS_OK ;;
    cat_test) marker=CAT_TEST_OK ;;
    shop_test) marker=SHOP_TEST_OK ;;
    adventure_test) marker=ADVENTURE_TEST_OK ;;
    ui_test) marker=UI_TEST_OK ;;
    haptics_test) marker=HAPTICS_TEST_OK ;;
    audio_mix_test) marker=AUDIO_MIX_TEST_OK ;;
    feedback_test) marker=FEEDBACK_TEST_OK ;;
    full_run_test) marker=FULL_RUN_TEST_OK ;;
  esac
  grep -q "$marker" "build/$suite.log"
  grep -E 'TESTS?_OK|SIMULATION|STRESS' "build/$suite.log"
done
if [[ "${1:-}" == "--render" ]]; then
  "$godot_bin" --path . --quit-after 600 --script tests/visual_test.gd > build/visual-test.log 2>&1
  if grep -E 'SCRIPT ERROR:|ERROR:|leaked at exit' build/visual-test.log; then exit 1; fi
  grep VISUAL_TEST_OK build/visual-test.log
fi
