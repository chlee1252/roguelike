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

## 2026-09-12 — 세 지역 캠페인·8무기·쉼터 성장

- 3개 실제 지역과 전용 보스, 일반/도전 난도, 8무기 중4종·12패시브 중4종 선택,
  6진화, 생활 아이템4종, 환경 단서3개, 후일담, 쉼터 가구/무기 해금/시작 버릇을 구현.
- `bash scripts/test-game.sh --render`: 전투·고양이·외형 상점·캠페인·UI·전체 진행·부하·렌더링 통과.
  추가 검사로 하악질 가장자리 피해/공포/밀기, 이동 없는 미끼 차단, 벽 반사 예산,
  매복 충전 후1회 발동, 방울 당김/주기 피해, 슬롯 제한, 진화6종,
  이동/획득/회복/방어/멈춤 패시브, 보스 패턴 차이, 단서 발견을 확인했다.
- version3 저장 이관, version4 시계/미끼/단서 복원, 잘못된 미끼 데이터 거절,
  충돌 도형 밖 경험치 생성, 중복 결과 정산 방지, 미정산 저널 복구,
  쉼터 구매 저장 실패 롤백, 실제 시작 버릇 교체 검사를 통과했다.
- 무적 수집 봇으로 각 지역의 일반/도전 전체 흐름을 검사했다. 최종 웨이브 사양 기준:

| 지역 | 일반 완료(초) | 도전 완료(초) |
|---|---:|---:|
| 해솔빌라 | 568.1 | 575.6 |
| 어린이공원 | 688.7 | 695.3 |
| 별빛시장 | 808.2 | 837.4 |

- 여섯 경우 모두 보스 이벤트·처치·진화·최소 성장·풀 상한 및 중간 저장의 동일 재현 검사를 통과했다.
  무적 봇의 결과이며 인간 승률, 실제 플레이 난도나 재미를 측정한 것이 아니다.
  일부 실행은 병렬이므로 해당 벤치마크 시간은 실기기 성능 근거로 사용하지 않는다.
- 실제 macOS 렌더러로 지역 선택·쉼터3탭·업그레이드·지역3개·후일담3개를 캡처.
  이야기 줄바꿈, 카드 문구 폭, 아이템 아이콘, 보호 중에도 보이는 고양이를 확인했다.
  `build/stage-selection.png`, `shelter-0.png`~`shelter-2.png`, `region-0.png`~`region-2.png`, `story-0.png`~`story-2.png`.
- Android ARM64 APK 내보내기 및 API33 에뮬레이터5582 설치/실행 성공.
  ADB 터치로 지역 선택→메뉴→쉼터→시작 버릇 ‘하악질’ 선택→새 산책→이동→일시정지를 확인했다.
  `build/campaign-android-hiss.png`에서 하악질1/6, 체력100, 자동 퇴치1회를 확인.
- Android 쉼터에서 돌아가기 버튼이 클릭 가능하지만 가려지는 현상을 발견했다.
  공통 페이지의 돌아가기 버튼을 상위 표시 순서로 올린 뒤 재설치하여
  `build/campaign-android-back-fix.png`에서 정상 표시를 확인했다. 캠페인 테스트도 재통과했다.
  첫 재설치 시 ADB 연결이 끊어졌지만 재시도 설치/실행은 성공했다.
- iOS Simulator 내보내기와 Xcode x86_64 빌드 성공. iOS18.4 QA 기기에 설치/실행하여
  `build/campaign-ios-menu.png`에서 새 ‘쉼터’와 ‘산책길 고르기’를 확인했다.
  기존 `application/boot_splash/fullsize` 내보내기 경고는 남아 있으며 빌드는 성공했다.
  iOS 내부 상점/쉼터 터치 및 실기기 발열·배터리·최저사양 성능은 검사하지 않았다.
- 이번 작업은 플레이테스트 가능한 콘텐츠 확장이다. 실제 이용자 테스트와 실제 IAP 연동/검증은
  아직 남아 있다. [진행표](playtest-guide.md)와 [구현 사양](night-campaign.md)에 구분했다.

## 2026-09-12 — 문구, 고양이 기본 무기, 전투 피드백과 음악

- 제목/버튼을 Jua로 바꾸고 작은 본문은 Pretendard로 유지했다. 메뉴·상점·무기 도감·레벨 업·설정 화면을 실제 렌더링으로 확인했다. 고양이 4종의 서로 다른 시작 무기는 UI 테스트에서 각각 새 게임으로 검증했다. 기존 전역 시작 무기 값이 고양이 기본 무기를 덮지 않는 것도 검사한다.
- `bash scripts/test-game.sh --render`: COMBAT, CAT, SHOP, ADVENTURE, UI, FEEDBACK, AUDIO_MIX, FULL_RUN, VISUAL 모두 통과. 최종 실행에 스크립트 오류·종료 시 누수 경고 없음.
- 전체 진행 봇: 3,133 처치, 레벨 19. 시뮬레이션 p95 0.417ms. 500적/600적탄 부하 p95 1.692ms. 데스크톱에서 Android 에뮬레이터도 켠 상태의 시뮬레이션 수치이며 모바일 FPS나 인간 난도 검증은 아니다.
- `audio_mix_test.gd`: 헤드리스 믹서와 macOS 실제 오디오 드라이버에서 3개 음악의 끝부분을 재생해 반복 경계를 넘는지 확인했다. 실제 드라이버 캡처 peak는 메뉴 0.0844, 전투 0.1084, 보스 0.1406으로 무음·클리핑이 없었다. 정지 후 버스 출력도 무음이다. 일반 헤드리스 UI 테스트는 재생 없이 상태만 검사하고, 믹서 테스트에서만 출력을 명시적으로 켠다.
- Android API 33 ARM64 에뮬레이터에 APK를 설치했다. 처음에는 WAV 반복 끝을 샘플 수로 지정해 음악 한 주기 후 AudioTrack에서 SIGSEGV가 발생했다. 반복 끝을 마지막 유효 인덱스(샘플 수 − 1)로 고쳤다. 수정 APK에서 메뉴 음악이 여러 번 반복되어도 프로세스가 유지되고 오류 로그가 비어 있음을 확인했다.
- Android에서 설정 진입, 배경음악/효과음 각각 끄기, 홈 이동과 앱 복귀, 설정 유지, 다시 켜기를 확인했다. 화면 캡처: `build/polish-android-menu.png`, `build/polish-android-settings.png`, `build/polish-android-mute.png`. `build/evolution-impact.png`는 연출 검사용 배치 화면이며 실제 진화 플레이 기록은 아니다.
- 이번 변경으로 iOS를 다시 실행하지는 않았다. 음악 취향·장시간 청취 피로도·실제 휴대폰 스피커 밸런스와 고양이별 인간 플레이 난도는 별도 확인이 필요하다. Suno 생성곡은 사용하지 않았다.

## 2026-09-12 — 실기기 햅틱 연결

- 피격·레벨 업 선택·진화·승리의 진동을 `CombatHaptics`에 연결했다. 짧은 단발 진동, 250ms 최소 간격, 상위 이벤트 우선 처리, 백그라운드 요청 폐기를 검사했다. 효과음 음소거와 독립적으로 동작하며 햅틱 설정 저장/재로드 테스트도 통과했다.
- `bash scripts/test-game.sh --render`: 기존 전체 검사와 `HAPTICS_TEST_OK`, 실제 설정 화면 캡처까지 통과했다. 새 설정 화면은 5개 항목과 실기기 테스트 버튼을 표시한다.
- Android APK 내보내기 성공. `aapt dump permissions build/LastCommando.apk`에서 `android.permission.VIBRATE` 포함을 확인했다.
- 연결 가능한 휴대폰이 없어 실제 햅틱 감촉은 확인하지 못했다. 시뮬레이터를 통한 물리 진동 검증으로 대체하지 않았다. 실기기 테스트 절차는 [햅틱 안내](haptics.md)에 정리했다.

## 2026-09-12 — 고양이 산책 / CatWalk 이름 변경과 iPhone 연결

- 표시 이름을 ‘고양이 산책’, 프로젝트·실행 파일·빌드 산출물을 `CatWalk`, 앱 식별자를 `com.marc.catwalk`로 변경했다. 앱 장면과 환경 확인 화면, 현재 README·기획 문서도 갱신했다. 과거 검증 기록의 이전 이름은 기록 그대로 보존한다.
- `bash scripts/test-game.sh --render` 전체 통과. 환경 확인 장면도 `ENVIRONMENT_SMOKE_OK`. 메뉴 이미지의 새 제목을 확인했다.
- Android `build/CatWalk.apk` 내보내기 성공. aapt에서 패키지 `com.marc.catwalk`와 표시 이름 ‘고양이 산책’을 확인했다.
- 실기기 전용 `iOS Device` 프리셋을 추가했다. `build/ios-device/CatWalk.xcodeproj`를 iPhoneOS ARM64 대상으로 서명 없이 컴파일하여 `BUILD SUCCEEDED`를 확인했다. 생성 앱의 CFBundleDisplayName과 CFBundleIdentifier도 새 값이다. 이는 설치 가능한 서명 앱의 검증과는 다르다.
- USB로 연결된 iPhone 17 Pro(iOS 26.6.2)를 페어링했다. 확인 시 개발자 모드는 꺼져 있었다. 자동 서명 시 Apple이 `PLA Update available` 오류로 최신 개발자 계정 약관 동의를 요구해 새 앱 프로비저닝 프로파일을 발급받지 못했다. 기기 설정과 계정 약관 동의는 사용자에게 요청한 상태이며 이 기록 시점에는 설치·실행을 완료하지 못했다.
- `scripts/install-iphone.sh <UDID> <TEAM_ID>`로 최신 내보내기·기기별 서명·설치·실행을 반복할 수 있다. 셸 구문 검사를 통과했다. 실제 서명/설치 전체 경로는 위 외부 조건 해소 후 검증해야 한다. 개인 계정 정보나 인증서는 저장소에 추가하지 않았다.

## 2026-09-12 — 표시 제목 복원

사용자 요청으로 표시 제목을 다시 **골목의 밤냥**으로 변경했다. 프로젝트·빌드 파일명 `CatWalk`과 앱 식별자 `com.marc.catwalk`는 유지한다. 실제 메뉴 렌더링 `VISUAL_TEST_OK`, Android APK의 표시 이름, iOS 실기기용 Xcode 프로젝트의 표시 이름을 확인했다. iPhone 서명·설치에 필요한 외부 조건은 이전 기록과 동일하며 이번 제목 변경으로 설치 완료를 의미하지 않는다.

## 2026-09-12 — 약관 동의 후 iPhone 재시도

사용자가 Apple 약관 동의를 완료한 뒤 자동 서명을 다시 시도했다. `generic/platform=iOS` 대상으로 개발용 서명 빌드가 성공했고 `codesign --verify --deep --strict`도 통과했다. 이전 `PLA Update available` 오류는 재발하지 않았다. 앱 표시 이름은 ‘골목의 밤냥’, 식별자는 `com.marc.catwalk`다.

연결된 iPhone 17 Pro는 여전히 개발자 모드가 꺼져 있어 기기 지정 빌드가 `Developer Mode disabled`로 중단됐다. 생성 프로파일을 검사한 결과 이 iPhone의 UDID는 아직 포함되지 않았다. 따라서 현재 앱을 이 기기에 설치·실행했다고 볼 수 없다. 사용자가 개발자 모드를 켠 뒤 `scripts/install-iphone.sh`의 기기 지정 빌드(`-allowProvisioningDeviceRegistration`)로 등록·서명을 갱신하고 설치를 이어가야 한다.

## 2026-09-12 — iPhone 설치·실행 성공 및 구매 문구 정리

- iPhone 17 Pro(iOS 26.6.2)의 개발자 모드 활성화와 DDI 연결을 확인했다. 기기 지정 자동 서명 빌드가 성공했고, 생성된 프로파일에 연결한 iPhone이 포함되는 것을 검사했다.
- `scripts/install-iphone.sh`의 빌드·서명·설치·실행 전체 경로가 성공했다. 기기의 설치 앱 목록에 ‘골목의 밤냥’/`com.marc.catwalk`가 나타났으며 실행 프로세스가 유지되는 것을 확인했다. 이전 약관/개발자 모드로 인한 설치 차단은 해소됐다.
- Xcode의 실기기 스크린샷으로 상점의 고양이 4종과 버튼·텍스트 표시를 확인했다(`build/iphone-first-launch.png`). 스크린샷은 이전 문구가 보이는 수정 전 화면이다. 모터 진동의 촉감이나 장시간 플레이 난도까지 검증했다는 의미는 아니다.
- 사용자 요청에 따라 게임 화면의 ‘해금’을 없앴다. 토큰 상점과 쉼터 물건은 ‘구매’, 무기는 ‘사용 가능’, 어려움 난도는 ‘보스 처치 후 열림’으로 구분했다. 결과 보상 안내와 현재 사용 문서도 수정했다. `game/`, `ui/`에 해당 표현이 남지 않은 것을 검색으로 확인했다.
- 문구 변경 후 `VISUAL_TEST_OK`, 상점·쉼터 화면 검사를 통과했다. 수정한 최신 코드로 기기 지정 빌드·재설치·실행을 다시 성공했다(`build/iphone-copy-install.log`).
