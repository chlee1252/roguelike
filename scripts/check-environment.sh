#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot_bin="${GODOT_BIN:-godot}"
expected_version="$(cat .godot-version)"
actual_version="$("$godot_bin" --version)"
if [[ "$actual_version" != "$expected_version".* ]]; then
  echo "Expected Godot $expected_version; found $actual_version" >&2
  exit 1
fi
mkdir -p build
touch build/.gdignore
"$godot_bin" --headless --path . --editor --import > build/import.log 2>&1
"$godot_bin" --headless --path . --quit-after 300 --script tests/environment_smoke.gd > build/smoke.log 2>&1
grep -q ENVIRONMENT_SMOKE_OK build/smoke.log
if grep -E 'SCRIPT ERROR:|ERROR:' build/import.log build/smoke.log; then
  exit 1
fi
cat build/smoke.log
if [[ "${1:-}" == "--render" ]]; then
  "$godot_bin" --path . --quit-after 300 --script tests/environment_smoke.gd > build/render.log 2>&1
  grep -q ENVIRONMENT_SMOKE_OK build/render.log
  if grep -E 'SCRIPT ERROR:|ERROR:' build/render.log; then
    exit 1
  fi
  cat build/render.log
fi
