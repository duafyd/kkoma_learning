# 꼬마 탐험 공부방

만 2~5세를 위한 Android 태블릿 학습 앱입니다. 공식 요구사항은 [docs/kkoma_spec.md](docs/kkoma_spec.md), 실제 구현·검증·재개 기록은 [docs/PROGRESS.md](docs/PROGRESS.md)에 있습니다. 기능 코드와 자동 테스트를 구현했으며, 녹음 음원·교육 전문가 검수·실제 태블릿 검증까지 모두 끝난 출시 제품으로 보고하지 않습니다.

## 구현된 기능

- 만 나이 2~5세와 별도 학습 경로 설정. 나이를 바꾸면 기본 학습 경로도 바뀝니다. 퀴즈 성공이 이어지면 한 단계씩 조정하고, 반복 시도에는 힌트·다른 길·도움 통과를 제공합니다.
- 한글 자음·모음·쉬운 음절/낱말, A~Z·a~z, 1~20 숫자: 101항목. 소문자는 학습 단계 4 이상에서 제공. 세기·비교·분류·패턴·조합·기초 더하기/빼기 등 19퀴즈.
- Android 오프라인 TTS 읽기. 알파벳 이름과 대표 단어, 자음 이름과 예시를 구분해 읽습니다. 기기에 해당 언어의 오프라인 음성이 없으면 글과 그림으로 계속 진행합니다.
- 음성 재생 실패 시 안내를 표시하고 보호자 영역에서 최근 상태를 확인할 수 있습니다. 음성 실패·무음은 듣기 시도로만 기록하며 실제 재생 성공만 듣기 완료로 기록합니다. 취소된 이전 재생은 완료로 기록하지 않습니다.
- 따라 그리기: 시작점·화살표·현재 획·시범·재시도, 연령별 판정. 시작·방향·경로 거리·완료도 평가와 손 떨림 허용. 완료 획을 저장해 앱 재시작 후 복원합니다.
- 자유 그림: 6색, 굵기, 지우개, undo/redo, 전체 지우기 확인, 4~5세 도장/배경. 초안 자동 보관, PNG 저장/다시 그리기, 보호자 확인 후 작품 삭제.
- 《별빛 도서관과 사라진 이야기》 시즌 1의 12화: 120개 기본 장면, 경로별 4/6/8/10장면. 대사·선택·퀴즈·필기·그림·보상, 9화 세 갈래 복습과 12화 결말. 장면/선택/시도/도움/필기를 저장해 이어합니다.
- 사과를 바구니로 드래그하거나 눌러 모으기, 연령별 3/5/10/20개, 4~5세 하나 더/하나 덜 조작.
- 보호자 산술 관문, 자동 읽기/반복/음량/반응/애니메이션, 하루 사용 시간, 진도 초기화/작품 삭제/앱 종료 확인. 장면 마무리 후 쉬는 화면.
- 가로/세로 화면, 큰 터치 영역, 벡터 그림책 배경과 모아·루루·토토·휙휙, 자체 벡터 앱 아이콘.
- 휴대폰 반응형: 좁은 화면 학습 카드 1열과 상단 작업 버튼 별도 줄, 낮은 가로 화면은 캔버스/도구 좌우 배치. 도구 영역만 스크롤해 필기·그림 터치와 분리. 보호자 확인은 키보드가 떠도 스크롤 가능. 홈 카드는 글자 확대에 따라 높이가 늘어납니다.

따라 그리기는 **99항목**입니다: 한글 기본 자음 14개·모음 10개와 가/나/모(27), 영어 A~Z·a~z(52), 숫자 1~20(20). 현재 획 수와 시범을 표시하며 완료 후 같은 과목의 다음 글자로 이어집니다. 두 자리 숫자는 왼쪽 숫자부터 쓰고 획마다 저장합니다. 소문자 a/g는 한 층 손글씨 형태입니다. 사과/나무 낱말은 듣기/보기만 제공합니다. 경로는 직접 작성한 중심선이며 **교육 전문가의 모양·필순 검수는 미완료**입니다. [전체 경로 미리보기](docs/tracing_preview.png)에서 점검할 수 있습니다.

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

2026-10-15 사용자 승인으로 기존 서명 보류를 해제하고 **APK 직접 공유용 전용 키**를 생성했습니다. 릴리스 빌드는 로컬 `android/key.properties`를 읽어 자동 서명합니다. Play Store 업로드는 하지 않습니다.

최신 릴리스 빌드 성공 및 apksigner 서명 검증 통과(v2, 종료 코드 0). APK 약 51MB. 전체 테스트 73개 통과, 정적 분석 문제 없음. 자세한 결과는 PROGRESS와 `docs/sharing-apk-signature.log`를 확인하세요. 설정은 [Flutter 공식 서명 안내](https://docs.flutter.dev/deployment/android#sign-the-app)를 따릅니다. Flutter test와 APK build는 생성 파일 충돌을 피하도록 순차 실행하세요.

```powershell
powershell -ExecutionPolicy Bypass -File tool/android.ps1 build apk --release
```

공유 파일: `build/app/outputs/flutter-apk/app-release.apk`. 수신 기기에서 APK를 여는 앱의 '알 수 없는 앱 설치' 권한을 허용하고 설치합니다. 실제 기기 설치 결과는 별도 검증 대상입니다.

**백업할 비공개 파일 두 개:** `android/release-signing/kkoma-sharing.p12`, `android/key.properties`. 두 파일은 Git에서 제외되며 비밀번호는 채팅·문서·로그에 출력하지 않습니다. USB나 본인의 안전한 저장소에 별도 백업하세요. 자동으로 외부 백업하거나 전송하지 않았습니다. APK만 공유하고 키/비밀번호는 공유하지 마세요.

다른 PC에서는 소스를 clone한 다음 두 비공개 파일을 같은 위치로 복원해야 릴리스 빌드할 수 있습니다. 키가 없으면 새 키를 생성하지 말고 원본 백업을 복원하세요. 키 생성 스크립트 `tool/create-sharing-key.ps1`는 기존 파일을 덮어쓰지 않습니다. 예전 `tool/sign-debug.ps1`은 공유 빌드에 사용하지 않습니다.

업데이트는 같은 applicationId와 같은 서명 키를 유지하고 `pubspec.yaml`의 빌드 번호를 올려 배포합니다. 현재 앱 ID는 `com.example.flutter_application_1`이며 그대로 유지했습니다. 현재 에뮬레이터는 offline이고 실제 Galaxy Tab 설치·성능 검증은 미완료입니다. 절차는 [docs/DEVICE_VALIDATION.md](docs/DEVICE_VALIDATION.md)를 참고하세요.

## APK를 GitHub Releases에 올리기

변경 소스를 먼저 커밋한 뒤 프로젝트 루트에서 실행합니다:

```powershell
powershell -ExecutionPolicy Bypass -File tool/publish-apk.ps1
```

명령 하나로 analyze/test → 서명 APK 빌드 → 서명 검증 → main push → Releases APK 업로드를 순서대로 실행합니다. Git Credential Manager의 기존 GitHub 로그인을 사용하며 GitHub Secrets에 서명 키를 등록하지 않습니다. 일반 `git push`만 실행하면 APK는 올라가지 않습니다.

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

테스트는 필기 방향/부분/터치/떨림, 4연령×12화 완주, 힌트/도움/분기/저장 복구, 빠른 중복 입력, 설정 동시 쓰기, 하루 사용 시간, PNG 동시 저장/다시 열기/삭제 및 실패 롤백, 중단된 삭제 복구, 음성 중복/무음/누락/시간 초과, 태블릿 3크기 전체 화면을 검증합니다. 최신 실제 실행 결과는 PROGRESS와 `docs/followup-test.log`를 확인하세요. 오디오는 호스트의 채널 mock 테스트이며 Android 기기 재생 검증과 구분합니다.

2026-10-15 필기 확장 검증 기록은 `docs/tracing-expansion-test.log`에 있습니다. 모든 경로의 4연령 정상 입력, 원형/교차 획의 역방향·부분 입력, 두 자리 숫자 순서·중단 후 복원, 연령별 다음 글자 선택을 검증합니다. 경로 검토 이미지 재생성: `flutter test tool/tracing_preview_test.dart` (Windows에서는 먼저 TEMP/TMP를 `.tool_tmp`로 설정).

명세 대비 구현 범위와 누락 사항은 [docs/REQUIREMENTS_STATUS.md](docs/REQUIREMENTS_STATUS.md)에 정리했습니다.

`dart run tool/audit_content.dart`는 콘텐츠 참조와 리소스를 검사하고 `docs/content_audit.json`을 생성합니다. `--require-recordings`를 추가하면 녹음이 누락될 때 실패합니다. 현재 사전 녹음 240파일, 효과음, 배경음악은 제작하지 않았습니다. 효과 설정은 현재 진동 켜기/끄기이며 음량 조절 가능한 효과음으로 보고하지 않습니다. 시스템 이모지와 TTS 발음은 기기마다 다를 수 있습니다.

실제 Galaxy Tab의 필기·음성·프레임/메모리·재부팅/업데이트, 아동 사용성, 교육 전문가의 문항/필순/발음 검수, 정식 앱 ID/서명은 미완료입니다. 앱 ID는 `com.example.flutter_application_1`을 유지했습니다.

패키지 API는 공식 [Riverpod](https://pub.dev/packages/flutter_riverpod), [go_router](https://pub.dev/packages/go_router), [sqflite](https://pub.dev/packages/sqflite), [path_provider](https://pub.dev/packages/path_provider), [flutter_tts](https://pub.dev/packages/flutter_tts) 문서와 설치된 소스를 확인했습니다. 불필요한 템플릿 cupertino_icons는 제거했습니다.
