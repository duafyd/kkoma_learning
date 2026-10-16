# 소스 전달과 다음 작업

## 다른 PC에서 이어서 개발

```powershell
git clone https://github.com/duafyd/kkoma_learning.git
cd kkoma_learning
flutter pub get
powershell -ExecutionPolicy Bypass -File tool/verify-source.ps1
```

현재 검증 환경은 Flutter stable 3.47.7 / Dart 3.13.5다. `pubspec.lock`을 유지한다. 소스 검사에는 Android 서명 키나 AI API 키가 필요하지 않다. Windows 검사는 `.tool_tmp`를 임시 폴더로 사용한다. Android SDK/JDK 설치와 한글 SDK 경로 우회는 README의 개발 환경 설명을 따른다.

`verify-source.ps1`은 Git에 들어갈 비공개 키/설정·설치 패키지 경로를 거절한 뒤 analyze, 전체 테스트, 음원 인덱스 일치, 대본/연기 지침/콘텐츠 검토 자료 재생성 일치, 콘텐츠 감사와 Git 공백 검사를 순서대로 실행한다. Windows 체크아웃의 CRLF/LF 차이는 무시한다. 오래된 생성 자료는 다시 만든 파일을 남기고 실패하므로 변경을 검토한 다음 재실행한다. 파일명 검사는 임의 문자열에 숨긴 비밀을 탐지하는 보안 감사가 아니다. 음성 생성·결제·기기 설치·커밋·푸시·Release 업로드는 실행하지 않는다.

## APK를 만들 때

원본 공유 서명 키와 `android/key.properties`는 Git에 없다. 기존 앱을 업데이트할 때는 별도 보관한 **같은 키**를 복원해야 한다. 이 두 파일을 채팅이나 저장소에 올리지 않는다. 원본 키 없이 릴리스 빌드가 실패하는 것은 의도한 동작이다. 새 키를 자동 생성하지 않는다.

일반 `git push`는 소스만 올린다. APK 공개 배포는 사용자가 요청한 경우에만 README의 `tool/publish-apk.ps1` 절차로 수행한다. 이전 공개 APK와 최신 로컬 APK는 서로 다를 수 있으므로 `docs/PROGRESS.md`와 `docs/polish_build.json`의 빌드 번호를 먼저 확인한다.

## 보류 및 다음 검수

- 음원: 실제 등록 음원은 0개다. 고정 대본 671개와 AI 시연 계획은 준비됐지만 비용 사용은 보류다. `generate_ai_auditions.dart --execute`는 실행하지 않는다. 현재 음성은 기기 TTS 대안이다.
- 교육 검수: `docs/review/`의 128경로·118문항·48개 연령/화 경로를 ID별로 검토하고 근거를 기록한다. 자동 검사 통과로 pending 승인을 바꾸지 않는다.
- 실기기: 사용자의 마지막 단계 요청을 유지한다. 나중에 `docs/DEVICE_VALIDATION.md`에 따라 실제 필기·소리·성능·업데이트를 확인한다. 에뮬레이터 통합1개 통과는 이를 대신하지 않는다.
- 검수 피드백이 오면 해당 경로/문항/장면 ID를 수정하고 집중 회귀와 전체 소스 검사를 실행한다. 저장 형식과 기존 공유 서명은 보존한다.
