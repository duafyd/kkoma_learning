# 소스 전달과 다음 작업

2026-10-17 누적 구현 소스40bd63f를 main에 공개했고, APK1.0.0(214325690)도 GitHub Releases에 공개했다. 최신 결과는 docs/published_build.json과 PROGRESS 상단을 따른다. 이전 단계의 로컬/미업로드는 당시 기록이며 이번 공개에 포함됐다. 다음 변경의 공개는 다시 별도 사용자 요청 기준을 유지한다.

## 다른 PC에서 이어서 개발

```powershell
git clone https://github.com/duafyd/kkoma_learning.git
cd kkoma_learning
flutter pub get
powershell -ExecutionPolicy Bypass -File tool/verify-source.ps1
```

현재 검증 환경은 Flutter stable 3.47.7 / Dart 3.13.5다. `pubspec.lock`을 유지한다. 소스 검사에는 Android 서명 키나 AI API 키가 필요하지 않다. Windows 검사는 `.tool_tmp`를 임시 폴더로 사용한다. Android SDK/JDK 설치와 한글 SDK 경로 우회는 README의 개발 환경 설명을 따른다.

스토리 후속(로컬 검증 완료: analyze0/전체466/Android4): `story` 문서에 선택적 `episodeId`/`sceneId`를 추가하고 기존 숫자 `episode`/`scene`도 유지한다. SQLite 스키마는1이며 별도 일괄 마이그레이션/일반 조회 중 쓰기는 없다. 유효한 pendingDrawing 제출 복구는 기존대로 같은 작품을 저장·완료한다. 유효한 ID가 숫자보다 우선하며 없는 과거 ID는 당시 숫자로 해석한다. 제거된 장면은 같은 화 시작, 기존에 알려진 부적격 장면은 다음 유효 장면으로 이동하고 해당 활동의 획/힌트/성공/지원/제출 상태만 다시 시작한다. flags와 completed는 보존한다. 조건부 그림 저장은 정규화된 동일 체크포인트를 비교한 뒤 실제 원문으로 CAS한다. 삭제된 장면의 제출 intent를 읽었다고 그림을 자동 생성하지 않는다. 실제 ID 없는 옛 기록의 과거 콘텐츠 순서를 추측할 수는 없고, 같은 ID를 전혀 다른 과제로 재사용하면 상태의 의미를 보장할 수 없으므로 과제가 바뀌면 새 ID를 부여한다. `test/story_resume_identity_test.dart`와 기존 그림 복구 검사를 함께 실행한다.

이번 공개에 포함한 학습 이어하기 후속: Trace/학습 세션 문서의 `_updatedAt`은 본문과 동일 쓰기이며 퀴즈는 선택적 `quizId`도 저장한다. 과거 문서는 계속 읽고 SQLite 스키마 버전은1이다. 홈은131개 키를 일괄 조회해 현재 경로 내 미완료 필기/퀴즈만 읽기 전용으로 고른다. 별도 북마크 문서는 없고 완료/초기화 완료 후에는 해당 카드가 사라진다. 시각 없는 과거 기록은 카탈로그 순서로 선택한다. 임의 저장 경로/URL은 사용하지 않는다. `RESUME_CAPTURE=true`로 `test/learning_resume_test.dart`를 실행하면 새 홈3크기를 재생성한다. 실제 DB 재개/배치 조회는 Android 통합 검사에 포함한다.

이번 공개에 포함한 보호자 후속: `autoAdvanceLearning`은 과거 설정에서 true로 읽히며, 끄면 함께 찾기의 단계가 보호자가 고른 경로를 넘지 않는다. 이미 높은 세션은 재진입 시 현재 문제만 다시 시작하고 완료 기록은 지우지 않는다. 보호자 미리보기는 실제 글자 획/문항/참고 답/힌트를 읽기 전용으로 보여 주며 교육 검수 승인이나 아이의 완료 기록을 만들지 않는다. 화면 재생성은 `.tool_tmp`를 TEMP/TMP로 지정한 `flutter test --concurrency=1 --dart-define=PARENT_CAPTURE=true test/parent_curriculum_test.dart`다.

`verify-source.ps1`은 Git에 들어갈 비공개 키/설정·설치 패키지 경로를 거절한 뒤 analyze, 전체 테스트, 음원 인덱스 일치, 대본/연기 지침/콘텐츠 검토 자료 재생성 일치, 콘텐츠 감사와 Git 공백 검사를 순서대로 실행한다. Windows 체크아웃의 CRLF/LF 차이는 무시한다. 오래된 생성 자료는 다시 만든 파일을 남기고 실패하므로 변경을 검토한 다음 재실행한다. 파일명 검사는 임의 문자열에 숨긴 비밀을 탐지하는 보안 감사가 아니다. 음성 생성·결제·기기 설치·커밋·푸시·Release 업로드는 실행하지 않는다.

## APK를 만들 때

원본 공유 서명 키와 `android/key.properties`는 Git에 없다. 기존 앱을 업데이트할 때는 별도 보관한 **같은 키**를 복원해야 한다. 이 두 파일을 채팅이나 저장소에 올리지 않는다. 원본 키 없이 릴리스 빌드가 실패하는 것은 의도한 동작이다. 새 키를 자동 생성하지 않는다.

일반 `git push`는 소스만 올린다. APK 공개 배포는 사용자가 요청한 경우에만 README의 `tool/publish-apk.ps1` 절차로 수행한다. 이전 공개 APK와 최신 로컬 APK는 서로 다를 수 있으므로 `docs/PROGRESS.md`와 `docs/published_build.json`의 빌드 번호를 먼저 확인한다. 콘텐츠 검토·보호자 미리보기·학습 이어하기·스토리 ID 후속은 이번 공개에 포함됐다. 이후 변경의 반영 여부는 PROGRESS에서 확인한다.

## 보류 및 다음 검수

- 음원: 실제 등록 음원은 0개다. 고정 대본 671개와 AI 시연 계획은 준비됐지만 비용 사용은 보류다. `generate_ai_auditions.dart --execute`는 실행하지 않는다. 현재 음성은 기기 TTS 대안이다.
- 교육 검수: `docs/review/`의 128경로·127문항(필기 도움9개 포함)·48개 연령/화 경로를 ID별로 검토하고 근거를 기록한다. 탐색12개는 단일 정답이 없다. 자동 검사 통과로 pending 승인을 바꾸지 않는다.
- 실기기: 사용자의 마지막 단계 요청을 유지한다. 나중에 `docs/DEVICE_VALIDATION.md`에 따라 실제 필기·소리·성능·업데이트를 확인한다. 최신 에뮬레이터 통합4개 통과는 이를 대신하지 않는다.
- 검수 피드백이 오면 해당 경로/문항/장면 ID를 수정하고 집중 회귀와 전체 소스 검사를 실행한다. 저장 형식과 기존 공유 서명은 보존한다.
