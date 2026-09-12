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

## 2026-09-11 — 한글 UI 및 디자인 개선

Pretendard 한글 폰트를 포함하고 메뉴, HUD, 장비 선택, 설정, 일시 정지,
결과 화면과 웨이브 알림을 한글로 변경했다. 둥근 패널, 청록·민트 팔레트,
장비 아이콘과 시작 화면의 전술 지형 일러스트를 적용했다.

- 전투·UI·저장·10분 전체 작전·부하·실제 창 렌더링 테스트 통과.
- 창 포커스 변경 알림에서 UI를 즉시 재구성하던 오류 수정 및 회귀 테스트 추가.
- 메뉴·전투·장비 선택·설정·일시 정지·승리·패배 화면 캡처 확인.
- Android API 33 ARM64 에뮬레이터에 새 APK 설치 후 메뉴, 작전 시작,
  드래그 이동, 자동 전투와 한글 HUD 확인. 런타임 오류 없음.
- macOS 및 Android 내보내기 성공. iOS x86_64 시뮬레이터용 Xcode 빌드 성공.
  이번 UI 변경 후 iOS 런타임 재실행은 하지 않았다. 이전 실행 검증은 위 기록 참고.
- 이 노트북의 Android 및 iOS 시뮬레이터 창 열기·설치·실행 절차를 README에 추가.

## 2026-09-11 — 무기 파지·전투 효과·배경 개선

- 총을 몸 중앙에서 가슴 옆 손 위치로 이동. 양손 파지, 발사 반동,
  총구 섬광과 탄피 배출을 발사 주기에 맞춰 표시한다.
- 탄환 시작점을 총구로 옮기고 표적까지의 탄도를 보정했다.
  8방향 근거리 표적 명중 회귀 테스트를 추가했다.
- 적 처치 효과를 짧은 밝은 섬광, 충격파, 흩어지는 파편과 연기로 변경했다.
  기존 효과 100개 상한을 유지하며 파편은 별도 노드 없이 그린다.
- 청회색 포장 패널, 배수구, 유도로 가장자리 표시와 헬리패드로 배경을 개선했다.
  배경 표시는 충돌 없는 장식이다.
- 전투·UI·저장·10분 작전·최대 개체 부하·실제 창 렌더링 테스트 통과.
  `build/firing-impact.png`에 발사와 처치 효과를 함께 캡처했다.
- 최신 macOS·Android 내보내기와 iOS x86_64 시뮬레이터 빌드 성공.
  이번 변경의 화면 검증은 macOS 실제 렌더링에서 수행했다.

## 2026-09-12 — 골목의 밤냥 콘셉트 전환

기존 군사 콘셉트를 말 없는 평범한 길고양이의 한국 도시 괴이 산책으로 전환했다.
`docs/cat_pixel.png`의 픽셀 가독성을 참고해 독립적인 네 발 태비 고양이를 만들었다.
현재 구현과 확장 설계는 `docs/gameplay.md` 및 `docs/cat-game-design.md`에서 구분한다.

- 고양이 앞발·이동 경로의 털·3회 연쇄 뚜껑을 서로 다른 공격으로 구현.
  진화3종, 기억3종, 음식3종, 도시 괴이8개 행동 유형과15분 첫 스테이지.
- 상자 최대2초 보호와 외부 재충전, 밥그릇 회복, 낮은 담장 충격파.
  건물 이동 충돌과 건물 내부 음식 생성 방지.
- `COMBAT_TESTS_OK`, `CAT_TEST_OK`, `UI_TEST_OK`, `FULL_RUN_TEST_OK`,
  `VISUAL_TEST_OK` 확인. 음식 효과·숨기 충전은 새로운 저장 version2에 보존.
- 15분 고정 시드 무적 수집 봇: 레벨27, 퇴치6652, 세 공격 진화.
  이 결과는 게임 난도·실제 플레이어 완주율을 의미하지 않는다.
- M2 Max 시뮬레이션 p95 약0.37ms, 500적/600위험탄 부하 p95 약1.31ms.
  렌더링·발열·실제 휴대전화 프레임 속도는 포함하지 않는 측정이다.
- Android API33 ARM64에서 새 APK 설치·실행, 한글 고양이 메뉴,
  터치 드래그 이동, 자동 앞발 퇴치, 첫 레벨업의 털/뚜껑 선택 화면 확인.
- macOS·Android 내보내기와 iOS x86_64 시뮬레이터 Xcode 빌드 성공.
  이번 콘셉트의 iOS 런타임 실플레이는 아직 재검증하지 않았다.
- Android 화면에서 발견한 안내 겹침은 근거리 환경 힌트와 웨이브 배경으로 개선.
- 설계 문서 분량 검사: 요청 순서25개 절, 무기 상세20개, 진화15개,
  패시브20개, 일반 유령20개, 엘리트10개, 보스8개, 스테이지8개,
  상호작용15개, 애니메이션20개를 확인했다. 문서 콘텐츠 전체를 구현한 것은 아니다.
- 마지막 렌더링 검사에서 원형 탄환의 filled/width 옵션 조합 경고를 수정했고,
  재캡처 로그에 경고·오류 없이 `VISUAL_TEST_OK`를 확인했다.
- 최종 APK 재설치 후 모바일 전용 이동 안내와 기존 고양이 산책의 이어하기 표시를 확인했다.

## 2026-09-12 — 말랑한 치즈냥·앙숙 테마·보스 필수 클리어

- 라벤더·살구 팔레트, 둥근 볼·반짝이는 눈·짧은 발의 치즈냥 픽셀과 아이콘.
- 생선뼈 직선 관통, 털 경로, 연쇄 장난감 공으로 공격 역할 분리.
- 강아지·까마귀·분무기·청소기를 본뜬 앙숙 괴이8종으로 외형 교체.
- 14분 보스 ‘멍멍 꿈대장’ 이름·체력바, 체력50% 이하2단계 패턴.
  15분 자동 승리를 제거하고 보스 퇴치 시에만 완료 처리.
- 전투·UI·전체 진행·부하·실제 창 렌더링 테스트 통과. 고정 시드 무적 수집 봇은
  보스를 퇴치하고 레벨22·총6370퇴치로 완료했다. 이는 실제 난도 측정이 아니다.
- 추가 회귀 검사: 생선뼈가2명만 관통, 공이3개 서로 다른 표적에 연쇄,
  15분 초과 시 미완료 유지, 초과 보스전 저장 복원, 보스 퇴치 시 승리.
- 저장 schema version3와 보스 최대 체력 복원 검사 통과.
- `build/stage-boss.png`에서2단계 보스와 HUD를 함께 확인했고 렌더링 로그에 경고·오류 없음.
- 최신 macOS·Android 내보내기 및 iOS x86_64 시뮬레이터 빌드 성공.
  이번 화면 검증은 macOS 실제 렌더링 기준이며 모바일 런타임 재실행은 하지 않았다.

## 2026-09-12 — 고양이 4종·배경 4종·공용 토큰 상점

- 작은 눈·코, 입과 흰 주둥이를 없앤 새 픽셀 얼굴. 치즈/턱시도/삼색/눈송이의
  앉기·걷기 프레임과 아이콘을 교체했다. 참고 이미지 기반 비율 관찰 후 새로 그렸다.
- 달빛/벚꽃/비 오는 네온/눈꽃 팔레트, 지붕·꽃나무·웅덩이·배경 장식 추가.
- 일반 빌드 잔액은 0부터 시작하며 현금 결제는 비활성. 디버그의 명시적
  `--shop-preview`는 독립 저장소에서 가상 구매·해금·선택을 시험한다.
- `bash scripts/test-game.sh --render`: 전투/고양이/상점/UI/전체 진행/렌더링 모두 통과.
  고정 시드 전체 진행 레벨22·6370퇴치·보스 처치. 시뮬레이션 p95 0.385ms,
  최대 풀 부하 p95 1.326ms (M2 Max의 시뮬레이션 코드 측정, 모바일 FPS가 아님).
- `python3 -m unittest server.test_ledger -v`: 5개 테스트 통과.
  동시 중복 영수증/해금, 이중 사용·음수 잔액 방지, 서버 재시작 잔액 유지,
  인증 계정 사용, 가격 위조 무시, 미검증/보류/취소/환불/타 환경 구매 거절.
  검증기는 테스트용 픽스처이며 실제 스토어 영수증을 검증한 테스트가 아니다.
- 데스크톱 실제 렌더러에서 상점3탭, 테마4종, 새 고양이4종 캡처 확인.
  `build/shop-0.png`~`shop-2.png`, `build/theme-0.png`~`theme-3.png`.
- Android ARM64 APK 내보내기, API33 에뮬레이터5582 재설치·실행 성공.
  ADB 터치로 상점 탭을 전환하고 테마/토큰 화면을 캡처했다.
  Godot 로그에 스크립트 오류 없음. `build/shop-android-themes.png`,
  `build/shop-android-tokens-after.png`에서 UI와 결제 준비 상태 확인.
- iOS Simulator 내보내기와 Xcode x86_64 빌드 성공. 내보내기에 기존
  `application/boot_splash/fullsize` 속성 경고1건이 있었지만 빌드는 완료됐다.
  iOS18.4 QA 시뮬레이터에서 설치·실행 완료, `build/shop-ios-menu.png`에
  새 고양이와 상점 진입 버튼을 확인했다. 실행 응답이 지연되어 설치 로그도 확인했다.
  iOS의 상점 내부 터치 및 실제 IAP 거래는 이번 검증에 포함하지 않는다.
- 실제 결제 플러그인/스토어 상품/인증/운영 검증기/거래 완료·환불 처리 미연결.
  [토큰 상점 문서](token-shop.md)에 활성화 전 남은 작업을 명시했다.
