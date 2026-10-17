# 꼬마 탐험 공부방

만 2~5세를 위한 Android 학습 앱입니다. 한글·영어·수학, 따라 그리기, 자유 그림과 《별빛 도서관과 사라진 이야기》 12화를 오프라인으로 이용합니다.

**최신 소스 변경 (2026-10-17):** 정답/필기 완료의 성공 소리와 안내, 유아 필기 허용 범위, 12화·120장면의 사건 연결과 Flame 별조각 수집을 개편했습니다. 모험 지도도 같은 저장 기록의 12칸을 표시하며, 도입 놀이와 본 미션의 결과를 구분합니다. [스토리 구성·범위](docs/STORY_REWORK.md) · [수집 지도](docs/screenshots/collection-1280x800.png) · [완성 책](docs/screenshots/rework-finale-tablet.png).

누적 구현과 후속을 [3efcb82](https://github.com/duafyd/kkoma_learning/commit/3efcb827924b737185df3f7ce9247143840bdcaf)로 main에 푸시하고 원격 일치를 확인했습니다. 다른 PC에서는 main을 pull해 이어서 개발할 수 있습니다.

**최신 공개 APK: [1.0.0 (214363529) 다운로드](https://github.com/duafyd/kkoma_learning/releases/download/apk-1.0.0-214363529/kkoma-1.0.0-214363529.apk)** · [Release](https://github.com/duafyd/kkoma_learning/releases/tag/apk-1.0.0-214363529). 143.4MiB, 기존 공유 키 서명이며 위 경험 재개편을 모두 포함합니다. 공개 서버 크기/SHA256·다운로드 HEAD200을 확인했습니다([공개 파일 검증](docs/published_build.json) · [배포 내역](docs/RELEASE_NOTES.md)). 일반 Git push는 소스만 올리며 APK는 사용자의 이번 추가 요청으로 공개했습니다. 이후 업로드도 별도 요청 때만 실행합니다.

최신 실제 테스트·로컬 APK·Git 반영 결과는 [PROGRESS](docs/PROGRESS.md) 상단, 다른 PC에서 재개하는 절차는 [SOURCE_HANDOFF](docs/SOURCE_HANDOFF.md)를 확인하세요. 과거 단계별 빌드와 검사 이력도 PROGRESS에 보존합니다.

배포 명령에서도 **analyze 문제0 / 전체567개 통과**, 릴리스 빌드·기존 키 v2 서명을 재확인했습니다. 새78개에는 전체 시즌72개 매개변수 조합의 저장·복원이 포함됩니다([소스 검사 요약](docs/source_validation.json)). [직전 로컬 빌드214363192](docs/collection_build.json)는 당시 기록이며 최신 공유 APK는214363529입니다. 이번 Android 재실행은 에뮬레이터 ADB 연결 실패로 미실행이며, 직전 통합5개 통과와 구분합니다. 음원 제작·실기기·교육자 승인·아동 검수는 대기입니다.

## 구현된 기능

- **연령별 학습:** 만 2~5세 Strategy, 한글·영어·수학 콘텐츠와 힌트/쉬운 길/도움 통과. 보호자 경로와 자동 단계 올림 설정.
- **듣기:** 글자 이름·대표 단어·수량을 구분해 읽기, 음량·반복·취소·생명주기 처리. 실제 등록 녹음은 **0/671개**, 현재는 기기의 오프라인 TTS 대안입니다. 캐릭터별 AI 연기 제작 자료와 시연 계획은 준비했으며 비용 사용은 보류입니다.
- **따라 그리기:** 한글50·영문52·숫자1~20의 학습122항목과 준비 운동6종. 획 시작/방향/시범/코칭·완료/재개, 손 떨림·짧은 획 허용과 탭·낙서 거절. 실제 아동의 난이도와 필순 전문가 검수는 대기입니다.
- **자유 그림:** 색·굵기·지우개·undo/redo·벡터 도장·배경·초안·PNG 저장·작품 확대. 저장 실패와 중단 제출 복구, 보호자 삭제 확인.
- **수학 놀이:** 세기/비교/패턴/분류, 구체물 더하기·빼기, 수량 선 잇기·드래그 및 탭 대안, 힌트와 저장 복원.
- **연속 이야기:** 12화·120개 기본 장면, 연령별4/6/8/10장면, 7화 그림 지도·9화 세 길·12화 두 방 선택. Flame 소품/글자 선택·돌/별 배치와 장소별 장애물·잠긴 조각·회수 이동·12칸 책을 저장 진도에 연결합니다. 기존 배경·캐릭터 합성과16포즈를 재사용하며 장편 걷기·음소 립싱크·연기 녹음을 새로 제작한 것은 아닙니다.
- **진도와 보호자:** SQLite, 홈의 미완료 필기·퀴즈 이어하기, 문항·장면 ID 복원과 과거 저장 호환, 보호자 관문·교육 내용 미리보기·사용 시간·소리/동작 설정·초기화 확인.
- **반응형 화면:** 좁은 세로/낮은 가로 폰·태블릿, 확대 글자·시스템 여백·스크롤 및 캔버스 분리 검증. 실제 Galaxy Tab/S25의 손가락·청취·성능은 최종 검증 항목입니다.

## 개발 환경과 실행

Flutter **stable 3.47.7**, Dart **3.13.5**, Android minSdk **24**, target/compileSdk **36**. Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0, NDK 28.2.13676358, JDK 25.0.3. 설치 시 `pubspec.lock`을 유지합니다.

```powershell
flutter pub get
powershell -ExecutionPolicy Bypass -File tool/verify-source.ps1 # 전체 소스 전달 검사
powershell -ExecutionPolicy Bypass -File tool/test.ps1
dart run tool/audit_content.dart
dart run tool/export_voice_scripts.dart
dart run tool/export_story_studio.dart
dart run tool/generate_ai_auditions.dart # 무료 계획만 생성, API 호출 없음
dart run tool/prepare_recordings.dart
dart run tool/prepare_recordings.dart --check
powershell -ExecutionPolicy Bypass -File tool/android.ps1 build apk --release
```

`tool/test.ps1`은 한글 사용자 TEMP 경로에서 flutter_tester가 종료되는 Windows 문제를 피합니다. `tool/android.ps1`은 원래 SDK를 이동하지 않고 `.tool_tmp/android-sdk` Junction을 사용해 JNI/CMake의 한글 경로 문제를 피합니다. 원본 SDK는 `%LOCALAPPDATA%/Android/Sdk`에서 찾습니다. Kotlin incremental 캐시는 C: 패키지 캐시와 D: 프로젝트의 드라이브 차이 때문에 비활성화했습니다.

새 화면 캡처는 `POLISH_CAPTURE=true`, 경로 검토 자료는 `REVIEW_EXPORT=true`로 해당 테스트를 실행합니다. [교육 검토 자료 재생성](docs/review/README.md)과 PROGRESS의 검사 명령을 참고하세요. 격리 Android 태블릿 에뮬레이터(API35) 통합 검사는 PROGRESS 상단의 실제 실행 결과를 따릅니다. 고유한 테스트 DB로 저장/이동/필기 완료/DB 재개를 검사하며 실제 아이 진도를 사용하지 않습니다. 실행 중인 대상 ID를 확인한 다음 `tool/android.ps1 test integration_test/app_flow_test.dart --device-id=<에뮬레이터ID> --timeout=120s`로 실행합니다. PowerShell에서는 옵션의 값에 `=`를 사용합니다.

## APK와 설치

2026-10-15 사용자 승인으로 기존 서명 보류를 해제하고 **APK 직접 공유용 전용 키**를 생성했습니다. 릴리스 빌드는 로컬 `android/key.properties`를 읽어 자동 서명합니다. Play Store 업로드는 하지 않습니다.

최신 테스트·로컬 APK·기존 배포 APK는 PROGRESS의 해당 기록을 확인하세요. **Git 푸시와 APK 업로드는 사용자가 명시적으로 요청했을 때만 수행합니다.** 로컬 빌드와 GitHub 배포를 구분합니다. 서명 설정은 [Flutter 공식 서명 안내](https://docs.flutter.dev/deployment/android#sign-the-app)를 따릅니다. Flutter test와 APK build는 생성 파일 충돌을 피하도록 순차 실행하세요.

최신 APK와 검증 결과는 이 문서 상단 및 `docs/published_build.json`을 따릅니다. 예전 빌드·테스트 결과는 PROGRESS에 보존합니다. 기존 앱을 먼저 삭제하지 말고 같은 공유 서명의 APK를 업데이트 설치합니다. 실제 기기 업데이트·소리·프레임·메모리 검증은 대기입니다. 현재671개 고정 대본의 등록 녹음은0개이며 오프라인 기기 TTS를 사용합니다. 배경음악도 미제작입니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/android.ps1 build apk --release
```

공유 파일: `build/app/outputs/flutter-apk/app-release.apk`. 수신 기기에서 APK를 여는 앱의 '알 수 없는 앱 설치' 권한을 허용하고 설치합니다. 실제 기기 설치 결과는 별도 검증 대상입니다.

**백업할 비공개 파일 두 개:** `android/release-signing/kkoma-sharing.p12`, `android/key.properties`. 두 파일은 Git에서 제외되며 비밀번호는 채팅·문서·로그에 출력하지 않습니다. USB나 본인의 안전한 저장소에 별도 백업하세요. 자동으로 외부 백업하거나 전송하지 않았습니다. APK만 공유하고 키/비밀번호는 공유하지 마세요.

다른 PC에서는 소스를 clone한 다음 두 비공개 파일을 같은 위치로 복원해야 릴리스 빌드할 수 있습니다. 키가 없으면 새 키를 생성하지 말고 원본 백업을 복원하세요. 키 생성 스크립트 `tool/create-sharing-key.ps1`는 기존 파일을 덮어쓰지 않습니다. 예전 `tool/sign-debug.ps1`은 공유 빌드에 사용하지 않습니다.

업데이트는 같은 applicationId와 같은 서명 키를 유지하고 `pubspec.yaml`의 빌드 번호를 올려 배포합니다. 현재 앱 ID는 `com.example.flutter_application_1`이며 그대로 유지했습니다. 별도 태블릿 에뮬레이터에서 Android 저장/이동/필기/DB 재개를 검사했으며 실제 Galaxy Tab 설치·성능 검증은 미완료입니다. 절차는 [docs/DEVICE_VALIDATION.md](docs/DEVICE_VALIDATION.md)를 참고하세요.

## APK를 GitHub Releases에 올리기

변경 소스를 먼저 커밋한 뒤 프로젝트 루트에서 실행합니다:

```powershell
powershell -ExecutionPolicy Bypass -File tool/publish-apk.ps1
```

명령 하나로 전체 소스 검사(analyze/test·생성 자료·콘텐츠 감사·비공개 파일 제외) → 서명 APK 빌드 → 서명 검증 → main push → Releases APK 업로드를 순서대로 실행합니다. Git Credential Manager의 기존 GitHub 로그인을 사용하며 GitHub Secrets에 서명 키를 등록하지 않습니다. 일반 `git push`만 실행하면 APK는 올라가지 않습니다.

빌드 번호는 2020년 이후 경과 초로 자동 증가하며, APK 태그는 `apk-버전-빌드번호`입니다. APK의 versionCode만 빌드 인수로 변경하고 pubspec은 수정하지 않습니다. 과거 릴리스보다 낮은 번호·중복 태그·미커밋 변경·다른 브랜치에서는 중단합니다. 업로드는 draft로 준비하고 크기/서버 해시 확인 후 공개합니다. 실패 시 draft가 남을 수 있으며 기존 릴리스·파일은 덮어쓰거나 삭제하지 않습니다. 100개를 넘긴 릴리스 이력은 최신 100개 기준으로 검사합니다.

키와 key.properties는 PC에만 있고 APK만 업로드됩니다. 다른 PC에서는 원본 키 두 파일을 별도 복원해야 합니다. 구현 API는 [GitHub Releases 공식 문서](https://docs.github.com/en/rest/releases/releases)를 따릅니다.

## 구조와 저장

- `lib/app`: go_router, Material 테마, 앱 생명주기.
- `lib/core`: SQLite 저장소, 오디오 서비스, 공통 화면.
- `lib/features`: profile/parent/learning/math/tracing/drawing/story/progress/home.
- View는 사용자 입력만 전달하고, Riverpod Notifier/AsyncNotifier ViewModel이 Repository 및 정책을 조율합니다.
- `AgeStrategy`, `TraceStrategy`, `StoryMachine`은 별도 판정/전이 규칙입니다.
- 학습 항목·문제·장면은 `learning/data/learning_content.dart`, `story/data/story_content.dart`의 별도 Dart 데이터입니다. 추가 필기 경로는 `tracing/data/additional_paths.dart`에 있으며 기존 13개 경로는 유지합니다.
- `kkoma.db`의 documents 테이블에 설정/진도/세션/스토리/그림 초안/작품 메타데이터를 저장합니다. 진도 쓰기는 직렬화합니다. 작품 PNG는 앱 내부 artworks 디렉터리에 저장합니다.
- 손가락 이동 버퍼는 캔버스 안에서 관리하고, 획 종료 시에만 ViewModel을 갱신합니다. 작품 PNG 생성은 화면 캡처가 아닌 동일 렌더러를 사용합니다.
- 계정·서버·광고·결제·분석 SDK·위치·마이크 권한·외부 전송이 없습니다. Android 자동 백업을 끄고 음성은 네트워크를 요구하지 않는 TTS 음성만 선택합니다.

## 자동 테스트와 제한

테스트는 필기 방향/부분/터치/떨림, 4연령×12화 완주, 힌트/도움/분기/저장 복구, 빠른 중복 입력, 설정 동시 쓰기, 하루 사용 시간, PNG 동시 저장/다시 열기/삭제 및 실패 롤백, 중단된 삭제/제출 복구, 녹음 우선/실패 TTS 대체/반복/취소/생명주기, 음성 중복/무음/누락/시간 초과, 태블릿 3크기 전체 화면을 검증합니다. 최신 실제 실행 결과와 각 로컬 로그 경로는 PROGRESS 상단을 확인하세요. 오디오는 호스트의 채널 mock 테스트이며 Android 기기 재생 검증과 구분합니다.

2026-10-15 필기 확장 검증 기록은 `docs/tracing-expansion-test.log`에 있습니다. 모든 경로의 4연령 정상 입력, 원형/교차 획의 역방향·부분 입력, 두 자리 숫자 순서·중단 후 복원, 연령별 다음 글자 선택을 검증합니다. 경로 검토 이미지 재생성: `flutter test tool/tracing_preview_test.dart` (Windows에서는 먼저 TEMP/TMP를 `.tool_tmp`로 설정).

명세 대비 구현 범위와 누락 사항은 [docs/REQUIREMENTS_STATUS.md](docs/REQUIREMENTS_STATUS.md)에 정리했습니다.

`dart run tool/audit_content.dart`는 콘텐츠 참조·배경·캐릭터·이야기 효과음 리소스를 검사하고 `docs/content_audit.json`을 생성합니다. `--require-recordings`를 추가하면 녹음이 누락될 때 실패합니다. 현재 고정 대본 **671개에 대한 등록 음원은 0개**이며 배경음악도 미제작입니다. 대본은 `export_voice_scripts.dart`, 스토리 연기 지침은 `export_story_studio.dart`로 재생성합니다. `generate_ai_auditions.dart`의 기본 실행은 계획만 만들며 API를 호출하지 않습니다. 유료 생성은 계속 보류합니다. 이야기 효과음 3개는 `dart run tool/generate_story_sounds.dart`로 재현할 수 있는 자체 합성 소리이며 녹음 대사가 아닙니다. 시스템 이모지와 TTS 발음은 기기마다 다를 수 있습니다.

다른 PC로 소스를 옮겨 개발하거나 Git에 올리기 전에는 `tool/verify-source.ps1`을 실행합니다. 비공개 파일 경로, analyze/전체 테스트, 생성 자료 일치와 콘텐츠 감사를 묶어 검사하며 자동 푸시나 APK 업로드는 하지 않습니다. [소스 전달·보류 항목·다음 검수](docs/SOURCE_HANDOFF.md)를 참고하세요.

실제 Galaxy Tab의 필기·음성·프레임/메모리·재부팅/업데이트, 아동 사용성과 교육 전문가의 문항/필순/발음 검수는 미완료입니다. 공유용 서명은 연결되어 있으며 기존 앱 업데이트를 위해 앱 ID `com.example.flutter_application_1`과 원본 키를 유지합니다.

패키지 API는 공식 [Riverpod](https://pub.dev/packages/flutter_riverpod), [go_router](https://pub.dev/packages/go_router), [sqflite](https://pub.dev/packages/sqflite), [path_provider](https://pub.dev/packages/path_provider), [flutter_tts](https://pub.dev/packages/flutter_tts) 문서와 설치된 소스를 확인했습니다. 불필요한 템플릿 cupertino_icons는 제거했습니다.
