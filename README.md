# 꼬마 탐험 공부방

만 2~5세를 위한 Android 태블릿 학습 앱입니다. 공식 요구사항은 [docs/kkoma_spec.md](docs/kkoma_spec.md), 실제 구현·검증·재개 기록은 [docs/PROGRESS.md](docs/PROGRESS.md)에 있습니다. 기능 코드와 자동 테스트를 구현했으며, 녹음 음원·교육 전문가 검수·실제 태블릿 검증까지 모두 끝난 출시 제품으로 보고하지 않습니다.

## 구현된 기능

- 만 나이 2~5세와 별도 학습 경로 설정. 나이를 바꾸면 기본 학습 경로도 바뀝니다. 퀴즈 성공이 이어지면 한 단계씩 조정하고, 반복 시도에는 힌트·다른 길·도움 통과를 제공합니다.
- 한글 자음·모음·쉬운 음절/낱말, A~Z와 대소문자, 1~20 숫자: 75항목. 세기·비교·분류·패턴·조합·기초 더하기/빼기 등 19퀴즈.
- Android 오프라인 TTS 읽기. 알파벳 이름과 대표 단어, 자음 이름과 예시를 구분해 읽습니다. 기기에 해당 언어의 오프라인 음성이 없으면 글과 그림으로 계속 진행합니다.
- 음성 재생 실패 시 안내를 표시하고 보호자 영역에서 최근 상태를 확인할 수 있습니다. 음성 실패·무음은 듣기 시도로만 기록하며 실제 재생 성공만 듣기 완료로 기록합니다. 취소된 이전 재생은 완료로 기록하지 않습니다.
- 따라 그리기: 시작점·화살표·현재 획·시범·재시도, 연령별 판정. 시작·방향·경로 거리·완료도 평가와 손 떨림 허용. 완료 획을 저장해 앱 재시작 후 복원합니다.
- 자유 그림: 6색, 굵기, 지우개, undo/redo, 전체 지우기 확인, 4~5세 도장/배경. 초안 자동 보관, PNG 저장/다시 그리기, 보호자 확인 후 작품 삭제.
- 《별빛 도서관과 사라진 이야기》 시즌 1의 12화: 120개 기본 장면, 경로별 4/6/8/10장면. 대사·선택·퀴즈·필기·그림·보상, 9화 세 갈래 복습과 12화 결말. 장면/선택/시도/도움/필기를 저장해 이어합니다.
- 사과를 바구니로 드래그하거나 눌러 모으기, 연령별 3/5/10/20개, 4~5세 하나 더/하나 덜 조작.
- 보호자 산술 관문, 자동 읽기/반복/음량/반응/애니메이션, 하루 사용 시간, 진도 초기화/작품 삭제/앱 종료 확인. 장면 마무리 후 쉬는 화면.
- 가로/세로 화면, 큰 터치 영역, 벡터 그림책 배경과 모아·루루·토토·휙휙, 자체 벡터 앱 아이콘.

현재 따라 그리기를 지원하는 글자는 **ㄱ ㄴ ㅁ ㅏ ㅓ ㅗ ㅜ / A B C / 1 2 3**입니다. 나머지는 듣기/보기로 제공하며, 준비되지 않은 필기 버튼은 표시하지 않습니다. 지원 획도 교육 전문가 검수는 별도로 남아 있습니다.

## 개발 환경과 실행

Flutter **stable 3.47.7**, Dart **3.13.5**, Android minSdk **24**, target/compileSdk **36**. Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0, NDK 28.2.13676358, JDK 25.0.3. 설치 시 `pubspec.lock`을 유지합니다.

```powershell
flutter pub get
powershell -ExecutionPolicy Bypass -File tool/test.ps1
dart run tool/audit_content.dart
powershell -ExecutionPolicy Bypass -File tool/android.ps1 build apk --release
```

`tool/test.ps1`은 한글 사용자 TEMP 경로에서 flutter_tester가 종료되는 Windows 문제를 피합니다. `tool/android.ps1`은 원래 SDK를 이동하지 않고 `.tool_tmp/android-sdk` Junction을 사용해 JNI/CMake의 한글 경로 문제를 피합니다. 원본 SDK는 `%LOCALAPPDATA%/Android/Sdk`에서 찾습니다. Kotlin incremental 캐시는 C: 패키지 캐시와 D: 프로젝트의 드라이브 차이 때문에 비활성화했습니다.

## APK와 설치

APK 경로: `build/app/outputs/flutter-apk/app-release.apk`.

현재 릴리스 빌드는 **서명 없음**으로 설정되어 있습니다. 사용자가 **서명 없이 유지**하기로 결정했으므로 키 생성·서명을 실행하지 않습니다. 컴파일된 APK가 있어도 서명 전에는 Android에 설치할 수 없습니다. 아래 서명 명령은 향후 사용자가 결정을 변경할 경우에만 적용합니다.

검증용 키 생성이 명시적으로 승인된 뒤에만 다음 명령을 실행하세요. 이 키는 공개된 기본 암호를 쓰는 개발 검증용이며 정식 배포에 사용하면 안 됩니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/sign-debug.ps1 -CreateDevelopmentKey
# 이후에는 키를 재사용
powershell -ExecutionPolicy Bypass -File tool/sign-debug.ps1
adb install -r build/app/outputs/flutter-apk/app-validation.apk
```

키는 `android/validation-signing/`에 보관하고 Git에서 제외합니다. 기존 설치와 키가 다르면 업데이트가 거부될 수 있습니다. 앱 삭제는 로컬 작품/진도를 잃게 하므로 임의로 삭제하지 않습니다.

디버그 실행도 기본 Android debug 키를 생성할 수 있으므로 키 생성 승인 후 실행하세요.

```powershell
flutter emulators --launch Pixel_Tablet
powershell -ExecutionPolicy Bypass -File tool/android.ps1 devices
powershell -ExecutionPolicy Bypass -File tool/android.ps1 run -d emulator-5554
powershell -ExecutionPolicy Bypass -File tool/android.ps1 test integration_test/app_flow_test.dart -d emulator-5554
```

현재 AVD는 offline이며 실제 Android 실행·통합 테스트를 통과했다고 주장하지 않습니다. 실기기 검증 절차는 [docs/DEVICE_VALIDATION.md](docs/DEVICE_VALIDATION.md)에 있습니다. 통합 테스트는 실제 학습 데이터를 건드리지 않는 별도 SQLite DB를 사용합니다.

## 구조와 저장

- `lib/app`: go_router, Material 테마, 앱 생명주기.
- `lib/core`: SQLite 저장소, 오디오 서비스, 공통 화면.
- `lib/features`: profile/parent/learning/math/tracing/drawing/story/progress/home.
- View는 사용자 입력만 전달하고, Riverpod Notifier/AsyncNotifier ViewModel이 Repository 및 정책을 조율합니다.
- `AgeStrategy`, `TraceStrategy`, `StoryMachine`은 별도 판정/전이 규칙입니다.
- 학습 항목·획·문제·장면은 `learning/data/learning_content.dart`, `story/data/story_content.dart`의 별도 Dart 데이터입니다.
- `kkoma.db`의 documents 테이블에 설정/진도/세션/스토리/그림 초안/작품 메타데이터를 저장합니다. 진도 쓰기는 직렬화합니다. 작품 PNG는 앱 내부 artworks 디렉터리에 저장합니다.
- 손가락 이동 버퍼는 캔버스 안에서 관리하고, 획 종료 시에만 ViewModel을 갱신합니다. 작품 PNG 생성은 화면 캡처가 아닌 동일 렌더러를 사용합니다.
- 계정·서버·광고·결제·분석 SDK·위치·마이크 권한·외부 전송이 없습니다. Android 자동 백업을 끄고 음성은 네트워크를 요구하지 않는 TTS 음성만 선택합니다.

## 자동 테스트와 제한

테스트는 필기 방향/부분/터치/떨림, 4연령×12화 완주, 힌트/도움/분기/저장 복구, 빠른 중복 입력, 설정 동시 쓰기, 하루 사용 시간, PNG 동시 저장/다시 열기/삭제 및 실패 롤백, 중단된 삭제 복구, 음성 중복/무음/누락/시간 초과, 태블릿 3크기 전체 화면을 검증합니다. 최신 실제 실행 결과는 PROGRESS와 `docs/followup-test.log`를 확인하세요. 오디오는 호스트의 채널 mock 테스트이며 Android 기기 재생 검증과 구분합니다.

2026-10-15 후속 검증: `flutter analyze` 오류/경고 없음, 테스트 **56개 통과**. 저장 지연 중 백그라운드 전환·초기 로딩 중 일시 중지·시간 저장 실패 후 재시도도 포함합니다.

명세 대비 구현 범위와 누락 사항은 [docs/REQUIREMENTS_STATUS.md](docs/REQUIREMENTS_STATUS.md)에 정리했습니다.

`dart run tool/audit_content.dart`는 콘텐츠 참조와 리소스를 검사하고 `docs/content_audit.json`을 생성합니다. `--require-recordings`를 추가하면 녹음이 누락될 때 실패합니다. 현재 사전 녹음 214파일, 효과음, 배경음악은 제작하지 않았습니다. 효과 설정은 현재 진동 켜기/끄기이며 음량 조절 가능한 효과음으로 보고하지 않습니다. 시스템 이모지와 TTS 발음은 기기마다 다를 수 있습니다.

실제 Galaxy Tab의 필기·음성·프레임/메모리·재부팅/업데이트, 아동 사용성, 교육 전문가의 문항/필순/발음 검수, 정식 앱 ID/서명은 미완료입니다. 앱 ID는 `com.example.flutter_application_1`을 유지했습니다.

패키지 API는 공식 [Riverpod](https://pub.dev/packages/flutter_riverpod), [go_router](https://pub.dev/packages/go_router), [sqflite](https://pub.dev/packages/sqflite), [path_provider](https://pub.dev/packages/path_provider), [flutter_tts](https://pub.dev/packages/flutter_tts) 문서와 설치된 소스를 확인했습니다. 불필요한 템플릿 cupertino_icons는 제거했습니다.
