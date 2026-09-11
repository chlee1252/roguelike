# 골목의 밤냥

어느 날부터 귀신이 보이기 시작한 평범한 길고양이가 한국의 밤골목을 산책하는 Godot 4 자동전투 로그라이트입니다. 고양이는 세상을 구하러 나선 영웅이 아닙니다. 밥과 안전한 자리를 찾아 걷다 괴이를 돌려보냅니다.

**현재 플레이:** 파스텔빛 해솔빌라 골목, 생선뼈 관통·털뭉치 경로·튕기는 장난감 공 3종과 진화, 강아지·까마귀·청소기 등을 본뜬 앙숙 괴이 8종, 음식, 상자 숨기·밥그릇 회복·담장 충격파. 고양이 픽셀은 [참고 이미지](docs/cat_pixel.png)의 읽기 쉬운 귀·눈·윤곽을 참고해 새로 그렸습니다.

**클리어 조건:** 14분에 등장하는 스테이지 보스 **멍멍 꿈대장**을 쓰러뜨려야 합니다. 체력 절반 아래에서 2단계 패턴으로 바뀌며, 15분이 지나도 보스가 살아 있으면 전투가 이어집니다.

**최신 변경:** [귀여운 테마·생활형 무기·보스 클리어 규칙](docs/cute-theme.md).

**전체 설계:** [세계관·무기 20종·진화 15종·스테이지 8개와 25개 기획 항목](docs/cat-game-design.md). 문서의 확장 콘텐츠는 아직 모두 구현된 것이 아닙니다. [현재 구현과 기술 구조](docs/gameplay.md)에서 구분해 확인할 수 있습니다.

## 바로 실행하기

이 노트북에는 Godot, 내보내기 템플릿, Android SDK, JDK 17, Xcode와 시뮬레이터가 설치되어 있습니다.

```sh
cd /Users/marc/dev/roguelike
godot --path .
```

**밤 산책 시작**을 누르세요. 터치 화면에서는 화면을 누르고 끌면 가상 조이스틱이 나타납니다. PC에서는 WASD·방향키 또는 마우스 드래그로 이동합니다. Esc 또는 오른쪽 위 버튼으로 일시 정지합니다. 설정에서 소리, 조이스틱 위치, 피격 효과를 바꿀 수 있습니다. **이어하기**는 자동 저장한 산책을 복원합니다.

에디터로 열려면 `godot --editor --path .`을 실행하세요.

빌드 파일명 `LastCommando`와 패키지 ID `com.lastcommando.prototype`은 기존 설치·시뮬레이터 명령 호환을 위해 유지했습니다. 화면에 표시되는 게임 이름은 **골목의 밤냥**이며, 새 저장 형식을 사용해 이전 군사 테마 저장 데이터와 분리합니다.

## Android 에뮬레이터에서 열기

이 노트북에서 검증한 기기는 **Pixel_XL_Edited_API_33** ARM64 AVD입니다. Android Studio → Device Manager에서도 찾을 수 있습니다. API 37 기기는 이 환경에서 System UI가 멈추는 문제가 있어 API 33을 사용합니다.

먼저 APK를 만듭니다.

```sh
cd /Users/marc/dev/roguelike
mkdir -p build
godot --headless --path . --export-debug Android build/LastCommando.apk
```

터미널에서 에뮬레이터 창을 엽니다. 이 명령은 에뮬레이터를 종료할 때까지 실행 상태로 남습니다.

```sh
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
"$ANDROID_SDK_ROOT/emulator/emulator" -list-avds
"$ANDROID_SDK_ROOT/emulator/emulator" -avd Pixel_XL_Edited_API_33 \
  -gpu host -no-snapshot -port 5582
```

**새 터미널 탭**에서 아래 명령을 실행하세요. Android 홈 화면이 나타난 후 설치합니다.

```sh
cd /Users/marc/dev/roguelike
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
"$ANDROID_SDK_ROOT/platform-tools/adb" -s emulator-5582 wait-for-device
"$ANDROID_SDK_ROOT/platform-tools/adb" -s emulator-5582 install --no-incremental -r build/LastCommando.apk
"$ANDROID_SDK_ROOT/platform-tools/adb" -s emulator-5582 shell am start -W \
  -n com.lastcommando.prototype/com.godot.game.GodotAppLauncher
```

게임은 가로 화면으로 열립니다. 마우스로 누르고 끌어 이동할 수 있습니다. 이미 Android Studio에서 실행한 기기를 쓴다면 `adb devices`로 확인한 ID를 `emulator-5582` 대신 넣으세요. 설치 대상은 ARM64 기기여야 합니다. 코드 수정 후 APK 생성·설치·실행을 반복하면 됩니다.

## iOS 시뮬레이터에서 열기

이 노트북에서 검증한 기기는 **LastCommando QA / iPhone 16 Pro / iOS 18.4**입니다. 현재 설치된 Godot 4.7.2 템플릿의 시뮬레이터 라이브러리는 x86_64만 포함하므로, Xcode 빌드와 시뮬레이터 모두 x86_64로 실행해야 합니다. 기본 ARM64 iOS 26.4 기기에는 이 빌드가 설치되지 않습니다.

먼저 Xcode 프로젝트를 내보내고 서명 없이 시뮬레이터용 앱을 빌드합니다.

```sh
cd /Users/marc/dev/roguelike
mkdir -p build/ios
godot --headless --path . --export-debug 'iOS Simulator' build/ios/LastCommando.zip
xcodebuild -project build/ios/LastCommando.xcodeproj -scheme LastCommando \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/ios-x86-derived ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO build
```

아래 ID는 **이 노트북에 만들어 둔 QA 기기**입니다. 기기를 삭제했다면 `xcrun simctl list devices available`로 확인하거나, Xcode → Window → Devices and Simulators에서 iOS 18.4 기기를 만든 후 ID를 바꾸세요.

```sh
IOS_DEVICE_ID=116C5A53-D922-47A5-BFE2-7F1F3B624B14
xcrun simctl boot "$IOS_DEVICE_ID" --arch=x86_64
xcrun simctl bootstatus "$IOS_DEVICE_ID" -b
open -a Simulator --args -CurrentDeviceUDID "$IOS_DEVICE_ID"
xcrun simctl install "$IOS_DEVICE_ID" \
  /Users/marc/dev/roguelike/build/ios-x86-derived/Build/Products/Debug-iphonesimulator/LastCommando.app
xcrun simctl launch "$IOS_DEVICE_ID" com.lastcommando.prototype
```

이미 같은 아키텍처로 부팅했다면 `boot` 명령은 생략합니다. ARM64로 켰다면 해당 QA 기기만 `xcrun simctl shutdown "$IOS_DEVICE_ID"`으로 끈 후 다시 부팅하세요. 최초 부팅은 수 분 걸릴 수 있습니다. 창이 세로 방향이면 Simulator의 **Device → Rotate Left/Right**로 회전합니다. 마우스로 드래그해 이동하세요.

코드 수정 후 내보내기·빌드·설치·실행을 반복합니다. `.zip`은 내보내기 대상 이름이며, 이 프리셋은 실제로 Xcode 프로젝트 폴더를 생성합니다. 팀 ID `0000000000`은 서명 없는 시뮬레이터용 자리표시자입니다. 실제 iPhone 설치 및 App Store 배포에는 별도 개발자 서명 설정이 필요합니다.

## 개발 환경과 테스트

- Godot **4.7.2 stable**, GDScript. 정확한 버전은 `.godot-version`에 고정합니다.
- Compatibility 렌더러, 가로형 640 × 360 기준 화면, 픽셀 아트 최근접 필터.
- macOS: `/Applications/Godot.app`, CLI `godot`.
- Android: JDK 17, SDK `~/Library/Android/sdk`, ARM64 디버그 APK.
- iOS: Xcode, iOS 18.4 시뮬레이터 런타임.
- 한글 폰트: Pretendard Regular/Bold, [SIL Open Font License](assets/fonts/LICENSE.txt).

```sh
bash scripts/check-environment.sh
bash scripts/check-environment.sh --render
bash scripts/test-game.sh --render
```

환경 테스트는 버전·리소스 가져오기·장면 로딩을 확인합니다. 게임 테스트는 털 경로·뚜껑 연쇄·상자 시간 제한·음식 효과·건물 충돌과 전투, 터치 입력, 성장 선택, 일시 정지, 저장 복원, 15분 전체 산책, 최대 개체 수 부하를 검증합니다. 렌더링 테스트는 실제 창에서 메뉴·전투·업그레이드·설정·결과 화면을 캡처해 `build/`에 저장합니다. 로그와 빌드 산출물은 Git에서 제외합니다.

새 Mac에서는 [고정 버전 엔진](https://godotengine.org/download/archive/4.7.2-stable/)과 [동일 버전 내보내기 템플릿](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable)을 설치하세요. 템플릿과 공식 `SHA512-SUMS.txt`를 받은 다음 아래 명령으로 검증·설치할 수 있습니다. Python 3.11 이상이 필요합니다.

```sh
python3 scripts/install-templates.py /path/to/templates.tpz /path/to/SHA512-SUMS.txt
```

Godot의 Editor Settings → Export → Android에서 JDK 17 및 SDK 경로를 지정합니다. 이 노트북의 JDK 경로는 `/Users/marc/Library/Java/JavaVirtualMachines/temurin-17.0.6/Contents/Home`입니다. 설정은 로컬에만 저장합니다.

macOS 앱 빌드:

```sh
godot --headless --path . --export-debug macOS build/LastCommando.zip
```

현재 전투 구조·무기 진화·분 단위 웨이브는 [게임 설계](docs/gameplay.md), 기존 플랫폼 검증 결과는 [게임 검증 기록](docs/game-validation.md), 초기 설치 기록은 [환경 검증](docs/environment-validation.md)에 정리했습니다.
