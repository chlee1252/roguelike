#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ $# != 2 ]]; then
  echo 'Usage: bash scripts/install-iphone.sh <iPhone UDID> <Apple Team ID>' >&2
  exit 2
fi
iphone_udid="$1"
apple_team_id="$2"
mkdir -p build/ios-device
if ! godot --headless --path . --export-debug 'iOS Device' build/ios-device/CatWalk.zip > build/catwalk-ios-export.log 2>&1; then
  tail -30 build/catwalk-ios-export.log
  exit 1
fi
if rg 'SCRIPT ERROR:|ERROR:' build/catwalk-ios-export.log; then exit 1; fi
if ! xcodebuild -project build/ios-device/CatWalk.xcodeproj -scheme CatWalk \
  -configuration Debug -sdk iphoneos -destination "id=$iphone_udid" \
  -derivedDataPath build/ios-device-derived DEVELOPMENT_TEAM="$apple_team_id" \
  CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  build > build/catwalk-iphone-build.log 2>&1; then
  tail -30 build/catwalk-iphone-build.log
  exit 1
fi
xcrun devicectl device install app --device "$iphone_udid" \
  build/ios-device-derived/Build/Products/Debug-iphoneos/CatWalk.app
xcrun devicectl device process launch --device "$iphone_udid" com.marc.catwalk
