# 소스 전달 검사와 GitHub 반영 (진행 중, 2026-10-16)

요청: “다 하고 다음단게 진행하고 깃에 올리자”. 이번 요청으로 기존 로컬 개선 전체의 소스 커밋/푸시를 승인받았다. 아래 과거 단계의 Git 보류 기록은 당시 상태이며 이번 소스 전달에는 적용하지 않는다. APK 공개 업로드는 이번에 요청하지 않았으므로 기존 공개 파일을 유지한다. 유료 음원 제작·실기기 검증 보류는 유지한다.

- [x] 원격 fetch 및 main/origin/main 분기 없음(0/0), 기존 미커밋 변경 보존.
- [x] `tool/verify-source.ps1` 추가: 비공개 파일/설치 패키지 경로 차단, analyze/전체 테스트, 음원 인덱스·대본·연기 지침·검토 자료 재생성 일치, 콘텐츠 감사, 작업/스테이지 공백 검사. 네트워크 음성 생성·자동 배포 없음.
- [x] `docs/SOURCE_HANDOFF.md`에 다른 PC 개발/서명 키 별도 복원/외부 검수와 보류 조건 정리. README의 깨진 명령 문장과 오래된 음원357개 설명을 현재671대본/등록0개로 수정.
- [x] 실제 Git 임시 저장소2개에서 가짜 `.p12`/`.apk`를 추적한 경우 테스트 실행 전 거절·종료1 확인. PowerShell 구문 검사 통과. 비공개 경로 후보0/알려진 credential 형식 후보0. 원본 키 두 파일의 ignore 확인, 값 출력 없음.
- [x] 최종 소스 전달 검사: analyze 문제0 / 전체415개 통과(테스트138초), 음원 인덱스/671대본/352스토리 take/118문항/48경로 재생성 일치, 콘텐츠 오류0, 작업/스테이지 공백 검사 통과. 전체 명령 종료0, `docs/source-handoff-verify.log`(로컬). Windows 줄바꿈 비교도 CRLF/LF 동등·내용 변경 검출을 따로 확인했고 최종 PS 구문 오류0이다. Dart build hooks의 stderr가 외부 PowerShell 로그에 NativeCommandError 형식으로 표시되지만 실제 명령 종료0 및 모든 검사 성공을 확인했다.
- [ ] 검토한 프로젝트 파일 커밋/푸시 및 원격 SHA 확인.

최신 로컬 APK는 기존 **214290482**를 유지한다. SHA256 `9a049dba63379dcc880fa818c78e0f0faf244762061727d1c14af3ac092cc7ee`를 다시 확인했다. 이번 추가는 개발 검증 스크립트/문서이며 앱 바이너리 변경은 없다. 이전 에뮬레이터 통합1개/서명 v2 검증 기록은 아래에 있다. 현재 단계에서 실기기·음성·APK 공개 배포를 새로 수행했다고 보고하지 않는다.

다음: 소스가 GitHub에 반영되면 다른 PC는 이 저장소를 clone해 같은 검증 명령으로 이어간다. 교육자 검수·아동 관찰·실기기·음원 제작 결과가 오면 ID별 수정/회귀를 진행한다. 유료 생성 보류와 실제 기기 마지막 검수 방침을 임의로 해제하지 않는다.

# 음원·실기기 외 로컬 완성도 마무리 (로컬 구현·호스트/에뮬레이터 검증 완료, 2026-10-16)

요청: 음원 제작과 실기기 테스트를 제외한 남은 작업을 진행한다. Git 푸시/APK 업로드도 별도 요청 전에는 하지 않는다. 기존 미커밋 작업·저장 데이터·공유 키를 보존한다.

- [x] 홈 이어하기/장별 모험 지도·작품 전시, 수학/그림방의 그림책 색·도구·안내 통일.
- [x] 유아용 점·선·원 준비 운동과 저장/시범/다음 연습, 전체 필기 경로의 기계적 검사·시각 검토 자료.
- [x] 기존 캐릭터와 일관된 투명 동작 atlas 제작·실제 프레임 사용, 유한 이동/인사·무동작/복원/백그라운드 처리.
- [x] 수학 조작의 더하기·빼기 원인/결과와 그림 도장/완료 피드백 보완, 기존 진도/저장 복구 회귀.
- [x] 기능별 analyze/test, 최종 전체 검사·캡처·콘텐츠 감사·서명 APK 로컬 빌드, README/요구사항/재개 기록.

범위 구분: 전문 교육자 검수·아동 관찰은 자동 코드 검사로 대체할 수 없다. 대본/필순/난이도의 검토 자료와 로컬 검사를 준비하고 외부 확인은 별도로 남긴다. 음원/음악 제작·기기 설치·실제 청취/터치/성능 검증은 이번 요청에서 제외한다. 새 패키지·유료 API·서버를 도입하지 않는다.

구현1/준비 운동: 별도 `prewritingItems`에 점·가로길·세로길·동그라미·물결·산길 6종을 추가했다. 기존 학습122항목과 구분해 `/prewriting`에서 접근하며, 기존 TraceVM/Repository/시범/코칭/다음 활동/초기화를 공유한다. 점만 전용 PrewritingStrategy로 가까운 탭을 받고 일반 글자·숫자는 탭을 계속 거절한다. 취소·저장 복원·3화면·보호자 초기화 4개 집중 검사 통과. 첫 전체 검사에서 600px/글자1.5배 수학 상단 액션이 넘쳤고 손가락 놀이의 중복 수학 액션을 제거해 수정했다. 이후 UI 단계 전체 analyze 문제0/404개 통과(124초, `docs/polish-ui-full.log`).

구현2/화면·수학·그림: 홈 표지는 실제 저장 화/장면, 모험 지도는 12개 표지·목표·완료 상태와 현재 화 이어하기를 제공한다. 다른 표지 미리보기는 진도를 바꾸지 않는다. 작품은 확대/다시 그리기, PNG가 없어도 저장 문서로 화면에 복원한다. 그림방은 공통 안내·색 이름·글꼴 독립 꽃/나비/별/원/세모 도장, 넓은 태블릿 옆 도구와 폰 캔버스 우선 배치를 사용한다. 기존 5종 emoji 도장도 같은 의미로 다시 렌더하며 기존 PNG 파일은 변경하지 않는다. 수학 Counting 상태/VM을 UI에서 분리하고 실제 추가/제거에 따른 수식·사과 소품을 표시한다. Sorting의 새 선 잇기는 기존 VM/판정/저장을 그대로 사용하고 드래그·탭/스크롤 대안·취소·힌트·저장 실패/복원에 대응한다. 선은 저장 성공한 짝만 남으며 바구니 보기로 돌아가도 결과를 공유한다. 새 흐름7개 통과. 최초 작품함3개 검사는 가상화 목록을 스크롤하기 전에 찾던 테스트 오류였고 실제 스크롤로 수정해 통과했다.

구현3/캐릭터: imagegen 스킬의 내장 이미지 도구를 사용해 `assets/story/cast-motion-v1.png`를 새로 만들었다. 4인물×idle/입 열기/이동 A/B의 실제16프레임이며 기존 캐릭터 디자인을 참조했다. 균일 격자 요청이 지켜지지 않아 명시적 행 경계를 사용하고 alpha·소스 영역·실제 컷 몽타주를 확인했다. 재배치 시도본은 `docs/art-review/cast-motion-packing-attempt.png`에 남기고 앱에는 넣지 않았다. 프롬프트는 `docs/cast_motion_prompt.txt`/`cast_motion_packing_prompt.txt`. `StoryCastFrame`이 1024px 캐시 이미지의 실제 프레임을 그리며, 정상 등장과 돌다리/별길 이동에 유한 두 포즈를 교대한다. 인사 때 입 열린 표정을 사용하지만 음소에 맞춘 립싱크는 아니다. 기존 탐색/가리키기 포즈도 유지한다. 동작 끄기/복원/백그라운드에는 정지하고 진도 판정에 관여하지 않는다. 실제 투명도/16소스/걸음 변화/중단·동작 줄이기/화면 컷 3개 통과.

구현4/필기·검토 자료: 25개 영문/숫자 곡선과 이를 포함한 복합 숫자의 꺾인 몸통을 부드럽게 만들었다. 의도한 모서리, 획 수·순서·시작/끝점은 유지하고 기존 완료 잉크·진도 인덱스를 초기화하지 않는다. 기존 ㅊ 짧은 획 수정도 유지한다. 128개 실제 경로를 4연령에서 전체 수용·부분/탭/가로지르기 거절로 검사했다. `docs/review/`에 시작점·획 번호·다른 색 경로6장, 128항목 좌표 JSON, 실제118개 문항 JSON/CSV, 4연령×12화 경로와 검토 지침을 제공한다. 내부 구조 검사는 통과했지만 교육자 승인·청취·아동 관찰은 전부 pending이다. 곡선/기존 필기 집중22개 통과(`docs/polish-curves.log`), 프레임/검토5개 통과(`docs/polish-review.log`).

화면 확인: 3크기×글자1/1.5배의 새 흐름6개 재통과(`docs/polish-final-capture.log`, 7초), `docs/screenshots/polish-{home,prewriting,dot,curve,drawing,counting,connection,gallery,exhibition}-{tablet,phone,landscape}-{1.0,1.5}.png` 54장. `cast-motion-review.png`로 실제16컷도 확인했다. 이는 호스트 이미지이며 실기기 검증이 아니다. 최종 전체 검사/감사/빌드는 아래에 기록한다.

에뮬레이터: 설치된 Pixel_Tablet/WHPX를 확인했다. 기존 emulator-5554는 offline이며 이를 종료하거나 데이터를 변경하지 않았다. 같은 AVD의 read-only 시도는 기존 인스턴스 잠금 때문에 실패했다. 대신 `.tool_tmp/polish-avds`에 별도 KkomaPolish AVD를 만들고 5580 포트/숨김 창/무음/2GB RAM/SwiftShader로 시작했다. 실제 기기는 조작하지 않는다. 기존 Android 통합 검사의 오래된 홈/제목 선택자를 현재 UI로 고치고 별도 DB의 준비 운동 저장 확인도 추가했다. 부팅 및 실행 결과는 최종 기록에 반영한다.

최종 자동 검사: `tool/test.ps1` **analyze 문제0 / 전체415개 통과**(직전393 + 준비 운동4 + 화면/연결7 + 경로/검토2 + 캐릭터3 + 화면6, 170초, 종료0, `docs/polish-full-test.log`). `BOOK_CAPTURE` 등 기존 검사도 기본 전체 검사에 포함되며 파일 생성은 각 opt-in 플래그에서만 수행한다. `prepare_recordings.dart --check`/`audit_content.dart` 종료0, 콘텐츠 오류0, 122기존 학습 + 준비 운동6종/12화, 음원은671개 미제작/0등록으로 유지한다. `export_content_review.dart` 종료0, 검토 문항118개·연령/화 경로48개. `git diff --check`도 통과했다.

Android 실행 결과: 새 KkomaPolish 에뮬레이터 API35/2560×1600가 약79초에 부팅됐다. 기존/실제 기기의 데이터는 사용하지 않았다. PowerShell을 통한 `-d ... --timeout ...` 전달은 Flutter가 위치 인자로 오인해 최초 실행이 실패했고 `--device-id=emulator-5580 --timeout=120s`로 수정했다. 디버그 APK 빌드122.1초/설치 후 통합1개가13초에 통과했다. DB 재개 후 점 연습의 `done`도 직접 확인하는 assert를 추가해 재실행했고, 최종 빌드43.5초/검사7초 **1개 통과·종료0**(`docs/polish-android-integration-final.log`). 실제 Android SQLite·프로필 저장·홈/이야기 이동·선택 진도·준비 운동 저장·DB 닫기/다시 열기를 확인했다. 이는 음성/프레임/실기기 성능 또는 전체12화 Android 완주 검사가 아니다. 검사가 끝난 뒤 이번에 만든5580만 `adb emu kill`로 종료했고 기존5554는 조작하지 않았다. 테스트 AVD와 로그는 `.tool_tmp`/로컬 로그에 남겨 다음에 재사용할 수 있다.

재개/제약: 유료 음원 생성, 음악 제작, 실제 기기 설치/청취/필기/성능, Git 푸시/APK 업로드는 하지 않는다. 교육자 승인·아동 관찰·별도 보안 저장소의 키 백업 확인은 사람이 해야 하며 자동 검사 통과로 대체하지 않는다. 새 동작은16프레임의 단순 포즈 전환이고 음소 립싱크·긴 걷기 사이클 제작을 완료했다고 보고하지 않는다. 문항/그림체의 전문 검수도 대기다. 마지막 릴리스 빌드/서명 결과는 아래에 추가한다.

최종 로컬 APK: `tool/android.ps1 build apk --release --build-number=214290482` 성공(Gradle68.2초, 종료0). **1.0.0 (214290482)**, **149,998,465 bytes /143.0MiB**, `build/app/outputs/flutter-apk/app-release.apk`. 기존 공유 키로 apksigner **v2 true / 서명자1** 확인, aapt 버전 확인. SHA256 `9a049dba63379dcc880fa818c78e0f0faf244762061727d1c14af3ac092cc7ee`. 결과 `docs/polish_build.json`, 로컬 로그 `docs/polish-build.log`/`docs/polish-signature.log`/`docs/polish-package.log`. 최종 추가 analyze도 문제0(4.1초, `docs/polish-final-analyze.log`). 기존 KGP/flutter_tts 미래 호환·Cupertino 폰트·JDK native 경고는 남지만 현재 debug/release 빌드·서명은 통과했다. 새 패키지/키/결제 서비스/사용자 데이터 삭제를 하지 않았다. **Git 커밋/푸시·APK 업로드 없음**. 공개 APK는214232596, 최신 로컬 파일은214290482다.

재개 명령: `tool/test.ps1`; `.tool_tmp`를 TEMP/TMP로 지정해 `flutter test --concurrency=1 --dart-define=POLISH_CAPTURE=true test/polish_capture_test.dart`, `flutter test --concurrency=1 --dart-define=REVIEW_EXPORT=true test/content_review_test.dart`, `flutter test --concurrency=1 --dart-define=CAST_CAPTURE=true test/story_cast_frame_test.dart`; `dart run tool/export_content_review.dart`; `dart run tool/prepare_recordings.dart --check`; `dart run tool/audit_content.dart`. Android 통합은 실제 기기 대신 별도 에뮬레이터를 선택하고 `tool/android.ps1 test integration_test/app_flow_test.dart --device-id=<ID> --timeout=120s`를 사용한다. 새 로컬 보완 범위는 완료했고, 외부 교육 검수/아동 관찰의 결과가 오면 자료의 ID를 기준으로 수정한다. 실기기·음원 제작은 사용자 요청 때까지 보류한다.

# 7~12화 본문 미션 연출 마무리 (로컬 구현·자동 검증 완료, 2026-10-16)

사용자 요청: 다음 화부터 마지막 화까지 이어서 진행한다. 기존 로컬 작업·공유 서명을 보존하고, 유료 음성 생성·Git 푸시/APK 업로드·실기기 테스트는 보류한다.

- [x] 7화 꽃 색/모양, 8화 휙휙 바구니, 9화 세 갈래 복습, 10화 성장 책장, 11화 복습, 12화 선택한 방의 정리를 본문 안의 입력/결과로 연결.
- [x] 8~12화 필기를 이야기 그림과 함께 유지하고 저장된 획만 장면에 반영. 11화 기존 필수 별 배치 및 7화 그림 저장/중단 복구 유지.
- [x] 연령·분기·도움·힌트·저장 실패·중복 입력·복원·애니메이션 끄기와 폰/태블릿 회귀 테스트 및 시각 확인.
- [x] analyze/전체 test, 콘텐츠/음원 감사, 로컬 릴리스 빌드·서명 검증, README/결과/재개 기록.

실제 음원은 0개이고 TTS 대안을 사용하는 상태다. 이번 범위는 기존 삽화 위의 장면별 소품 상호작용/유한 연출이며, 새 캐릭터 걷기·입모양 프레임이나 AI 연기 음원을 제작했다고 보고하지 않는다.

구현: 순수 `BookMission`은 StoryMachine이 결정한 실제 분기 문제/저장된 획·세기만 투영한다. Flame `BookMissionStage/Game`은 7~12화 퀴즈 17장면과 필기 5장면을 담당한다. 7화 꽃·잎/패턴에 따른 꽃길, 8화 글자·숫자 정리와 C 바구니/종이 이동, 9화 선택한 길의 빛줄기, 10화 씨앗·싹·나무와 펼친 책, 11화 복습과 숫자 2의 별 연결, 12화 선택한 꽃/별 장식과 ㅜ 이야기책이다. 정답/힌트/지원은 기존 Machine, 저장은 VM/Repository가 맡으며 저장 실패에는 변화하지 않는다. 선택판은 성공 후 1.8초 안에 사라지고 결과가 장면에 남는다. 무동작·시스템 동작 줄이기·복원은 즉시 최종 상태, 대기는 엔진 정지, 백그라운드 저장 후에는 연출을 다시 시작하지 않는다. 만 2세/쉬운 경로와 11화 기존 별 드래그는 유지한다. 버튼 대안도 유지한다.

7화 지도: 제출 완료 CAS에 작품 ID를 `flags.gardenArtwork`로 함께 기록한다. 새 필수 저장 필드/마이그레이션 없이 구버전은 지도가 없는 채로 정상 진행한다. Provider가 정확한 ID로 작품 문서를 찾아 정원 그림 속에 재표시하며, 다른 최신 그림/임시 초안으로 바꾸지 않는다. 보호자가 작품을 삭제했다면 지도를 숨긴다. 중단/부분 PNG/메타데이터/조건부 저장 경합 회귀를 유지하고 재개 시 같은 ID도 검사한다.

중간 검사: 신규 23개(순수 분기/연령/힌트·획, 터치 크기, 중복/백그라운드/동작 줄이기 2개, 6개 화×3크기 실제 장면/필기 18개, 지도 식별/삭제 1개)가 통과했다. 첫 집중 검사에서 지도 삭제 mock이 예전 목록을 재사용해 1개 실패했고, 실제 GalleryVM처럼 새 상태를 발행하도록 테스트를 수정해 재통과했다. lint의 중괄호 안내도 수정 후 전체 검사를 진행한다. `BOOK_CAPTURE=true` 최종 23개 통과(13초, `docs/chapters-final-capture.log`), `book-{7..12}-{choices,reaction,result,trace,written}-{tablet,phone,landscape}.png` 84장(7화는 그림 미션이라 trace/written 제외). 실제 이미지에서 글꼴 누락과 작은 미리보기 위쪽 잘림을 확인해 수정했으며, 결과 소품이 배우 얼굴을 가리는 위치도 조정했다. 호스트 렌더이고 Android 손가락/청취/프레임 검증이 아니다.

콘텐츠: export_voice_scripts/export_story_studio/prepare_recordings/--check/audit_content 종료0, 122항목/12화/콘텐츠 오류0. 9화 숫자 질문의 '작은 판'을 '그림 속'으로 바꿔 화면과 맞췄다. 671개 대본 ID·실제 녹음0·음성 비용 보류는 유지한다. 감사에 본문 22장면/실제 획 수/그림 선택 검사와 범위를 추가했다. 전체 검사 및 빌드 최종 결과는 아래에 추가한다.

최종 검사: `powershell -ExecutionPolicy Bypass -File tool/test.ps1` **flutter analyze 문제0 / 전체393개 통과**(직전370 + 신규23, 테스트118초, 종료0). `docs/chapters-full-test.log`. 기존 12화×4연령 완주, 분기/도움/필기/그림 PNG/저장 경합/오디오 회귀를 포함한다. 기존 장별 66개 위젯 검사는 접힌 버튼 대안을 열어 종전 입력/저장 실패 검증을 그대로 수행한다. 새 지도 ID를 중단 복구 검사에도 추가했다. 최종 `BOOK_CAPTURE=true` 23개/84장 및 `git diff --check`도 통과했다.

로컬 APK: `tool/android.ps1 build apk --release --build-number=214274816` 성공(Gradle56.5초, 종료0). **1.0.0 (214274816)**, **147,724,730 bytes /140.9MiB**, `build/app/outputs/flutter-apk/app-release.apk`. 기존 공유 서명 apksigner **v2 true / 서명자1**, aapt 버전 확인. SHA256 `a802896271bdb6d4991b327419d4e967c3975aaa5f81090a590a10c40bda4c95`. 결과 `docs/chapters_build.json`; 로컬 로그 `docs/chapters-build.log`/`docs/chapters-signature.log`/`docs/chapters-package.log`. 기존 KGP/flutter_tts 미래 호환성·미사용 Cupertino 폰트·JDK native 경고는 남아 있지만 현재 빌드/서명은 통과했다. 키를 새로 만들거나 데이터 삭제를 하지 않았다. **Git 커밋/푸시·APK 업로드 없음**, 공개 배포판은 여전히214232596이다.

남은 범위: 이번 본문 상호작용/필기 연출은 마지막12화까지 구현·호스트 검증했다. 모든 대사 장면의 게임화·전면적인 새 삽화/캐릭터 걷기·입모양 프레임·새 음악·전문가 교육/필순/발음 검수·아동 사용성 관찰·실제 Android 설치/손가락/청취/성능은 완료가 아니다. 연기 음원 실제 제작/청취는 비용 보류 때문에 진행하지 않았고, 현재 여전히671개 음원 미제작/0등록·TTS 대안이다. 실기기는 사용자가 정한 마지막 단계에 수행한다.

재개: 미커밋 작업을 유지한다. 주요 새 파일 `domain/book_mission.dart`, `presentation/book_mission_stage.dart`, `test/book_mission_test.dart`; Machine/Page/Illustration/PictureQuiz/StoryVM 및 감사/기존 장별·그림 복구 검사도 수정했다. `tool/test.ps1`; TEMP/TMP를 `.tool_tmp`로 지정한 뒤 `flutter test --concurrency=1 --dart-define=BOOK_CAPTURE=true test/book_mission_test.dart`; `dart run tool/prepare_recordings.dart --check`; `dart run tool/audit_content.dart`. UI/연출을 더 바꾸면 현재84장과 비교하고 기기 검증은 별도 유지한다. 음원 유료 생성·Git 푸시/APK 업로드는 새로운 명시 요청 없이는 실행하지 않는다. 이후 후보는 전체 시각 일관성/교육 검수 보완과 최종 실제 기기 검사이며, 비용 보류는 일반 앱 개발 중단을 뜻하지 않는다.

# AI 연기 음원 준비·3/4화 장면 상호작용 (코드·자동 검증 완료 / 음원 생성 비용 보류, 2026-10-16)

요청: 단순 기기 TTS 수준을 넘어 인물·감정이 살아 있는 스토리 음성을 목표로 하고, 다음 단계를 가능한 범위까지 진행한다. 실제 음원이 없는 부분을 완성으로 보고하지 않는다. 현재 연결된 음성 생성 서비스·승인된 유료 호출은 없으므로, 인물별 정확한 클립 선택·연기 제작 자료·검증을 구현한다. 사용자는 캐릭터별 AI 연기 음성을 선택했고 실제 생성 비용은 보류했다. 결제/음원 생성 호출 없이 독립 개발을 진행했다.

- [x] 같은 대사도 캐릭터/장면별로 정확한 녹음 ID를 고르는 재생 경로, 자동/수동 읽기·취소 회귀.
- [x] 전체 스토리의 인물별 캐스팅·감정·호흡·발음 제작 지침 및 파일 품질 검사 자료.
- [x] 3화 자음 열매/씨앗·4화 소리 기차의 실제 터치·필기 결과 연출, 기존 진도/도움 유지.
- [x] 실패·복원·연령·모션·화면 크기 회귀와 캡처, 전체 analyze/test·감사·로컬 APK/서명.

음성 구현: `RecordedVoice.find`/`AudioService.speak`에 선택적 녹음 ID를 추가했다. 스토리 자동/수동 읽기·소품 완료·개수·글자 샘플은 정확한 ID + 원문 + 언어를 사용하므로 다른 캐릭터의 같은 대사를 가져오지 않는다. 일반 학습의 기존 텍스트 검색은 유지한다. `StoryMachine.narrationId`는 순수 규칙이고 모든 연령/장면/선택/쉬운 길/배치 전후를 대본과 대조한다. 화면이 바뀐 뒤 예약된 이전 자동 읽기도 차단했다. 기존 녹음 인덱스 화자가 바뀌면 재제작·검수를 요구한다.

제작 자료: 전체 대본 671개(한564/영107)에 인물·감정·연기·호흡 지침을 추가했고, 그중 스토리 문맥 352개 take의 캐스팅별 시연 후보를 `docs/audio/story_studio.json`에 내보낸다. `voice_quality.dart`는 PCM의 sample peak/RMS·무음·클리핑 경고를 측정하며 LUFS/연기/청취 승인을 자동 판정하지 않는다. `STORY_DIRECTION.md`가 제작·검수 기준이다. 실제 파일은 여전히 0개, 배경음악 미제작이며 기본 음성은 TTS다.

사용자 선호 반영: 캐릭터별 AI 연기 음성을 선택했다. OpenAI Docs 스킬로 공식 API·현재 모델/종료 일정을 확인하고 `generate_ai_auditions.dart`를 추가했다. 일반 REST `gpt-audio-1.5`로 인물별 짧은 시연 4개를 만드는 선택적 개발 도구이며 앱에 Realtime/서버/API 키를 넣지 않는다. 기본 실행은 계획만 생성하고 네트워크/키 읽기/결제가 없다. 실제 `--execute`는 별도 비용 승인과 환경변수 키가 필요하다. 이 PC에서 키가 미설정임만 확인했고 값을 읽거나 출력하지 않았다. 실제 API 호출 0회/생성 음원 0개. `ai_audition_plan.json`/`AI_AUDITIONS.md`에 대상 대본·목소리 후보·요청·검수 절차가 있다. mock 3개로 staging/원문/기존 파일 보존/불완전 응답을 검증했으며 실제 서비스 연동/발음/연기 품질을 검증했다고 보고하지 않는다. 보호자 설정에 AI 제작 방식과 TTS 대안을 안내한다.

장면 구현: `LetterMission`을 3화 ㄴ/ㄱ 열매 선택·ㄱ 이름표와 4화 나/가 표지 선택·ㄴ 이름표로 확장했다. 같은 Flame 엔진이 저장된 정답·획만 읽어 열매에서 씨앗 꾸러미로의 이동/라벨, 열차 이름표 빛·출발 신호/유한 증기를 렌더한다. ㄱ/ㄴ은 각각 준비된 1획 경로를 사용한다. 힌트 선택 강조를 네 종류 모두에 연결하고, 기존 만 2세/쉬운 길·저장 형식은 보존했다. 기차 전체를 분리한 새 주행 프레임·새 캐릭터/배경/음원은 만들지 않았다. 본문 글자 연출은 이제 2~5화의 8장면이며 6/11화 배치와 12화 도입 탐색도 유지한다.

중간 검증: 오디오·번들·연기/PCM·2~5화 집중 58개 통과. 장면/오디오 캡처 실행 49개, 추가 시각 수정 후 장면 17개 재통과. 3/4화 30장을 새로 추가해 `letter-{2,3,4,5}-{choices,opening,trace,partial,complete}-{tablet,phone,landscape}.png` 총 60장. 1획인 3/4화의 partial 캡처는 첫 획 완료 상태다. 호스트 폰트/렌더이며 실제 Android 청취·터치/성능 검증이 아니다. 기존 353 + 오디오/PCM/ID 8 + 장면 6 = 전체 367개/analyze 문제 0 통과(107초, `docs/adventure-test.log`). 이후 사용자 AI 선택으로 추가한 시연 도구 3개·보호자 안내까지 포함한 최종 결과는 아래에 기록한다. 최초 번들 테스트는 새 speaker 필드를 기대값에 반영하지 않아 1개 실패했고 갱신 후 재통과했다. lint도 수정 후 재검증한다.

최종 시각 보완: 휴대폰 완료 캡처에서 씨앗 꾸러미 끈이 ㄱ 뒤로 비쳐 다른 글자처럼 보일 수 있어, 불투명 종이 이름표가 끈을 가리도록 수정했다. 캡처17개 재통과(docs/adventure-label-capture.log) 및 실제 이미지로 ㄱ 모양을 재확인했다. 이후 전체 검사370개/analyze 문제0을 다시 통과했고 아래 APK에 최종 이름표 수정도 포함했다.

최종 검증: `tool/test.ps1` **analyze 문제 0 / 전체 370개 통과**(직전353 + 음성/PCM/정확한 ID8 + 3/4화 화면6 + AI 시연 도구 mock3, 110초, 종료 코드0). `docs/adventure-final-test.log`. 최종 캡처 실행 `LETTER_CAPTURE=true` 장면17개 통과(`docs/adventure-final-capture.log`). 무료 `generate_ai_auditions.dart` 실행으로 계획 파일을 만들었고 API 호출0·생성 WAV0을 확인했다. `export_voice_scripts.dart`, `export_story_studio.dart`, `prepare_recordings.dart` 및 `--check`, `audit_content.dart` 모두 종료 코드0, 콘텐츠 오류0. 녹음 필수 생산 검사는 `export_story_studio.dart --require-recordings`가 미제작352개 때문에 예상대로 종료1(`docs/performance-required.log`)이며 이를 성공으로 숨기지 않는다. `git diff --check`도 통과했다.

로컬 APK: `tool/android.ps1 build apk --release --build-number=214272709` 성공(52.6초, 종료 코드0). **1.0.0 (214272709)**, **147,544,510 bytes / 140.7MiB**, `build/app/outputs/flutter-apk/app-release.apk`. 기존 공유 키 apksigner **v2 검증 통과 / 서명자1**, aapt 버전 확인. SHA256 `04e06981c2c31e7ce597e56e442b43d10b1dce240eedfb7b3df942bd22adb0a4`. 결과 `docs/adventure_build.json`, 로컬 로그 `docs/adventure-final-build.log`/`docs/adventure-final-signature.log`/`docs/adventure-final-package.log`. 기존 KGP/flutter_tts 마이그레이션·Cupertino 폰트·JDK native 경고는 남아 있지만 빌드/서명은 성공했다. 앞선 중간 APK는 최신 파일로 대체됐으며 Git 커밋/푸시·Release/APK 업로드는 하지 않았다. 공개 APK는 여전히 214232596이다.

**음원 비용 결정(2026-10-16):** 사용자가 AI 시연4개 유료 생성 질문에 “비용 사용은 아직 보류”라고 답했다. 실제 생성은 실행하지 않았고 유료 API 도입/결제/키 발급을 하지 않았다. 현재 API 키도 미설정이다. AI 캐릭터 음성의 선호는 유지하지만 유료 생성 재개는 사용자의 새로운 명시 요청 전까지 수행하지 않는다. 앱의 실제 음성은 여전히 기기 TTS 대안이며 성우급 AI 음원 제작/청취 완료가 아니다. 이 보류는 일반 앱 개발 중단 요청이 아니다.

남은 작업/다음: 실제 AI 시연·한국어 발음/감정·캐스팅 확정·352개 스토리 음원 제작은 비용 보류 상태다. 전체671개 음원·배경음악도 미제작이다. 독립 개발의 다음 후보는 7화 색 정원/8화 휙휙의 협동 사건을 그림 속 행동/결과로 강화하는 작업이다. 모든 중간 장면의 게임화, 캐릭터 걷기/입모양 프레임, 새 삽화의 그림체 통일, 교육·필순·발음 검수, 아동 관찰, Android 실제 설치/음성/터치/성능은 남아 있다. 실기기는 마지막에 유지한다.

재개: 미커밋 작업을 보존하고 본 항목/`AI_AUDITIONS.md`를 먼저 읽는다. `tool/test.ps1`; TEMP/TMP를 `.tool_tmp`로 지정해 `flutter test --concurrency=1 --dart-define=LETTER_CAPTURE=true test/letter_mission_test.dart`; `dart run tool/export_voice_scripts.dart`, `dart run tool/export_story_studio.dart`, `dart run tool/prepare_recordings.dart --check`, `dart run tool/audit_content.dart`. AI 도구는 `dart run tool/generate_ai_auditions.dart`의 무료 계획 생성만 허용된 현재 범위다. `--execute`는 비용 보류 해제·환경변수 키 설정 후에만 검토한다. 주요 변경: core/audio 두 파일, StoryMachine/StoryPage/StoryVM, LetterMission/Stage/StoryIllustration, ParentPage, 음성 카탈로그/번들/품질/시연 도구와 관련 회귀 테스트. API 키를 소스·로그·채팅에 넣지 않으며 기존 서명 키와 로컬 데이터를 변경/삭제하지 않는다.

기존 미커밋 작업·서명 키를 보존한다. Git 푸시/APK 업로드는 하지 않으며 실기기 검증은 마지막에 유지한다.

# 꽃문·등대의 글자 미션과 필기 연결 (로컬 구현·자동 검증 완료, 2026-10-16)

- [x] 2·5화 글자 선택을 그림 속 터치로 연결하고 기존 VM/저장·쉬운 길·접근성 유지.
- [x] 필기 중 그림책 장면 유지, 확정된 획에 따른 꽃길·등대 빛 변화, 성공 연출·무동작·복원 처리.
- [x] 실제 터치·잘못된 입력·저장 실패·획 복원·연령·가로/세로 회귀 및 화면 캡처.
- [x] 전체 analyze/test, 콘텐츠 감사, 로컬 릴리스 빌드·서명 검증, README·재개 기록 갱신.

구현: `LetterMission`은 기존 StorySnapshot에서 2·5화 주 퀴즈/필기만 투영한다. Flame `LetterMissionStage/Game`의 TapCallbacks가 기존 VM 답안 명령을 호출하며 판정·저장 규칙은 기존 State Machine/Repository에 남는다. 새 진도 필드·의존성·이미지/음원·서명 키는 추가하지 않았다. 필기 CanvasWorkspace에 그림책을 유지하고, 저장된 ㅏ 2획/A 3획에 따라 꽃길/등대 빛을 1.6초 이내로 연결한다. 정답 후 배경은 기존 삽화 사이를 1초 전환하며 문짝을 관절로 여는 새 애니메이션은 아니다. 초기 복원·무동작·백그라운드는 즉시 확정 상태를 보여주고, 대기 시 엔진은 정지한다. 2세 탐색과 쉬운 길은 기존 UI를 유지하며 그림 속 선택의 버튼 대안도 제공한다.

검증: 기존 장별/연령/저장 76개 통과 후 신규 11개를 추가했다. `tool/test.ps1` analyze 문제 0 / 전체 353개 통과(104초, `docs/letter-test.log`). 마지막 테스트 보강 후 별도 analyze 문제 0, `LETTER_CAPTURE=true` 11개 통과(`docs/letter-capture.log`). 낙서·취소·저장 실패에는 빛이 증가하지 않고, 실제 획 입력·복원·가로/세로 회전·다음 이야기·두 탭 중복 차단·백그라운드 저장·무동작/애니메이션 중단을 검증했다. 좁은 꽃문 터치 영역 중첩을 조정했고, 부동소수점 경계 검사의 정밀도와 Flutter 백그라운드 프레임 지연을 반영해 테스트를 수정했다. 소스의 lint도 수정 후 재검증했다. 최초 실패를 통과로 보고하지 않는다.

시각: `docs/screenshots/letter-{2,5}-{choices,opening,trace,partial,complete}-{tablet,phone,landscape}.png` 30장. 실제 삽화·캐릭터·문패·꽃길/등대 빛을 호스트에서 캡처했다. 캐릭터가 길을 가리던 크기와 낮은 가로 화면의 완료 버튼 위치를 수정했다. 이는 Android 실기기/아동 사용성·터치감·성능 검증을 대신하지 않는다.

콘텐츠: `prepare_recordings.dart --check`와 `audit_content.dart` 종료 코드 0. 122항목·12화, 글자 장면 4곳의 획 수/선택지 검사 추가, 콘텐츠 오류 0. 대본 671개(한564/영107), 실제 녹음 0개·배경음악 미제작은 유지한다. 이번 작업의 새로운 안내는 화면/기존 장면 음성으로 제공하며 새 녹음을 만들었다고 보고하지 않는다. 변경 파일: `letter_mission.dart`, `letter_mission_stage.dart`, StoryMachine/StoryIllustration/StoryPage/StoryPictureQuiz, `letter_mission_test.dart`, 기존 장별 버튼 대안 테스트, 감사·README·요구사항 대조표.

로컬 APK: `tool/android.ps1 build apk --release --build-number=214266319` 성공(49.4초, 종료 코드 0). **1.0.0 (214266319)**, **147,528,126 bytes / 140.7MiB**, `build/app/outputs/flutter-apk/app-release.apk`. 기존 공유 키로 apksigner **v2 검증 통과 / 서명자 1**, aapt 버전 확인. SHA256 `cd351de7349c50eac98cb713d141f012f29d8fe37c8a32e8b425418351798e68`. 결과 `docs/letter_build.json`, 로컬 로그 `docs/letter-build.log`/`docs/letter-signature.log`/`docs/letter-package.log`. 기존 KGP/flutter_tts 마이그레이션·미사용 Cupertino 폰트·JDK native 경고는 남아 있지만 빌드/서명은 성공했다. `git diff --check` 통과. Git 커밋/푸시·Release/APK 업로드는 하지 않았다. 공개 GitHub APK는 여전히 214232596이며 이번 로컬 기능을 포함하지 않는다.

남은 작업/다음: 이번 범위는 2·5화 주 글자 선택과 필기 장면 4곳이다. 전체 중간 장면의 연출·캐릭터 걷기/입모양 프레임·과목별 새 삽화·실제 녹음/음악·교육 검수·아동 사용성·실기기는 아직 끝나지 않았다. 다음 후보는 3화 자음 열매/글자 씨앗과 4화 소리 기차에서 선택·필기 결과가 장면 사건으로 이어지는 상호작용이다. 새 아트가 필요한 부분은 별도 제작/일관성 검수를 거쳐야 하며 기존 그림 이동을 새 프레임 애니메이션이라고 보고하지 않는다. 실기기 설치/업데이트·청취·성능은 사용자 지시대로 마지막에 수행한다.

재개: 기존 미커밋 작업을 보존하고 PROGRESS 최신 항목과 `letter_mission.dart`, `letter_mission_stage.dart`, `story_page.dart`, `letter_mission_test.dart`를 먼저 확인한다. `tool/test.ps1`; `.tool_tmp`를 TEMP/TMP로 지정해 `flutter test --concurrency=1 --dart-define=LETTER_CAPTURE=true test/letter_mission_test.dart`; `dart run tool/prepare_recordings.dart --check`; `dart run tool/audit_content.dart`. 호스트 캡처는 테스트 전용 Windows 한글/아이콘 폰트를 로드하며 Android 폰트를 대신 검증하지 않는다. 데이터 초기화/키 재생성은 하지 않으며 Git/APK 배포는 별도 명시 요청 때만 수행한다.

실기기 검증은 마지막에 수행한다. Git 커밋/푸시 및 APK 업로드는 이번 요청에 포함되지 않는다. 이전 미커밋 작업과 서명 키를 보존한다.

# 꼬마 탐험 공부방 개발 기록

## 그림 속 핵심 미션 / 돌다리·별자리 연출 확장 (로컬 구현·자동 검증 완료, 2026-10-16)

사용자 다음 단계 요청. 도입 탐색을 넘어 6화 돌 3개·11화 별 5개 필수 배치를 Flame 그림 속 조작으로 옮기고, 저장된 배치와 정답 성공이 실제 장면의 길/빛/동료 이동으로 이어지게 한다. 기존 미커밋 수정·연령별 탐색/대체 퀴즈·저장 형식은 보존한다. 새 패키지·유료 서비스·음원/서명 키 제작·Git/APK 업로드는 하지 않는다. 실기기는 마지막에 유지한다.

- [x] 본문 그림 속 돌/별 드래그·탭·접근성 입력과 기존 VM/State Machine 배치 연결, 버튼 대안 접기.
- [x] 배치 저장 후 경로/수량 변화·서사 피드백, 실제 정답 성공 후 건너기/별빛 길 연출·복원 시 재생 금지.
- [x] 실패/잘못된 자리·동시 입력·중단/크기 변경·애니메이션 끄기·도움 경로 회귀, 폰/태블릿 캡처.
- [x] analyze/test·콘텐츠/음원 감사·로컬 APK/서명, README/남은 작업·재개 기록 갱신.

API 확인: [Flame 공식 Drag events](https://docs.flame-engine.org/latest/flame/inputs/drag_events.html)와 설치된 1.38.2 `DragCallbacks`/이벤트 소스를 확인한다. 드래그는 표현 계층이며 배치 수집·정답 판단·진도 저장은 기존 StoryVM/StoryMachine/Repository가 처리한다.

구현 범위: `WorldMission`은 6화 돌 3개/11화 별 5개 장면의 연출 지시를 데이터로 제공한다. `WorldMissionStage/Game`은 실제 Flame TapCallbacks/DragCallbacks로 본문 삽화 안의 소품을 옮기고, 놓을 위치를 기존 `placeObject(piece,slot)` 명령에 보낸다. 한 번의 저장이 끝날 때까지 표현 계층도 입력을 잠근다. 이미 놓은 소품·잘못된 순서·중복 처리는 기존 State Machine이 판단하며, 확정된 `observedObjects` 외에 새 진도 필드를 만들지 않았다. 기존 저장을 그대로 이어 쓴다. 만 2세와 쉬운 대체 문제는 기존 그림 선택을 유지한다. 기존 Flutter 배치 판은 ‘버튼으로 놓기’ 아래 접어서 남기고 같은 VM 명령을 사용한다.

장면 연출: 6화 대상 위치를 1536×1024 원본의 실제 다리 구멍에 맞췄다. Image의 cover/초점과 같은 변환으로 터치 위치를 계산하며, 저장된 자리만 기존 완성 삽화에서 타원으로 잘라 겹쳐 실제 돌 질감을 복원한다. 래스터 이미지를 새로 생성하거나 수정한 것이 아니다. 11화는 하늘의 별길 노드를 하나씩 채우고 빛줄기를 연결한다. 배치만 끝내서는 정답 처리하지 않으며, 개수 선택의 정답 저장이 성공해야 2.4초 동료 이동·빛 연출이 시작된다. 엔진은 정지 상태에서도 입력 때 한 프레임씩 다시 그리며 유한 연출 후 정지한다. 저장된 성공 상태를 처음 열면 최종 위치를 바로 보여 주며 동료 이동을 재생하지 않는다. 이동은 기존 투명 캐릭터의 위치 애니메이션이며 새 걷기 프레임/관절 애니메이션을 제작한 것은 아니다.

서사/음성: 6·11화 수학 미션의 화자를 토토로 정리하고, 배치 전에는 길 잇기 안내, 배치 후에는 개수 질문을 읽는다. 더 이상 화면과 음성이 ‘작은 판’을 지시하지 않는다. 일반 스토리에서도 성공 후 큰 본문이 결과 대사로 바뀌고, 같은 성공 문구를 아래 상자에 중복 표시하지 않는다. 기존 TTS/녹음 우선 재생 경로에 맞춰 고정 대본 2개를 추가하고 변경된 대사/질문도 manifest에서 갱신했다. 현재 671개 ID(한 564/영 107), 실제 녹음은 여전히 0개다.

집중 검증/수정: 새 세계 미션 11개와 기존 배치/그림 회귀 8개, 총 19개 통과(`docs/world-focused.log`). 첫 검사에서 ExpansionTile 아래 Material이 없어 잉크가 가려지는 Flutter 진단과, 애니메이션을 끈 성공 전이 중 형제 위젯 알림 시점 문제가 드러났다. Material 표면을 추가하고 이동 알림을 프레임 뒤에 전달하도록 수정한 후 재검증했다. 배경 위에서 떠 보이던 돌 자리는 실제 삽화 좌표와 질감 복원으로 고쳤다. 저장 지연 중 연타·두 손가락·취소·회전·백그라운드 완료, 애니메이션/시스템 동작 줄이기·복원 시 정지가 검증 범위다. 기존 6·11화 배치 판 검사는 접힌 버튼 대안을 먼저 열어 예전 드래그/탭 검사를 그대로 수행하도록 갱신했다. 최종 전체 검사/캡처/빌드 결과는 아래에 기록한다.

최종 자동 검증: `tool/test.ps1` **analyze 문제 0 / 전체 342개 통과**(직전 331 + 새 11, 테스트 96초, 종료 코드 0). 로컬 `docs/world-test.log`. 기존 12화×4단계 완주/스토리 분기·도움·그림·필기·오디오·저장 경합과 6크기×글자 1/1.5배 등 회귀를 포함한다. 새 세계 미션의 3크기 기본 조작 외에 기존 장면 검사가 폰/가로/태블릿의 확대 글자와 버튼 대안도 검사한다. `git -c core.autocrlf=false -c core.whitespace=cr-at-eol diff --check`도 통과했다.

최종 시각 확인: `flutter test --concurrency=1 --dart-define=WORLD_CAPTURE=true test/world_mission_test.dart` **11개 통과**(`docs/world-capture.log`). `docs/screenshots/world-{6,11}-{before,journey,after}-{tablet,phone,landscape}.png` **18장** 생성. 태블릿 돌 배치 전/복원 후, 폰 완료 대사, 별자리 이동 중·가로 완료 화면을 열어 실제 좌표/큰 터치/질감/화자/결과 문구를 확인했다. 호스트 캡처용 글꼴만 테스트에서 로드하며 Android 기기 글꼴/프레임/실제 손가락 검증을 대체하지 않는다.

콘텐츠 검사: `export_voice_scripts.dart`, `prepare_recordings.dart` 및 `--check`, `audit_content.dart` 모두 종료 코드 0. **122학습 / 12화 / 도입 놀이 12곳 / 본문 세계 미션 2곳 / 콘텐츠 오류 0**. 대본은 **671개(한 564/영 107) 미제작**, 실제 녹음 0개·기존 합성 효과음 3개를 유지한다. 새 대본 2개와 변경된 대사·질문은 제작 목록/인덱스/감사에 반영했고, 음원 제작·실제 청취 검수 완료로 보고하지 않는다.

로컬 APK: `tool/android.ps1 build apk --release --build-number=214265371` 성공(84.4초, 종료 코드 0). **1.0.0 (214265371)**, **147,495,358 bytes / 140.7MiB**, `build/app/outputs/flutter-apk/app-release.apk`. 기존 공유 키로 apksigner **v2 검증 통과 / 서명자 1**, aapt 버전 확인. SHA256 `7c864f9fa0616a99feb027d9c8217dc56f9fee0d9f52eaa5c672489c1d37867e`. 결과 `docs/world_build.json`; 로컬 `docs/world-build.log`/`docs/world-signature.log`. 이전과 같은 KGP/flutter_tts·Cupertino 폰트·JDK native 경고가 남아 있지만 빌드/서명은 성공했다. 새 키 생성·Git 커밋/푸시·Release/APK 업로드는 하지 않았다.

완료 범위/다음: 이번 단계는 기존 도입 놀이 12곳에 더해 **6·11화의 본문 배치 미션 두 곳**을 그림 속 상호작용으로 확장한 것이다. 모든 중간 장면의 게임화, 새 캐릭터 걷기/입모양 프레임, 과목별 그림체 통일, 실제 녹음/음악을 끝낸 것은 아니다. 다음 후보는 2화 꽃문·5화 등대에서 필기/문제 성공이 장면 오브젝트의 상태 변화와 연결되는 연출이다. 교육·필순·발음 검수와 아동 관찰도 남아 있다. 실기기 설치/업데이트·청취·성능 검증은 사용자 지시대로 마지막에 유지한다. 소스와 새 APK는 앞선 미커밋 작업을 포함해 로컬에만 있고 GitHub 배포 APK는 여전히 214232596이다.

재개: `tool/test.ps1`; 캡처는 TEMP/TMP를 프로젝트 `.tool_tmp`로 지정한 뒤 `flutter test --concurrency=1 --dart-define=WORLD_CAPTURE=true test/world_mission_test.dart`; 대본/번들은 `dart run tool/export_voice_scripts.dart`, `dart run tool/prepare_recordings.dart --check`, `dart run tool/audit_content.dart`. 핵심 파일은 `world_mission.dart`, `world_mission_stage.dart`, `world_mission_layout.dart`, `story_illustration.dart`, `story_machine.dart`다. 배치 저장 형식은 기존 observedObjects이며 별도 마이그레이션이나 데이터 삭제를 하지 않는다. Git/APK 배포는 새 명시 요청 때만 수행한다.

## 스토리 장면 놀이·필기 경험 보강 / Flame 적용 (로컬 구현·자동 검증 완료, 2026-10-16)

사용자 요청: 스토리와 한글/영어 따라 그리기의 품질 개선, Flame 2D 엔진 도입 고려. 기존 미커밋 UI/ㅊ 수정·저장 파일을 유지한다. 공식 Flame 문서와 stable 패키지를 확인하고 장면 내 소품/반응 렌더링에만 엔진을 적용한다. 저장·정답·분기·학습 완료는 기존 Repository/State Machine/Strategy가 담당한다. Flutter 접근성/대화/보호자 UI를 유지한다. 새 유료 서비스·마이크·서명 키·Git/APK 업로드 없음.

- [x] Flame 의존성/API 호환 확인, 12화 장면 놀이 데이터와 탐색 저장/복원·효과 연결.
- [x] 장면 소품 터치/수집 반응·유한 효과·무동작/백그라운드 엔진 정지, Flutter 접근성 대안.
- [x] 필기 중 순수 Dart 코칭·진행 피드백, 곡선 시작 화살표·펜 자국·시범/현재 획 표시 보강.
- [x] 실제 입력/잘못된 입력·저장 실패·재개·연령·회전·엔진 생명주기 회귀 및 캡처 검사.
- [x] 전체 analyze/test·감사·로컬 APK/서명, 실제 적용 범위·미제작/미검증·재개 기록.

적용 범위(2026-10-16): Flame **1.38.2** stable + 전이 의존성 ordered_set **8.0.1**(둘 다 MIT)을 추가했다. [공식 GameWidget](https://docs.flame-engine.org/latest/flame/game_widget.html)·[TapCallbacks](https://docs.flame-engine.org/latest/flame/inputs/tap_events.html) 문서와 설치된 1.38.2 소스로 크기/입력/정지/생명주기 API를 확인했다. 모든 정적 그림책 페이지를 엔진으로 바꾸지 않고 각 화의 첫 대사 장면 12곳에만 `ScenePlayStage`/`ScenePlayGame`을 얹는다. 배경·실제 투명 캐릭터·대사/선택/퀴즈는 Flutter를 유지한다. 정답/저장/분기는 엔진에 넣지 않았다.

장면 놀이: 별·꽃·열매·기차표·등불·돌·물감·이야기 조각·길잡이 등불·잎·마지막 별빛·책의 12개 소품과 초대/완료 대사를 작성했다. 만 2/3/4~5세에 1/2/3개를 찾는다. 소품 탭은 VM → State Machine → Repository 저장을 거쳐 확정된 `sceneFinds`만 반영하며 중복/범위 밖/퀴즈 중 입력은 무시한다. 이전 저장에 필드가 없어도 빈 목록으로 복원하고 새 장면 이동·지원하지 않는 수준/상태에서 정리한다. 선택 놀이여서 기존 이어하기·다음 버튼·힌트/도움 경로를 막지 않는다. 발견 후 빛줄기/짧은 입자·소품 이동·캐릭터 반응을 보여 주고 가만히 있을 때 엔진을 정지한다. 접근성 조작은 동일 VM 명령을 사용한다. 초기 복원에는 효과음을 재생하지 않는다. 자동 읽기/다시 듣기에 놀이 지시를 포함하고 마지막 발견 후 반응 대사를 읽으며 음소거/자동 읽기 설정을 따른다. 실제 녹음은 추가하지 않았다.

필기: `TraceCoach`는 현재 입력만 순차적으로 검사하는 순수 Dart 코칭이다. 시작점·밝은 길 복귀·방향·끝점 안내와 진행 막대를 제공하지만 합격/저장/점수는 만들지 않는다. 기존 `TraceStrategy`의 최종 판정·왕복/부분 획 방지와 앞선 ㅊ 보완은 유지했다. 현재 획을 다음 획보다 위에 그리고, 곡선의 첫 미세 선분 대신 이동 거리로 화살표 위치·접선을 계산한다. 획마다 한 번의 시범·움직이는 펜 끝을 보여 주며 그리기 시작/움직임 끄기에는 중단한다. 손을 떼기 전에는 완료하지 않고 취소/획 변경/연령 변경에서 버퍼를 정리한다. 잉크만 화면에서 부드럽게 보이며 판정에는 원래 좌표를 보낸다. 큰 태블릿 가로 화면은 캔버스/옆 안내판, 좁은 세로/가로 폰은 기존 독립 캔버스·스크롤 도구를 유지한다. 포인터 이동은 로컬 Notifier/캔버스만 갱신한다.

검증 중 발견/수정: 첫 집중 13개 중 엔진/코칭 기능은 통과했지만 새 테스트의 SemanticsHandle 정리가 누락된 2건을 수정했다. 이후 13개 모두 통과했다. 화면 캡처에서 좁은 화면의 제목 장식이 첫 소품을 가리는 실제 문제를 확인했고 중복 제목 장식을 제거했다. 수정 후 폰·가로 폰에서도 3개 모두 실제 탭으로 수집하는 검사와 ㅊ/곡선/필기 취소·시범을 확인했다. 현재 획을 가로지르는 미래 획의 덧칠과 낮은 화면의 도구 공간도 보강했다. 최종 전체 검사/빌드는 아래에 실제 결과를 기록한다.

추가 마무리: 애니메이션 끄기/숨김 때 남던 소품 이동·입자를 즉시 지우고, 다시 보여도 반응을 재생하지 않게 하는 회귀 검사를 추가했다. 수집 완료 후에도 '별빛이 꺼졌어요'라는 기존 대사를 남기지 않도록 본문과 읽기를 완료 반응으로 전환하고 복원 상태도 검증했다. 단계별 중간 검사 330개/331개와 별도로 마지막 대사 변경까지 포함해 전체 검사를 다시 실행했다.

최종 자동 검증: `powershell -ExecutionPolicy Bypass -File tool/test.ps1` **analyze 문제 0 / 전체 331개 통과**(테스트 92초, 종료 코드 0, 로컬 `docs/experience-test.log`). 앞선 312개 + 새 19개(`scene_play_test.dart` 10, `trace_coach_test.dart` 6, `experience_test.dart` 3). 12화×4단계 탐색 저장/복원·잘못된 입력·기존 미션 자유 진행, 12종 Flame 렌더/탭/정지 중 크기 변경, 실제 실패 저장/접근성/생명주기/애니메이션 중단, 모든 획의 4단계 코칭·역방향/낙서 방지, 폰/가로/태블릿 실제 필기/취소/시범과 기존 전체 회귀를 포함한다. `git -c core.autocrlf=false -c core.whitespace=cr-at-eol diff --check`도 통과했다.

최종 캡처: `EXPERIENCE_CAPTURE=true`로 `test/experience_test.dart` 3개를 실행해 모두 통과했다(로컬 `docs/experience-capture.log`). `docs/screenshots/experience-{story,restored,hangul,english,demo}-{tablet,phone,landscape}.png` **15장**을 생성했다. 태블릿 전후 장면/한글/영어/이동 중 펜, 폰 소품·필기, 낮은 가로 필기 화면을 열어 확인했다. 호스트 한글/아이콘 폰트를 캡처 테스트에서만 로드했고 앱 번들에 복사하지 않았다. Android 실제 화면·터치 느낌·프레임/메모리 측정을 대신하지 않는다.

콘텐츠/오디오: `export_voice_scripts.dart`, `prepare_recordings.dart` 및 `--check`, `audit_content.dart` 모두 종료 코드 0. **122학습 / 12화 / 장면 놀이 12곳 / 콘텐츠 오류 0 / 실제 녹음 0개**. 장면 놀이 초대/반응/2·5단계 복원 조합 60개 ID를 대본에 추가해 **669개(한국어 562·영어 107)**가 미제작으로 남는다. 기존 609개를 녹음했다고 보고하지 않는다. manifest/CSV/번들 인덱스/감사 및 음성 제작 안내를 함께 갱신했다.

로컬 APK: `tool/android.ps1 build apk --release --build-number=214240100` 성공(55.3초, 종료 코드 0). **1.0.0 (214240100)**, **147,036,566 bytes / 140.2MiB**, `build/app/outputs/flutter-apk/app-release.apk`. 기존 공유용 키로 apksigner **v2 검증 통과, 서명자 1**, aapt 버전 확인. SHA256 `6764499556b5fc0597833f59750d5b78635894531c3c10f570e07a4fb4b078db`. 결과는 `docs/experience_build.json`, 로컬 로그 `docs/experience-build.log`/`docs/experience-signature.log`. 기존 KGP/flutter_tts 마이그레이션·미사용 Cupertino 폰트·JDK native 경고는 남지만 빌드와 서명 검증은 성공했다. 새 키를 만들거나 기존 키 내용을 출력하지 않았다.

남은 품질 작업/재개: 이번 엔진 적용은 12화 **도입 장면의 선택 탐색**이다. 모든 중간 장면의 독자적인 게임 연출, 프레임별 캐릭터 걷기/표정/입모양, 과목별 새 개별 삽화, 실제 음성/음악은 제작 완료가 아니다. 다음은 핵심 중간 미션을 장면별 행동·결과로 확장하고 전용 캐릭터 동작을 제작하는 일이며, 이후 교육·필순/발음·아동 사용성 검수가 필요하다. 실기기 설치/업데이트·청취·성능은 사용자 지시대로 마지막에 수행한다. Git 커밋/푸시·Release/APK 업로드는 하지 않았고 GitHub의 214232596 배포판에는 이번 및 앞선 UI/ㅊ 후속 수정이 없다. 변경 사항은 이전 미커밋 작업과 함께 로컬에 있다. 재개 시 `flutter pub get`, `tool/test.ps1`, 음성 manifest/감사 명령을 실행한다. 캡처는 TEMP/TMP를 `.tool_tmp`로 설정 후 `flutter test --concurrency=1 --dart-define=EXPERIENCE_CAPTURE=true test/experience_test.dart`. 현재 APK 서명/버전 결과는 위 JSON이 기준이다.

## 화면 품질 1차 개편 (로컬 구현·자동 검증 완료)

사용자 피드백: 앱이 싸구려처럼 보임. 기존 그림책 지향을 기준으로 홈·학습·스토리의 구도와 글꼴 위계/표면/버튼을 함께 정리한다. 기존 실제 삽화를 재사용하며 신규 AI 이미지·음성·유료 서비스·패키지를 추가하지 않는다. 앞서 미커밋 ㅊ 수정과 저장 상태를 보존한다. 이번 요청에는 Git 푸시/Release/APK 업로드를 포함하지 않는다.

- [x] 공용 색/글꼴/버튼/표면 규칙과 공통 활동 헤더 정리.
- [x] 홈: 모험 표지 + 과목별 그림 책장, 저장소 기술 설명을 어린이 첫 화면에서 제거.
- [x] 학습: 과목별 글자 카드·읽기/필기 행동 위계, 실제 콘텐츠/읽기/이동 유지.
- [x] 스토리: 그림 비중과 내용 크기에 맞는 대사 패널, 반응형/퀴즈/필기/그림 회귀 유지.
- [x] 실제 호스트 화면 캡처 확인·수정, 6크기×2글자 배율 회귀와 전체 analyze/test, 로컬 빌드·미검증 기록.

구성: `app_theme.dart`에 종이색/잉크색/청록/금색·제목 Jua/본문 기본 sans-serif·버튼/카드 규칙을 모았다. Android 본문은 시스템 Roboto 및 한글 대체 글꼴을 사용하며 새 폰트/패키지를 번들에 추가하지 않았다. 홈은 태블릿에서 모험 표지와 과목 책장 4개, 작품/지도 줄을 한 화면에 배치하고 좁은 화면은 세로 스크롤한다. 과목 표지는 기존 꽃문/등대/다리/정원 삽화를 재사용한다. 가짜 학습 진도·보상·새 콘텐츠 수를 표시하지 않는다. 스토리 표지는 버튼 영역을 그림 아래에 확보해 캐릭터를 가리지 않는다.

학습/스토리: 학습 데이터·읽기 VM·경로는 유지하고 `LearningCard`로 과목 색/큰 글자/단어/읽기/필기 버튼을 구성한다. 확대 글자에서 핵심 모드 전환이 밀리지 않게 '함께 찾기'를 첫 행동으로 두었으며 수학 두 조작 모드도 유지한다. 일반 학습 카드의 그림은 기존 이모지를 사용하며 새 122종 삽화를 제작했다고 보고하지 않는다. 스토리의 태블릿 가로 배치를 8:5로 조정하고, 대사 스크롤은 내용 높이까지 줄어드는 패널로 만들어 짧은 대사 뒤의 큰 빈 상자를 없앴다. 높이가 낮은 가로 폰에서는 좁은 옆 패널 대신 높이를 제한한 그림과 전체 폭 대사를 세로로 스크롤한다. 명시적 스토리 전이·저장·TTS·필기 판정 로직은 변경하지 않았다.

검증 중 발견: 첫 집중 검사에서 확대 글자의 수학 '함께 찾기'가 가로 도구 목록 뒤로 밀리는 실제 문제를 수정했다. 새 탐색 테스트의 lazy 목록 항목 찾기/스크롤 뒤 프레임 대기·음소거 효과음 설정을 보강했다. 첫 캡처의 비어 있는 그림/네모 글자는 호스트 테스트가 이미지 디코딩·폰트를 준비하기 전 캡처한 결과였다. 캡처 모드에서만 해당 자산을 미리 읽고 호스트 한글/아이콘/이모지 폰트를 로드하도록 수정했다. Windows 폰트 파일을 앱에 복사하지 않았다. 본문/텍스트 버튼의 기본 글꼴과 이모지 fallback을 명시하고, 축소 대사 패널은 유한 장면에 맞는 SingleChildScrollView/Column으로 단순화했다. analyze 인수 순서 lint 1건도 수정했다.

회귀 수정: 첫 전체 검사 310개 통과/2개 실패였다. 분류 놀이의 스크롤 직후 프레임 대기 없이 누르던 테스트를 실제 화면 갱신 뒤 누르도록 보강했다. 낮은 가로 폰의 도움 메뉴 검사는 높이 125px 뷰포트에서 200px씩 이동해 버튼을 건너뛰는 것을 디버그로 확인하고, 스크롤 단위를 실제 높이에 맞게 줄였다. 제품에서도 이 크기는 전체 폭 대사로 바꿔 지나치게 좁은 패널을 피했다. 기대한 배치 수/원래 미션 복귀 결과는 유지한다. 이후 새 홈/학습/스토리 탐색·회전/도움·실제 드래그 분류 집중 11개가 모두 통과했다(`docs/design-visual-test.log`). 최종 전체 검사와 빌드는 아래에 별도로 기록한다.

시각 확인: 홈/한글/스토리 시작/대사 위치 × 태블릿 1280×800·폰 360×780·가로 폰 780×360의 호스트 캡처 12장을 생성했다(`docs/screenshots/design-{home,hangul,story,story-dialogue}-{tablet,phone,landscape}.png`). 홈 태블릿·폰, 한글 카드, 스토리 태블릿·가로 대사 화면을 열어 비교했다. ㅊ 수정과 함께 실제 기기 확인은 남아 있다. 캡처의 본문/이모지는 호스트 폰트를 사용하므로 Android 기기 글꼴과 정확히 같은 픽셀로 검증한 것이 아니다.

최종 자동 검사: `tool/test.ps1` **analyze 문제 0 / 전체 312개 통과**(직전 309+새 탐색 3, 테스트 83초), 로컬 `docs/design-test.log`. 6개 크기×글자 1/1.5배의 기존 레이아웃 12개와 모든 스토리·필기·그림·저장·오디오 회귀를 포함한다. 수정 후 성공을 확인했으며 첫 전체 검사 2건 실패를 통과로 기록하지 않았다. 앱의 교육 적합성·사용성·실기기 성능을 자동 검사만으로 완료 처리하지 않는다.

로컬 APK: `tool/android.ps1 build apk --release --build-number=214238199` 성공(49.2초, 종료 코드 0). **1.0.0 (214238199)**, **146,380,842 bytes / 139.6MiB**, `build/app/outputs/flutter-apk/app-release.apk`. 기존 공유용 키로 apksigner v2 검증 통과(종료 코드 0, 서명자 1), aapt 버전 확인. SHA256 `a8e26b125d1b7713bd2becaded76d331d1d5ba60545ea2b33cda2eac43ab90a7`. `docs/design_build.json`, 로컬 `docs/design-build.log`/`docs/design-signature.log`. ㅊ 첫 획 수정도 포함한다. 기존 Kotlin 플러그인 마이그레이션/Cupertino 폰트/JDK 경고는 유지하며 빌드/서명은 성공했다. 번들 인덱스 검사 통과(음성 0), 콘텐츠 감사 오류 0(122학습·12화·609개 녹음 미제작)도 재확인했다.

완료 범위/다음: 홈·일반 학습 카드·그림책 대사 및 공용 스타일의 첫 개편이다. 모든 과목의 개별 사물 삽화·퀴즈 그림의 그림체 통일·캐릭터 프레임/입모양·실제 녹음/음악 제작을 끝낸 것으로 보고하지 않는다. 다음 품질 작업은 과목별 개별 삽화와 퀴즈/반응 연출을 같은 시각 언어로 확장하고 아동 사용성 피드백을 받는 것이다. 실기기 성능/글꼴/청취·최종 설치 검증은 사용자 지시대로 마지막 단계에 유지한다. 이번 수정의 Git 커밋/푸시·Release/APK 업로드·키 생성·데이터 삭제는 하지 않았다. GitHub의 214232596 APK는 이전 배포판이다. 재개 명령은 `tool/test.ps1`, 캡처는 TEMP/TMP를 `.tool_tmp`로 설정 후 `flutter test --dart-define=DESIGN_CAPTURE=true test/design_navigation_test.dart`이며 캡처 모드만 호스트 폰트를 미리 읽는다.

## ㅊ의 짧은 첫 획 입력 보완 (로컬 구현·자동 검증 완료)

사용자 증상: 한글 자음 ㅊ의 맨 위 짧은 첫 획이 잘 넘어가지 않음. 첫 획 길이 0.13에 비례한 허용 폭(4~5단계 0.0208)이 작고, 좁은 캔버스에서 시작 번호 원·종료 원·방향 화살표가 짧은 길을 가리는 점을 확인했다. 기존 획 좌표·획 수·저장 데이터는 유지하며 짧은 직선의 손가락 오차와 표시를 보완한다. Git/APK 재업로드는 이번 요청에 포함하지 않는다. 실기기는 최종 단계라는 사용자 지시를 유지한다.

- [x] 실제 ㅊ 첫 획에 작은 평행 오차/끝점 오차를 넣은 실패 재현과 탭·부분·역방향·낙서 회귀 검사.
- [x] 짧은 직선에만 제한된 오차 보완, 렌더링과 판정의 허용 폭 공유.
- [x] 짧은 획의 번호/시작점/화살표 겹침 해소, 폰·낮은 가로·태블릿 포인터/진도 복원 검사.
- [x] analyze/test, 로컬 APK 빌드·서명 검증, 실제 실행 결과와 미검증 기록.

원인/구현: 첫 획 길이 0.13에서 4~5단계 판정 반경은 캔버스의 0.0208, 2~3단계는 0.0286이었다. 수평으로 0.03만 어긋난 온전한 선이 4연령 모두 실패하는 것을 `docs/chieut-before-test.log`로 재현했다(긍정 4개 실패, 낙서 방지 4개 통과). `TraceStrategy.toleranceFor`로 판정/표시의 폭을 공유하고, 길이 0.18 이하의 두 점 직선만 기존 폭과 `min(0.035, 획 길이×0.28, 연령 허용 폭)` 중 큰 값을 쓴다. ㅊ 첫 획은 0.035가 되며 긴 획·곡선의 판정은 유지한다. 최소 길이·과도한 길이·방향·순서 검사는 그대로 유지한다. 공용 캔버스를 쓰는 스토리도 같은 정책으로 표시한다.

표시: 짧게 표시되는 획은 번호 배지를 선 옆으로 옮기고 시작/종료 원을 줄인다. 화살표의 시작·끝·촉 크기를 선 길이에 비례시켜, 작은 캔버스에서 고정 18px 시작이 화살표 끝을 지나던 문제를 없앴다. 배경 길의 반경은 판정 정책 값과 일치하도록 그린다. 원래 ㅊ 좌표/4획과 저장 ID/형식은 바꾸지 않았다.

집중 확인: 기존 필기 판정·낙서/역방향/부분·확장 검사를 포함한 33개 통과(`docs/chieut-focused-test.log`). 신규 포인터 검사는 폰 360×780·가로 780×360·태블릿 1280×800, 글자 1.5배에서 탭/부분 획 거절 → 작은 오차가 있는 첫 획 통과 → 새 VM에서 다음 획 복원 → 남은 획 완료·성공 1회 저장을 검사했다. 캡처 3장을 열어 번호·화살표·시작/종료 표시를 확인했다(`docs/screenshots/chieut-first-{phone,landscape,tablet}.png`). Flutter 호스트 렌더이며 실제 기기 화면/손가락 테스트가 아니다. 시각 검사 최초 실행의 '긴 획 허용 폭은 연령 상한과 같다'는 신규 테스트 기대 1건은 기존 길이 비례 상한을 빠뜨려 실패했다. 기대를 기존 기준 수치로 고쳤으며 판정 코드를 그 기대에 맞춰 바꾸지 않았다.

최종 자동 검사: `tool/test.ps1` **analyze 문제 0 / 전체 309개 통과**(기존 297+신규 12, 테스트 86초), `docs/chieut-test.log`. `dart run tool/audit_content.dart` 콘텐츠 오류 0. 122학습·12화·609개 미제작 대본을 유지한다. 테스트는 새 판정 정책의 실제 실패 재현과 터치/저장 복구를 검사하며 실기기 손가락 검증을 대체하지 않는다. 검수 중인 원본 획 좌표를 바꾸거나 기존 사용자의 진도를 삭제하지 않았다.

수정본 로컬 APK: `tool/android.ps1 build apk --release --build-number=214236654` 성공(51.5초, 종료 코드 0). **1.0.0 (214236654)**, **146,381,126 bytes / 139.6MiB**, `build/app/outputs/flutter-apk/app-release.apk`. 기존 키로 apksigner v2 검증 통과(종료 코드 0, 서명자 1), aapt 버전 확인. SHA256 `7d72f5db496ad14d167d06aa161b289face7496e3f09db6483b508b298d53a3e`. `docs/chieut_build.json`, 로컬 `docs/chieut-build.log`/`docs/chieut-signature.log` 참조. 기존 Kotlin 플러그인 마이그레이션/Cupertino 폰트/JDK 경고는 유지되며 빌드/서명은 성공했다. 새 키 생성·실제 기기 설치·Git 커밋/푸시·Release/APK 업로드는 하지 않았다. 기존 GitHub 공유 APK 214232596에는 이 수정이 아직 없다.

다음 확인: 실제 손가락에서 짧은 첫 획 재시도와 정상 다음 획 이동을 확인한다(사용자 지시대로 기기 검증은 최종 단계). 재현 명령은 `tool/test.ps1`, 캡처는 `flutter test --dart-define=CHIEUT_CAPTURE=true test/chieut_trace_test.dart`이며 Windows TEMP는 `tool/test.ps1`과 같이 `.tool_tmp`로 지정한다. 수정본 배포는 별도 명시 요청 때 수행한다. 아직 미완료인 녹음·음악·교육 검수/실기기 검증은 아래 기록을 유지한다.

## 후속 요청: 검증 APK 공유 배포 (완료)

사용자가 “다하면 apk도 올려”라고 추가 요청해, 앞 단계의 로컬 APK를 GitHub Releases에 공개했다. 해당 요청으로 이번 버전의 Release/APK 업로드가 승인되었으며, 이전 단계의 미업로드 문장은 당시 이력이다. 이후 버전도 명시 지시 없이 자동 업로드하지 않는다.

- 버전 **1.0.0 (214232596)**, **146,364,738 bytes / 139.6MiB**, 기존 공유용 키의 v2 서명 검증 APK.
- [APK 다운로드](https://github.com/duafyd/kkoma_learning/releases/download/apk-1.0.0-214232596/kkoma-1.0.0-214232596.apk) · [Release](https://github.com/duafyd/kkoma_learning/releases/tag/apk-1.0.0-214232596).
- 배포 소스 `6438a73021b12c621e4d307f172405d86a51a620`. 검증 빌드 구현 커밋 `4475fe8` 이후 차이가 PROGRESS 문서뿐임을 확인하고, 기존 297개 통과/analyze 0·서명 검증 산출물을 재사용했다. 앱 소스 변경/불필요한 재빌드·테스트 반복 없이 기존 APK의 로컬 크기·해시를 다시 확인했다.
- 먼저 draft 생성 → APK 업로드 → 서버 크기/전체 SHA256 일치 확인 → 공개 → 공개 자산 재조회로 크기/해시를 재확인했다. 원본 키·비밀번호는 전송하지 않았다. 기존 릴리스/자산은 덮어쓰거나 삭제하지 않았다.
- 로컬/서버 SHA256 **`05b57c24bf8a0d1c7904dec7ad475fb6473171736269cedce12967b0d304b44b`**. `docs/recorded_build.json`에 업로드 결과와 링크를 추가했다. 로컬 로그 `docs/recorded-release.log`.

실제 설치·업데이트·청취·성능 검증은 수행하지 않았으며 최종 실기기 단계로 유지한다. 실제 녹음 0/609·배경음악·교육 검수의 미완료 상태도 그대로다. 배포 기록/README만 후속 소스 커밋에 반영한다.

## 녹음 우선 재생·TTS 대체 연결 (로컬 구현·자동 검증 완료)

사용자 요청: 다음 단계 진행 후 GitHub에 올리기. 이번 완료 소스는 커밋하고 `origin/main`에 푸시한다. APK는 로컬 빌드만 하고 Release/APK 업로드는 하지 않는다. 실기기 검증은 마지막 단계다. 새 패키지·유료 서비스 없이 기존 Android 오디오와 TTS를 연결한다. 아래 이전 단계의 푸시 금지 기록은 당시 이력이다.

- [x] 대본 원문/언어와 일치하는 녹음 번들 인덱스 생성·검사, 빈 인덱스로도 오프라인 실행.
- [x] Android MediaPlayer 완료/실패/취소 계약과 음성 음량·화면 이탈/백그라운드 해제 구현.
- [x] AudioService에서 녹음 우선 → 누락/실패 시 TTS, 반복·요청 교체·시간 초과·음소거·중단 처리.
- [x] 녹음/대본 불일치·중단 경합·실패 대체·진도 기록·생명주기 회귀 테스트, 단계별 analyze/test.
- [x] 콘텐츠/번들 감사와 로컬 APK 빌드·서명 확인, README/검수 안내/미검증 기록 갱신. 실제 녹음 제작과 기기 청취는 완료로 보고하지 않음.

구현: `RecordedVoice`가 `assets/audio/recordings.json`을 읽어 원문·언어를 정확히 비교한다. 화면/VM의 기존 `speak` 호출은 유지하며 학습·필기·퀴즈·대사·별도 영어 샘플에 공통 적용한다. Android `RecordedVoicePlayer`는 번들 자산만 열고 바이트 길이를 확인한 뒤 MediaPlayer 비동기 준비/재생/완료·오류·65초 제한을 처리한다. 오디오 포커스 거절/상실, onPause, 엔진 해제는 취소로 끝내며 늦은 콜백은 요청 식별자로 무시한다. 실제 WAV/음악 제작·청취 검수는 하지 않았다. 현재 인덱스는 비어 있고 609개 대본 전부 미제작이다.

대체/취소: 녹음 완료 후에만 `played`를 돌려주며, 누락/실패/시간 초과 시 해당 요청 재생기가 정지한 것을 확인한 뒤 남은 반복 횟수만 TTS로 읽는다. 취소는 대체 재생하지 않는다. 초기 재생기 정지 실패에도 겹쳐 읽지 않도록 실패로 반환한다. 새 요청/화면 이탈/음소거/백그라운드/해제는 세대와 토큰으로 지연 결과를 무효화한다. 앱 비활성 중 늦은 읽기 요청은 거부하고 복귀 시 자동 재생하지 않는다. 음성 음량·반복은 기존 보호자 설정을 따른다.

번들 제작: `prepare_recordings.dart`는 알려진 ID의 실제 형식 유효 WAV만 등록하며 원문·언어 변경에 기존 녹음을 조용히 재사용하지 않는다. 알 수 없는 파일/잘못된 WAV/깨진 인덱스는 오류다. `--check`와 콘텐츠 감사는 인덱스 누락·갱신 누락도 검사한다. `tool/android.ps1 build ...`에 제작 전 검사를 연결했으며 새 패키지는 추가하지 않았다. 직접 `flutter build/run`을 쓰면 생성/검사를 먼저 해야 한다. 절차와 사람의 청취 검수 구분은 `docs/audio/README.md`에 있다.

API 확인: Flutter [MethodChannel 순서 보장](https://api.flutter.dev/flutter/services/MethodChannel-class.html), Android [MediaPlayer 상태·자산 descriptor·비동기 준비/완료/해제](https://developer.android.com/reference/android/media/MediaPlayer) 공식 문서를 확인하고 구현했다. Android 네이티브 동작의 실제 청취/포커스 이벤트 검증은 최종 실기기 단계다.

자동 검증: 최종 `tool/test.ps1` **analyze 문제 0 / 전체 297개 통과**(기존 263 + 신규 34, 테스트 76초), `docs/recorded-test.log`. 새 테스트는 녹음 완료 대기·언어팩 없이 재생·텍스트/언어 불일치·중복/깨진 인덱스·파일/플러그인 누락·오류/시간 초과 대체·중간 반복 실패·정지 실패·취소·새 요청·음소거·해제·생명주기·실제 학습 진도/스토리 유지와 제작 번들 검사를 포함한다. 녹음 포맷 fixture는 테스트 임시 폴더에서만 만들며 실제 제작 음원으로 포함하지 않는다. MediaPlayer/오디오 포커스는 채널 계약 mock과 네이티브 컴파일 대상으로, 실제 청취로 검증하지 않았다.

검증 중 수정: 처음 analyze의 lint 3건을 수정했다. 기존 화면 음성 테스트 4건은 새 채널에 대한 호스트 mock·실제 자산 I/O 대기·전경 상태 준비를 추가하고, 인덱스는 파싱한 목록을 캐시하도록 보강했다. 별도 화면 검사 11개 통과. 첫 전체 검사에서는 빠른 요청의 TTS stop 호출 횟수 기대만 실패해, 구현 세부 호출 수 대신 '첫 요청 cancelled / 마지막 played / 마지막만 발화 / stop 전송' 계약으로 회귀 검사를 수정했다. 수정 후 전체 검사를 재실행해 297개 모두 통과했다. 콘텐츠 감사 오류 0, 음성 대본 609/미제작 609/형식 오류 0, 번들 인덱스 검사 통과(등록 0). 미제작을 통과로 바꾸거나 임시 음성을 배포하지 않았다.

최신 로컬 APK: `tool/android.ps1 build apk --release --build-number=214232596` 성공(77.3초, 종료 코드 0), **1.0.0 (214232596)**, **146,364,738 bytes / 139.6MiB**. 기존 키로 apksigner v2 검증 통과(종료 코드 0, 서명자 1), aapt 버전 확인. SHA256 `05b57c24bf8a0d1c7904dec7ad475fb6473171736269cedce12967b0d304b44b`. 경로 `build/app/outputs/flutter-apk/app-release.apk`. ZIP에서 그림책 PNG 32장(배경 30+캐릭터 2)·효과음 WAV 3개·빈 음성 인덱스 포함 확인. 로그 `docs/recorded-build.log`, `docs/recorded-signature.log`, 메타데이터 `docs/recorded_build.json`. 기존 flutter_tts의 Kotlin 플러그인 마이그레이션·사용하지 않는 Cupertino 폰트·JDK native-access 경고는 남지만 빌드/서명은 성공했다. APK 설치/청취를 실행한 것으로 기록하지 않는다.

Git 반영 범위: 이번 음성 재생 연결과 이전 로컬 단계의 1~12화 삽화·상호작용·효과음·그림 제출 복구·대본/검사/회귀 테스트·문서를 함께 반영한다. `android/key.properties`, 비공개 키, build/APK, 임시 폴더와 로그는 Git 제외 상태를 확인했다. 원본 키 생성/교체, Release 생성, APK 업로드는 하지 않는다. 테스트 원문 로그는 로컬 파일이며 이 문서와 빌드 JSON에 재현 명령/결과를 남긴다.

GitHub 확인: 구현 커밋 **`4475fe8cb2332d0ba2849d121a72f7da6d4cb921`**(177개 변경 파일)을 `https://github.com/duafyd/kkoma_learning.git`의 `main`에 푸시했다. `git ls-remote origin refs/heads/main`과 로컬 HEAD의 일치를 확인했고 소스 푸시 직후 작업 트리는 깨끗했다. 이 배포 결과 기록은 후속 문서 커밋으로 추가한다. Release 생성·APK 업로드·비공개 키 전송은 하지 않았다. 다음 세션은 `git pull --ff-only` 후 위 재현 명령으로 시작한다.

다음 단계/재개: `tool/test.ps1`, `dart run tool/prepare_recordings.dart --check`, `dart run tool/audit_content.dart`로 재현한다. 실제 대본·한글 필순·영어 발음·문항의 교육 검수 → 1화/짧은 안내부터 실제 녹음 제작·청취 검수·등록 → 나머지 609개와 배경음악 제작 순서로 진행한다. 전체 앱의 출시 완료 백분율을 임의로 제시하지 않는다. 12화 작성은 12/12이며 실제 녹음은 0/609다. **Galaxy Tab/S25 설치·업데이트·오프라인 TTS/녹음/효과음 청취·오디오 포커스·성능/메모리·실제 강제 종료 복구 검증은 사용자의 지시대로 마지막 단계**에 수행한다.

## 중단된 그림 제출 복구·음성 제작 준비 (로컬 구현·검증 완료)

사용자 지시: 다음 단계 진행, 실기기 테스트는 최종 단계로 보류. 기존 로컬 소스/작품/서명 키 보존. 커밋·푸시·Release 생성·APK 업로드 없음.

- [x] 그림 제출 의도를 스토리와 함께 먼저 저장하고, 고정 작품 ID·임시 PNG·재시도로 프로세스 재시작 후에도 한 작품/한 성공으로 복구.
- [x] 진도 초기화/다른 진행 상태가 늦게 끝난 저장에 의해 덮이지 않도록 조건부 저장. 기존 초안·작품 저장·삭제 동작 회귀 검사.
- [x] 저장 중/복구 실패 시 다시 시도할 수 있는 UI와 중단 시점별 호스트 테스트.
- [x] 실제 읽기 텍스트·언어·출처·검수 항목을 담은 음성 제작 목록과 검사 도구. 녹음 제작/청취 검수 완료로 보고하지 않음.
- [x] 단계별 analyze/test, 최종 콘텐츠 감사·로컬 APK 검증, README/요구사항/재개 기록 갱신. 기기 설치·청취·성능 검증은 수행하지 않음.

저장 구현: 7화 저장 버튼을 누르면 `StorySnapshot.pendingDrawing`에 제출할 문서·고정 작품 ID·경로·시각을 먼저 저장한다. PNG는 같은 ID의 `.saving` 파일에 flush 후 최종 파일로 rename하고 작품 목록에 등록한다. 그 뒤 스토리 성공과 pending 제거를 같은 story 문서 쓰기로 처리한다. 재시작 시 남은 pending을 자동 복구하며, 이미 등록된 동일 작품은 다시 추가하지 않는다. 등록된 pending 작품의 PNG가 없으면 저장된 문서로 재생성한다. 다른 문서를 같은 ID에 덮거나 작품 폴더 밖에 쓰는 것은 거부한다. 일반 자유 그림의 저장/삭제 직렬화와 초안은 유지한다. 손을 떼기 전의 포인터 버퍼까지 복구한다고 보장하지 않는다.

진도 보호: `LocalStore.writeIfUnchanged`를 추가했다. SQLite는 `UPDATE ... WHERE id = ? AND value = ?` 한 문장으로 이전 문서가 그대로일 때만 저장하고, MemoryStore도 같은 계약으로 비교 후 갱신한다. `StoryRepository.replaceIfCurrent`가 예전 JSON의 누락 필드를 기본값으로 읽되 원문을 비교 대상으로 사용하므로 DB 스키마 변경 없이 호환된다. 부모 진도 초기화나 다른 장면 저장이 중간에 일어나면 오래된 저장 결과로 story를 되살리지 않는다. 초기화 시 작품 보존 규칙은 유지한다. 대기 중 그림은 편집을 잠그고 이어서 저장 버튼을 제공하며, 복구 로딩 실패에는 기존 다시 열기 경로를 사용한다.

회귀 검증: `story_drawing_recovery_test.dart` 15개를 추가했다. 제출 의도만 존재 / 부분 임시 PNG / 최종 PNG만 존재 / 작품 등록 완료 / 마지막 진도 쓰기 실패 후 새 VM / 최초 제출 쓰기 실패 / PNG 누락 / 늦게 끝난 저장과 부모 초기화·새 진도 / 연령을 2세로 변경해 그림 장면을 건너뛰는 상황 / 예전 JSON / ID 재사용·경로 범위 / 폰 360×780·780×360·태블릿 1280×800 글자 1.5배에서 실제 재시도를 검사한다. 실제 OS를 강제 종료한 테스트는 아니며, 각 중단 지점의 영속 데이터와 실제 PNG I/O를 재현한 호스트 검사다. 최초 복구 실패 테스트는 Riverpod 자동 재시도가 future를 계속 대기시키는 것을 확인해 테스트 컨테이너에서만 자동 재시도를 끄고 명시적 재시도를 검사했다. 앱의 재시도 정책은 변경하지 않았다. 기존 작품/스토리 집중 25개 통과 후 새 UI/연령 검사를 더했다.

음성 준비: `tool/voice_catalog.dart`, `tool/export_voice_scripts.dart`로 원본 콘텐츠에서 대본 JSON/CSV를 생성한다. 현재 **609개(ko-KR 502 / en-US 107)**이며 모두 파일 미제작/청취 검수 pending. 종전 388개 ID 위주의 범위에서 필기 이름·만 2세/성공/선택 결과·1~5개 세기를 포함해 재산정했다. 동적 오류/힌트/도움/분류 피드백은 고정 대본 범위 밖이다. 실제 녹음을 추가한 것은 아니며 녹음 파일의 앱 재생/번들 연결도 후속이다. CSV 609행을 PowerShell Import-Csv로 다시 읽어 JSON 건수와 일치함을 확인했다. RIFF/청크 길이·PCM16 mono·16~48kHz·byte rate·빈 파일/60초 초과 검사를 추가했고, 별도 `--require-recordings` 검사로 미제작을 차단할 수 있다. 형식 통과를 사람의 청취 검수로 바꾸지 않는다. `docs/audio/README.md`, `docs/audio/voice_scripts.{json,csv}` 참조.

읽기 수정: 학습/필기에서 소문자 a/i 등을 그대로 문장에 보내면 관사/대명사처럼 읽을 위험이 있어 `learningLetterName`/`learningListeningText`를 공용 순수 함수로 만들고 영어 글자 이름 요청은 대문자로 보낸다. 표시 문자와 획 데이터는 소문자로 유지한다. 원문과 대본이 같은 함수를 사용하며, 실제 VM의 mock TTS 요청 `A. Apple.` 및 언어/목표 모음·WAV 오류 6개 회귀 검사를 추가했다. 실제 TTS 엔진 발음 개선을 청취로 확인한 것은 아니다. Fox의 x가 끝소리라는 콘텐츠 주의점도 대본 검수 항목에 명시했다.

최종 확인/재개: 이전의 'PNG 등록 뒤 스토리 저장 사이 강제 종료 시 중복 제출' 제한은 위 pending 복구로 보강했다. SQLite의 실제 Android 프로세스 종료·전원 차단·파일시스템 영속성까지 호스트 결과로 보장하지 않는다. 기존 무료/오프라인 구성과 122학습·57과목 퀴즈·12화·120장면·55개 그림 퀴즈·배경 30장·효과음 3개를 유지한다. 이후 작업은 대본/필순/문항 교육 검수 → 녹음·음악 제작과 재생 연결 → 아동 사용성 피드백 반영이며, **실기기 설치·업데이트·TTS/효과음 청취·성능/메모리·강제 종료 검증은 사용자의 지시대로 마지막 단계**다. 먼저 `tool/test.ps1`, `dart run tool/export_voice_scripts.dart`, `dart run tool/audit_content.dart`로 재현한다. 이전 버전의 녹음 388개/테스트 242개/APK 기록은 아래 이력이며 최신 상태는 이 상단을 기준으로 한다.

최종 결과: `tool/test.ps1` **analyze 문제 0 / 전체 263개 통과**(기존 242 + 신규 21, 76초). `docs/recovery-test.log`. 별도 `docs/recovery-visual.log` 호스트 렌더 1개 통과 후 폰/낮은 가로/태블릿의 저장 재시도 화면 3장을 열어 확인했다(`docs/screenshots/garden-recovery-{phone,landscape,tablet}.png`). 캡처는 pending 상태를 제공한 UI fixture이며 실제 OS 강제 종료/실기기 캡처가 아니다. 폰에서 긴 안내가 부자연스럽게 나뉘어 짧은 문장으로 수정한 후 전체 테스트와 캡처를 다시 실행했다. `dart run tool/audit_content.dart` 오류 0, 대본 생성 609개/형식 오류 0/미제작 609. `--require-recordings`는 의도대로 종료 코드 1로 미제작을 알렸다(`docs/voice-required-audit.log`); 이를 통과로 기록하지 않는다.

최신 로컬 APK: `tool/android.ps1 build apk --release --build-number=214217696` 성공(50.2초, 종료 코드 0), **1.0.0 (214217696)**, **146,282,602 bytes / 139.5MiB**. 기존 키로 apksigner v2 검증 통과(종료 코드 0, 서명자 1), aapt 버전 확인. SHA256 `e39bb62d343e6652c61d9f8c93425524fb2743c36870ec4c9840fd6557302343`. 경로 `build/app/outputs/flutter-apk/app-release.apk`. 로그 `docs/recovery-build.log`, `docs/recovery-signature.log`, 메타데이터 `docs/recovery_build.json`. 기존 Kotlin 플러그인 마이그레이션/Cupertino 폰트 안내와 JDK native-access 경고는 유지되지만 빌드·서명 검증은 성공했다. 비공개 키를 재생성하거나 외부 전송하지 않았다. **Git HEAD `44995b7` 유지, 커밋·푸시·Release 생성·APK 업로드 없음.**

다음 구현 후보: 검수된 WAV를 넣었을 때 실제로 사용하는 녹음 재생/번들 연결과 TTS 대체·취소/음량/반복 계약, 필순/문항 검수 자료 보강. 실제 교육·청취 검수와 609개 녹음/배경음악 제작은 미완료다. 실기기 최종 검증 순서는 위 사용자 지시를 유지한다. 아래는 이전 단계의 이력이다.

## 이전: 6~12화 전체 사건·학습·결말 보강 (로컬 구현·검증 완료)

사용자 요청: 남은 화 모두 작업. 70개 기본 장면을 개별 사건으로 작성하고 기존 1~5화 및 저장 파일을 보존한다. 커밋/푸시/Release/APK 업로드 없음.

- [x] 6 다리·7 정원·8 바람·9 세 갈래·10 종이숲·11 별자리·12 도서관의 전용 시작/완료 그림 제작 및 장면 연결.
- [x] 70장면의 대사·개별 퀴즈·성공 피드백·만 2세 변형, 연령별 4/6/8/10 경로 및 기존 필기 ID 유지.
- [x] 돌/별 배치 조작과 저장, 7화 그림 도구·별도 초안, 9화 경로별 복습, 12화 선택 방과 결말 시각 반영.
- [x] 전체 연령/분기/도움/예전 저장·중단 복원·폰/태블릿·그림 저장 회귀 검사와 모든 새 리소스 감사.
- [x] 전체 analyze/test·화면 캡처·로컬 서명 APK 검증, 미검증 및 재개 기록 정리.

구현: `episode_six.dart`~`episode_twelve.dart`에 각각 10개 기본 장면을 개별 작성했다. 공용 `_Chapter` 생성기를 제거하고 1~12화 명시적 목록으로 연결했다. 기존 70개 장면 ID/순서/최소 단계, 필기 ID `n-3 / h-ㅗ(그림 단계의 기존 메타데이터) / e-C / h-ㅏ / e-A / n-2 / h-ㅜ`, 선택 플래그 `companion / route / room`을 유지해 예전 저장 위치를 보존한다.

| 화 | 최종 사건과 학습 |
|---|---|
| 6 | 세 돌을 끌기/터치로 다리판에 놓고 수량 선택. 3 필기, 하나 더/하나 덜, 다리 완성 그림 |
| 7 | 빨강/파랑 분류로 색 복원, 동그라미/세모 패턴·잎 분류. 6색·지우개·undo/redo·그림 지도 PNG 저장 |
| 8 | 휙휙의 사과와 협력, A/C와 1/3 바구니 구별·C 필기·책/별 패턴, 정리된 페이지 그림 |
| 9 | 한글/영어/숫자 선택마다 서로 다른 3문항(총 9), 경로별 듣기, 공통 ㅏ 빛길·길 합류 |
| 10 | 씨앗→싹→나무 성장 순서로 페이지 복원, A 필기·책 정리, 두 단계의 쉬운 순서 미션 |
| 11 | 별 5개를 배치하고 수량 선택, 2 필기·패턴·ㅏ/A/3 기억, 도서관으로 별길 점등 |
| 12 | 꽃/별 장식 분류, ㅜ 필기·A/a 재회·책 정리, 고른 방의 실제 결말 그림과 새 책 후일담 |

새 일반 그림 퀴즈 28종 + 만 2세 자유 탐색 7종(총 35), 성장 순서 지원 문항 1종 추가. `QuizArrangement`, 장면별 quiz/background/speech 변형을 도메인 데이터로 두며 선택·판정·전환은 StoryMachine, 저장과 그림 제출은 StoryVM/Repository가 담당한다. 6/11화는 모든 조각을 놓기 전 정답 버튼이 잠기고, 조작이 어려우면 즉시 쉬운 길을 선택할 수 있다. 중복 조각/범위 밖 인덱스/이미 지난 자리에 놓기/저장 실패는 진행시키지 않는다. 나머지 참고 그림 세기는 선택 전 필수가 아니다.

그림 저장: `story-garden-draft`를 자유 그림의 `drawing-draft`와 분리했다. 획을 떼고 저장된 초안부터 복원하며 기존 자유 그림/작품은 보존한다. 예전 버전에서 자유 그림과 공유하던 진행 중 정원 초안은 새 키로 자동 복사하지 않는다. PNG/작품 목록 저장 성공 후 스토리 성공을 저장하고 화면을 바꾼다. 동일 VM에서 스토리 저장 재시도 시 같은 그림을 중복 제출하지 않는다. PNG 저장과 스토리 저장 사이에 프로세스가 강제 종료되면 작품은 남고 미션은 다시 열릴 수 있으므로 이 두 저장의 완전한 트랜잭션을 보장하지 않는다.

시각 검증: 내장 imagegen으로 15장 제작(시작 7 + 같은 구도의 편집 8), 원본과 프로젝트 복사본 보존. 앱 배경은 총 30장(화별 26 + 공용 4), 기존 캐릭터 아틀라스 2장/효과음 3개 재사용. 정확한 제작 기록은 `docs/ARTWORK.md`, `docs/finale_story_prompts.json`. Flutter 호스트 캡처 24장을 열어 각 화 전후·9화 세 경로·12화 두 방·7화 그림 도구·폰/낮은 가로·만 2세 탐색을 확인했다. 9화 복습에 가/나 듣기가 남은 것을 발견해 목표 모음 '오' 듣기로 수정하고 별도 mock 회귀 검사를 추가했다. 낮은 가로 화면은 조작판/답/도움 영역을 스크롤한다. 실기기 화면이나 실제 소리 검증은 아니다.

검증 중 수정: 첫 analyze의 중괄호 lint, const 목록 인덱스 접근을 개별 const 음성 정의로 교체, 테스트 helper의 private 타입 lint를 수정했다. 성장 미션 복귀 테스트가 안내 문구까지 초기 스냅샷과 동일하다고 잘못 기대해 실패한 1건은, 실제 요구인 원래 문항/phase/지원 상태 복귀를 검사하도록 고쳤다(`docs/finale-growth-first-test.log`). 구현 오류를 테스트만 지워 숨기지 않았으며 새 정답 내용/오답/성공 검사는 유지한다. 중간 전체 215개 및 241개 통과, 신규 핵심 24개 집중 통과 후 최종 전체 검사를 다시 실행한다.

콘텐츠 감사: 122학습/57과목퀴즈/12화/120기본장면, 그림 스토리 퀴즈 55종(일반 43+만 2세 12, 지원 성장 그림 1종은 별도), 지원 문항 6개, 리소스/답/변형 참조 오류 0. 음성 버튼 C 이름·모음 오 및 새 문항 포함 **사전 녹음 388개 미제작**, TTS 대체 유지. 배경음악·프레임별 걷기/입모양·교육 전문가/아동 사용성·실기기 설치/음성/메모리 검증은 미완료다. 에뮬레이터 재확인: `emulator-5554 offline`, 초기화나 사용자 데이터 삭제를 하지 않았다.

다음 세션: 먼저 아래 최종 검사/빌드 기록을 확인하고 `tool/test.ps1`, `dart run tool/audit_content.dart`로 상태를 재현한다. 시즌 1의 미작성 에피소드는 이제 없으며, 다음 단계는 실제 Tab/S25와 교육·서사 검수, 388개 녹음/배경음악 제작, 사용성 결과에 따른 난이도 조정이다. 방 꾸미기는 꽃/별 완성 그림 선택이며 가구 자유 배치 편집기는 아니다. 전체 앱 출시 완성도를 측정한 백분율로 보고하지 않는다. **커밋/푸시/Release/APK 업로드는 사용자 명시 지시 때만 한다.**

최종 검증: `powershell -ExecutionPolicy Bypass -File tool/test.ps1` **analyze 문제 0 / 전체 242개 통과**(직전 173 + 신규 69, 68초). 2~12화 기본 퀴즈 각각 폰 360×780/780×360·태블릿 1280×800 × 글자 1/1.5배에서 오답·정답·실패 저장·복원을 검사한다. 신규 6~12화 전환/분기/그림/배치/음성 회귀도 통과했다. `docs/finale-test.log`, 집중 검사 `docs/finale-interaction-test.log`(24개), 최종 호스트 캡처 재생성 `docs/finale-visual.log`(1개) 참조. 전체 검사의 테스트 개수에 별도 캡처 검사를 중복 합산하지 않는다.

최신 로컬 APK: `tool/android.ps1 build apk --release --build-number=214215508` 성공(49.4초, 종료 코드 0), **1.0.0 (214215508)**, `build/app/outputs/flutter-apk/app-release.apk`, **146,266,134 bytes / 139.5MiB**. 기존 공유용 키로 v2 서명 검증 통과(종료 코드 0, 서명자 1), aapt 버전 확인. SHA256 `572379bbeaeddfcee4ad9376f42aa7ed7493cdda12f3686128751061a789d2c5`. APK 안의 배경 30장·아틀라스 2장·효과음 WAV 3개 포함을 ZIP 항목으로 확인했다. `docs/finale-build.log`, `docs/finale-signature.log`, `docs/finale_build.json`. 기존 Kotlin 플러그인 마이그레이션/사용하지 않는 Cupertino 폰트 안내, JDK native-access 경고는 남으나 빌드·서명은 성공했다. 기기 설치/업데이트/실제 재생·성능은 미검증이다.

**배포 상태: Git HEAD `44995b7` 유지. 이번과 직전 그림책 작업은 모두 로컬 변경이며 커밋·푸시·Release 생성·APK 업로드를 하지 않았다.** 아래는 이전 단계 이력이며 현재 상태는 이 최상단 기록을 기준으로 한다.

## 이전: 4·5화 소리 기차와 알파벳 등대 (로컬 구현·검증)

범위: 4·5화 개별 사건/학습 연출. 기존 로컬 작업 보존, 커밋·푸시·Release/APK 업로드 없음.

- [x] 기존 장면 ID/순서/연령 경로/필기 ID를 유지해 씨앗 싣기 → 글자 표지 → 꺼진 등대 → A 빛 연결.
- [x] 기차역 준비 전후·등대 점등 전후 배경 4장과 Flutter 글자 표지 제작/시각 확인/번들.
- [x] 가/나 조합과 순서, A/a·Apple 그림 카드, 만 2세 탐색 변형, 한국어/영어 듣기 버튼 연결.
- [x] 이전 저장·도움 경로·언어/음량/취소·폰/태블릿/글자 확대 회귀 테스트, 콘텐츠 감사.
- [x] 전체 analyze/test, 호스트 캡처, 로컬 서명 APK, 미검증 범위와 다음 작업 기록.

구현: `episode_four.dart`, `episode_five.dart`에 20개 기본 장면을 개별 작성했다. 3화 씨앗 → 기차의 가/나 표지 → 등대 도착 → A 찾기/필기 → A/a 짝 → Apple 사과 → 숫자 다리로 연결한다. 4화 필기 `h-ㄴ`, 5화 `e-A`, 모든 장면 ID/순서/최소 단계/동행 선택을 유지한다. 만 2세는 씨앗/꽃, 사과/별의 정답 없는 탐색과 별도 대사를 제공한다. 6~12화 생성 위치, 7화 그림, 9화 길 분기, 12화 결말은 유지한다.

음성: `StorySpeech` 데이터의 ID/라벨/텍스트/언어와 `StoryVM.listenTo`를 연결했다. 한국어 가·나, 영어 A 이름·Apple 단어의 네 샘플이며 각각 ko-KR/en-US로 기존 오프라인 TTS를 호출한다. 전체 Apple 단어를 재생하며 첫소리만 분리한 녹음 클립은 아니다. 일반 내레이션은 한국어로 유지한다. 필기 화면에서도 같은 듣기 버튼을 사용한다. 음량/반복 설정, 이전 요청 취소, 경로/백그라운드 중단, 음성 실패 안내를 재사용하며 재생으로 미션/듣기 진도를 완료 처리하지 않는다. 사전 녹음이나 실제 발음 검수가 끝난 것으로 보고하지 않는다.

아트: 최종 1536×1024 PNG 4장 `ep4-station.png`, `ep4-ready.png`, `ep5-dark.png`, `ep5-beam-v2.png`. 첫 점등 그림은 원경으로 바뀌어 채택하지 않고, 꺼진 등대를 참조 편집해 같은 구도에 빛만 켰다. 초기 `ep5-lit.png`는 소스로 보존하되 번들 제외. 생성/편집 프롬프트는 `docs/episode_train_lighthouse_prompts.json`, 경로/제작 범위는 `docs/ARTWORK.md`. Flutter 글자 가/나/A를 얹고, 두 기차 표지가 잘리거나 캐릭터에 가리지 않도록 초점과 캐릭터 크기를 조정했다. 기차 엔진 방향과 무관하게 학습 순서가 명확하도록 '왼쪽 가 → 오른쪽 나'라고 안내한다. 실제 운행/드래그/광원 물리 애니메이션은 아니며 저장된 성공 뒤 사건 그림 교체와 캐릭터 반응이다.

검증: **analyze 오류 0 / 전체 173개 통과**(`tool/test.ps1`, 61초, `docs/ep45-test.log`). 기존 149+추가 24: 데이터/저장/연령 5, 4·5화 3화면×글자 1/1.5배 조작 12, 음성 VM 4, 실제 듣기 버튼 3화면 위젯 3. 기존 2·3화 위젯 검증은 `story_chapter_widget_test.dart`로 이름을 바꾸어 4·5화까지 확장했다. 영어/한국어 선택, A/Apple 요청 분리, 무음, 음성 팩 부재, 연타·지연 재생 취소, 화면 이동 중단, 저장 실패·오답·도움/복원과 배경을 검사한다. 최초 음성 테스트 5건 실패는 Windows FlutterTts 채널의 String 인수를 Android Map으로 가정한 테스트 오류였다. 설치된 4.2.5 소스의 플랫폼 분기를 확인해 두 형태를 해석하게 고쳤고 음성 7개가 통과했다. 테스트 lint의 if 중괄호 누락도 수정 후 전체 재실행했다.

시각 확인: 호스트 캡처 테스트 1개 통과(`docs/ep45-visual.log`), `docs/screenshots/ep4-{station,ready}-tablet.png`, `ep4-order-landscape.png`, `ep5-{dark,lit,apple,explore}-tablet.png`, `ep5-speech-phone.png` 등 8개를 실제 글꼴로 열어 확인. Android 기기 캡처가 아니다. 짧은 폰 가로 화면은 별도 대사 영역 스크롤, 세로는 전체 스크롤을 사용한다.

감사: `dart run tool/audit_content.dart` 오류 0. 122학습/57과목퀴즈/12화/120기본장면 유지. 그림/글자 스토리 퀴즈 20종(일반 15+만 2세 탐색 5), 배경 15장/캐릭터 아틀라스 2장/효과음 3개, 별도 언어 듣기 샘플 4개 감사. 사전 녹음 **357개 미제작**(기존 대비 +6문항 ID/+4듣기 샘플 ID), TTS 대체 유지. `adb devices -l`의 `emulator-5554 offline` 재확인. 기기 실행/발음/오디오 청취/성능은 미검증이며 사용자의 실기기 검증 연기 지시를 유지한다. 새 패키지·서버·서명 키 생성 없음.

남은 작업/재개: 6화 숫자 다리에 돌을 세고 놓기, 7화 색깔을 잃은 정원의 분류/패턴/그림 사건을 다음 단계로 보강한다. 8~12화의 개별 사건 아트/문항도 남아 있다. 녹음 357개·배경음악·필순/발음/문항 전문가 검수, 아동 관찰, 실제 Tab/S25 설치/회전/저장/음성/메모리 테스트는 미완료다. 다음 세션은 `tool/test.ps1`와 `dart run tool/audit_content.dart`로 상태 확인 후 이어간다. Git 푸시와 APK 업로드는 명시적 요청 때만 수행한다.

로컬 APK: `tool/android.ps1 build apk --release --build-number=214211948` 성공(48.6초, 종료 코드 0). `build/app/outputs/flutter-apk/app-release.apk`, **1.0.0 (214211948)**, **100,443,104 bytes(95.8MiB)**. 기존 공유용 키의 apksigner v2 서명 검증 통과(종료 코드 0, 서명자 1), aapt 버전 확인. SHA256 `beccdcff450cb2ac617443fe4634dfb165057fc1f1785711989a728869adfd9f`. 배경 15장·캐릭터 아틀라스 2장·비압축 WAV 3개 포함 및 미채택 원경 `ep5-lit.png` 미포함을 확인했다. 직전보다 약 10.9MiB 증가. 빌드/검증 로그 `docs/ep45-build.log`, `docs/ep45-signature.log`. 기존 Kotlin 마이그레이션/Cupertino 폰트/JDK native-access 경고는 빌드·서명 검증을 막지 않으나 SDK 변경 전에 점검한다. 실제 저사양 태블릿 성능/메모리는 미검증이다.

**배포: Git HEAD `44995b7` 유지. 모든 변경은 로컬 작업 파일이며 커밋·푸시·Release 생성·APK 업로드 없음.**

## 다음 품질 단계 — 2·3화 꽃문과 자음 열매 (로컬 구현·검증)

범위: 2화와 3화의 개별 사건/학습 연출. 기존 미커밋 작업 보존. Git 푸시·커밋·APK 업로드 없음.

- [x] 기존 10개 장면 ID/순서/최소 단계/필기 ID를 유지하며 2·3화 전용 대사·미션·성공 피드백 분리.
- [x] 닫힌 꽃문/열린 꽃길, 자음 나무/씨앗 바구니 배경 제작·시각 확인·번들.
- [x] 한글 그림 카드, 만 2세 탐색 변형, 퀴즈 성공 뒤 그림 변화 및 도움 경로 연결.
- [x] 4연령×12화 완주·이전 저장·폰 가로/세로·태블릿·글자 확대 회귀 테스트, 콘텐츠 감사.
- [x] 전체 analyze/test, 호스트 캡처, 로컬 서명 APK와 실제 기기 미검증/다음 작업 기록.

구현: `episode_two.dart`, `episode_three.dart`로 20개 기본 장면을 개별 작성했다. 2화는 아 소리로 꽃문 열기 → ㅏ 필기 → 오 찾기 → 아·오 짝 → 자음 나무로 연결한다. 3화는 기역 이름표 → 씨앗 꾸러미 → ㄱ 필기 → 씨앗 세기 → 앞 화의 ㅏ와 ㄱ으로 가 만들기 → 기차에 싣기로 이어진다. 기존 필기 ID `h-ㅏ`/`h-ㄱ`, 4·6·8·10 연령별 장면 수, 동행 선택/도움/이어하기 위치는 유지한다. 4~12화 생성 인덱스와 9화 길 분기는 바꾸지 않았다.

모델/상태: `QuizGlyph`에 한글 기호와 음가/이름을 분리하고 꽃/잎/씨앗 도형을 추가했다. `QuizArtwork.objectName`으로 별/씨앗의 중복 터치 방지·저장 로직을 재사용한다. `StoryScene.exploreQuiz/exploreText/exploreSuccessText`를 데이터로 선택해 만 2세는 글자 정답 없이 꽃/잎/씨앗을 탐색하고 대사도 맞춘다. 1화의 예외 코드를 같은 경로로 합쳤다. `successBackground`와 `StoryMachine.background`는 성공 상태에서만 완료 그림을 돌려준다. 저장 실패·오답에는 배경이 그대로이며 도움 통과로도 이야기를 이어갈 수 있다. 자동/수동 읽기는 같은 `narration` 규칙을 써 성공 후 이전 안내를 다시 읽던 문제를 고쳤다. UI가 정답·저장 결과를 판단하지 않는다.

아트: 내장 imagegen 기존 그림 참조 생성, 1536×1024 PNG 4장. `assets/story/ep2-{gate,open}.png`, `ep3-{tree,seeds}.png`. 프롬프트/참조/경로 `docs/episode_garden_tree_prompts.json`, 제작 기록 `docs/ARTWORK.md`. 배경의 이름표는 빈 상태로 만들고 Flutter TextPainter로 실제 한글을 얹었다. 배경과 동일한 cover 크롭/정렬을 써 가로세로에서 같이 이동한다. 열린 문과 열매 이름표의 위치를 캡처로 보고 수정했다. 문짝 회전/열매 드래그를 구현했다고 보고하지 않으며, 저장 후 그림 전환과 기존 캐릭터 반응을 사용한다.

회귀: 신규 도메인 5개 + 위젯 12개. 2화/3화 각각 360×780·780×360·1280×800 및 글자 1/1.5배에서 호스트 포인터 조작·오답·정답·저장 실패·성공 배경·재로딩을 검증한다. 4연령의 모든 예전 장면 위치/동행 선택/시도 복원, 한글 정답/그림 선택지 유일성·만 2세 대사·씨앗 개수 저장을 검사한다. 초기 이름표 캡처 빌드의 FittedSizes 접근자 오류는 설치된 Flutter SDK 소스에서 `.source`/`.destination`을 확인해 수정했고, 캡처 도구의 설정 Provider import 누락도 고쳤다. 이후 호스트 캡처 테스트 통과. 최종 전체 결과·APK는 이어 기록한다.

남은 작업/재개: 4화 뒤죽박죽 소리 기차의 소리·표지·씨앗 연결, 5화 알파벳 등대의 A 이름/Apple 단어 구분을 다음 개별 사건 연출 대상으로 삼는다. 이후 6~12화도 공용 배경·일반 문항을 보강해야 한다. 녹음·배경음악·교육/필순/발음 전문가 검수와 아동 관찰은 미완료다. 실제 Galaxy Tab/S25 검증은 사용자 요청대로 후속이며, 연결되지 않은 에뮬레이터는 임의 초기화하지 않는다. 사용자 요청 전 Git 푸시/APK 업로드 금지를 유지한다. 다음 세션은 `tool/test.ps1`와 `dart run tool/audit_content.dart`로 현재 상태를 확인하고 위 작업부터 이어간다.

최종 자동 검증: `tool/test.ps1` **analyze 오류 0 / 전체 149개 통과**(기존 132+신규 17, 54초). 만 2세 대사와 성공 후 수동 다시 듣기 수정 후 전체를 재실행했다. `docs/ep23-test.log`. 별도 호스트 캡처 테스트 1개 통과(`docs/ep23-visual.log`), 태블릿·폰 가로/세로 및 만 2세 변형 포함 7개 화면을 저장하고 실제 글꼴로 열어 확인했다. `docs/screenshots/ep2-{gate,open,explore}-tablet.png`, `ep3-{tree,ga}-tablet.png`, `ep3-count-phone.png`, `ep3-ga-landscape.png`. Android 실기기 캡처가 아니다.

콘텐츠 감사: `dart run tool/audit_content.dart` 오류 0. 122학습/57과목퀴즈/12화/120기본장면 유지, 스토리 그림 퀴즈 **12종(일반 9 + 만 2세 변형 3)**. 11개 배경/2개 캐릭터 아틀라스/3개 효과음 및 성공 그림·탐색 문제도 감사한다. 사전 녹음 **347개 미제작**(직전보다 감사 ID 순증 6), TTS 대체 유지. `adb devices -l` 재확인에서 `emulator-5554 offline`; 실행·기기 청취·성능·새 설치 검증은 하지 못했다. 새 패키지·서명 키·외부 서버 도입 없음.

최종 로컬 APK: `tool/android.ps1 build apk --release --build-number=214210578` 성공(47.0초, 종료 코드 0). `build/app/outputs/flutter-apk/app-release.apk`, **1.0.0 (214210578)**, **88,999,317 bytes(84.9MiB)**. 기존 공유용 키의 apksigner v2 서명 검증 통과(종료 코드 0, 서명자 1), aapt로 버전 확인. SHA256 `ea119697220e59098eeecbb66e5f488475db4c7631e7a9942247f2781698ccbf`. APK 내 배경 11장·캐릭터 아틀라스 2장·비압축 WAV 3개 포함 확인. `docs/ep23-build.log`, `docs/ep23-signature.log`. 기존 Kotlin 마이그레이션/Cupertino 폰트/JDK native-access 경고는 빌드·검증을 막지 않으며 다음 SDK 변경 전에 점검한다. APK 용량은 새 PNG 4장으로 직전보다 약 12.4MiB 증가했고, 저사양 태블릿의 메모리/성능 확인은 미완료다.

**배포 상태: HEAD `44995b7` 그대로. 이번 및 이전 그림책 변경은 로컬 작업 파일이며 커밋·푸시·Release 생성·APK 업로드를 하지 않았다.**

## 다음 품질 단계 — 1화 장면별 사건·그림·퀴즈 (로컬 구현·검증)

사용자 승인 범위: 직전 보고의 다음 단계인 1화 품질 보강. 기존 로컬 작업 파일을 보존하고 Git 커밋/푸시·APK 업로드는 하지 않는다.

- [x] 1화 10개 기본 장면의 대사·행동·학습을 별빛 찾기 사건으로 연결. 기존 장면 ID/4·6·8·10 연령별 경로와 저장 호환 유지.
- [x] 도서관 시작/별조각 탐색/지도 발견 전용 배경, 찾기/가리키기 캐릭터 포즈 제작·번들·시각 확인.
- [x] 별 모양 매칭·1~3개 세기·같은 별 짝 찾기를 그림 선택 카드로 구현. 세기 터치 진행을 VM/State Machine/Repository로 저장하고 힌트·대체·도움 경로 유지.
- [x] 장면/퀴즈/포즈 참조와 정답·연령별 완주·이전 저장 복원·중복 터치·폰/태블릿 회귀 검증.
- [x] analyze/test·호스트 렌더·로컬 서명 APK, 실제 기기 미검증 및 후속 작업 기록.

구현: `story/data/episode_one.dart`에 전용 대사/성공 피드백/그림 퀴즈를 분리했다. 그림 퀴즈는 별 모양, 3개 세기, 같은 별 짝 3종이며 만 2세용 자유 선택 1종을 별도로 제공한다. 만 2세는 어떤 모양을 골라도 탐색 성공이며 오답을 정답이라고 가르치는 문구를 쓰지 않는다. 장식 별 때문에 세기 정답이 모호해지지 않도록 '작은 판 위' 별만 세라고 안내한다. 숫자 1 필기와 장면 ID·순서는 유지했다. 다른 11화의 생성 인덱스/연령별 경로는 바꾸지 않았다.

상태: `StorySnapshot.observedObjects`에 누른 순서를 저장한다. 중복/범위 밖 터치는 세지 않고, 저장 성공 뒤에만 개수/효과음/읽기 반응을 낸다. 세기만으로 자동 통과하지 않으며 그림 답 선택을 제공한다. 세기를 모두 누르지 않아도 답 선택은 가능하다. 오답 후 세기 유지, 쉬운 경로/장면 이동 시 초기화, 예전 저장의 필드 부재와 유효하지 않은 인덱스 정리를 검사한다. 새 패키지·서버·유료 서비스·서명 키 생성 없음.

시각 확인: 내장 imagegen 편집으로 1536×1024 배경 3장과 1280×1280 탐색 포즈 아틀라스 1장 추가. 최초 시트의 칸 넘침을 호스트 렌더에서 발견해 여백을 늘려 재편집했고, 중앙 띠의 불투명 픽셀 회귀 검사를 추가했다. 배경 없는 초기 캡처는 테스트의 원본/리사이즈 이미지 캐시 키가 달라 생겼으며, 실제 Image.asset과 같은 ResizeImage로 디코딩을 기다린 뒤 다시 캡처했다. 실제 화면 파일 `docs/screenshots/ep1-{start,shape,count,map}-tablet.png`, `ep1-count-phone.png`, `ep1-count-landscape.png`. 이는 Android 실기기 캡처가 아닌 Flutter 호스트 렌더다. 프롬프트/경로/범위는 `docs/ARTWORK.md`, `docs/episode_one_prompts.json`, `docs/episode_one_atlas_fix_prompt.json`.

검증: `episode_one_test.dart` 4개 + `episode_one_widget_test.dart` 6개를 추가했다. 폰 360×780/780×360 및 태블릿 1280×800 각각 글자 1/1.5배로 실제 터치·중복 터치·오답·정답을 검사한다. 낮은 가로 화면 최초 실패 2건은 지연 생성 목록을 스크롤하기 전 찾은 테스트 문제였으며, 세로 Scrollable을 지정해 퀴즈까지 실제 스크롤한 뒤 조작하도록 고쳤다. 별도 렌더/에셋 집중 검증 3개 통과(`docs/ep1-visual.log`). 최종 전체 결과와 APK 메타데이터는 아래에 이어 기록한다.

콘텐츠 감사: `dart run tool/audit_content.dart` 오류 0. 122학습/57과목퀴즈/12화/120기본장면 유지, 그림 스토리 퀴즈 4종(만 2세 변형 포함). 새 리소스·그림 선택지 참조 검사. 사전 녹음은 **341개 미제작**(새 스토리 문항으로 감사 대상 순증 3), TTS 대체 유지. 모든 대사/효과음의 실제 청취와 교육 검수는 완료하지 않았다.

남은 작업/재개: 2화 모음 꽃밭의 문과 3화 자음 열매를 다음 사건 연출 대상으로 삼아, 공용 배경·퀴즈 재사용을 개별 그림/행동/대사로 보강한다. 4~12화도 같은 방식으로 이어야 한다. 녹음 341개·배경음악·프레임별 걷기/입모양, 교육 전문가/아동 사용성 검수는 미완료다. 실기기 검증은 사용자 요청대로 후속이며 ADB 에뮬레이터는 직전 확인에서 offline. 연결되면 `docs/DEVICE_VALIDATION.md` 기준으로 TTS/효과음 음량·백그라운드·회전·필기·설치/업데이트를 확인한다. 전체 앱 진행률은 측정된 백분율이 없고 이번 테스트 증가만으로 상향하지 않는다. Git 커밋/푸시 및 APK 업로드는 사용자가 명시적으로 요청할 때만 한다.

최종 검증: `powershell -ExecutionPolicy Bypass -File tool/test.ps1` **analyze 오류 0 / 전체 132개 통과**(기존 122+신규 10, 48초). 에셋 칸 경계 수정 뒤 전체를 다시 실행했다. `docs/ep1-test.log`에 실제 실행 로그, `docs/ep1-visual.log`에 렌더/에셋 집중 검증 3개 통과 기록. `adb devices -l` 재확인 결과 `emulator-5554 offline`이며 실행 검증을 하지 못했다.

로컬 APK: `tool/android.ps1 build apk --release --build-number=214209188` 성공(49.4초, 종료 코드 0). `build/app/outputs/flutter-apk/app-release.apk`, **1.0.0 (214209188)**, **76,018,944 bytes(72.5MiB)**. aapt로 버전 확인, 기존 공유용 키의 apksigner v2 서명 검증 통과(종료 코드 0, 서명자 1). SHA256 `d99c845d93afd65db3873919536a4d15264af5a10a73d64714ee95fa95070a10`. APK 안의 배경 7장·캐릭터 아틀라스 2장·비압축 WAV 3개 포함 확인. 빌드/서명 로그 `docs/ep1-build.log`, `docs/ep1-signature.log`. 기존 Kotlin 플러그인 마이그레이션/사용하지 않는 Cupertino 폰트 안내와 JDK native-access 경고는 남아 있으나 빌드·서명 검증은 성공했다. 실제 설치·소리·프레임 확인과 구분한다.

**배포 상태: Git HEAD는 `44995b7` 그대로이며 이번 및 직전 그림책 변경은 로컬 작업 파일이다. 커밋·푸시·Release 생성·APK 업로드를 하지 않았다.** 다음 세션은 위의 남은 작업부터 이어가고 먼저 `tool/test.ps1` 및 `dart run tool/audit_content.dart`로 상태를 확인한다.

## 그림책 페이지·캐릭터 움직임·효과음 (로컬 구현·자동 검증 반영)

사용자 요청: 페이지를 넘기며 캐릭터가 움직이고 짧은 효과음이 나는 그림책. 현 단계는 지속적 물리/충돌이 없으므로 Flutter AnimationController/Transform 및 Android 기본 오디오를 사용하고 Flame 의존성은 추가하지 않는다. **사용자 최신 지시: Git 푸시와 APK 업로드는 명시적으로 요청할 때만 수행. 이번 작업은 로컬 개발·테스트·빌드까지.**

- [x] 기존 삽화에서 배경/투명 캐릭터 레이어 분리, 일관된 그림체 유지 및 실제 PNG 검사.
- [x] 페이지 넘김 연출, 캐릭터 등장/대사 반응/성공 반응, 애니메이션 끄기·화면 비활성 중단.
- [x] 오프라인 페이지 넘김/친구 반응/성공 효과음 제작·번들·재생, 효과음 음량/중단/중복 방지.
- [x] 저장 성공 후 전환에만 연출 연결, 퀴즈/필기 미션 건너뛰기 방지, 재개 시 보상 재생 방지.
- [x] 회귀 테스트·화면 캡처·analyze/test 및 로컬 Android 릴리스 빌드, 미검증 범위 기록.

실제 구현: 배경 네 장에서 캐릭터를 제거한 신규 PNG와 2×2 투명 캐릭터 아틀라스 제작·각 출력 시각 확인. 원본 보존, 새 파일만 앱 번들. 캐릭터마다 독립 위치/회전/크기 및 입장/인사/성공 동작, 오른쪽 친구 방향 반전. 자동 반복 없는 1.2초 동작과 650ms 책장 원근/그림자/전환. 사용자/시스템 애니메이션 끄기와 백그라운드 TickerMode 연결. 학습 완료 전 그림 스와이프 진행 차단, 지나간 페이지는 접근성·입력에서 제외. 폰과 낮은 화면은 대사 스크롤 막대로 안내. 정적 그림을 움직이는 방식이며 프레임별 걷기/입모양을 구현했다고 보고하지 않는다.

효과음: 자체 Dart PCM 합성 도구와 3개 실제 WAV(0.28/0.36/0.66초), 독립 효과음 음량과 부모 미리 듣기. Android SoundPool/USAGE_GAME, 한 스트림만 재생·지연 로드 취소·onPause 차단·엔진 정리. Dart 서비스는 연타 300ms 억제, 재생 거부/시간 초과 진단, 화면 이동·일시 중지 시 취소. 전환 사운드는 버튼 탭이 아니라 저장된 StorySnapshot 전이에서 결정. 첫 진입/이어하기와 동일 상태에는 보상음을 내지 않는다. 기존 학습 성공 진동과 TTS는 유지하고 음악은 미제작 상태.

검증: `tool/test.ps1` **analyze 오류 0 / 전체 122개 통과**(기존 113+신규 9, 약 43초). 2화면에서 실제 인사/저장 실패/페이지 넘김/친구 선택/퀴즈 스와이프 차단, 전환 중 중복 입력/애니메이션 끄기, 무음/백그라운드/지연 재생 취소/네이티브 거부, PCM 포맷·길이·피크·페이드, 아틀라스 4칸의 투명/인물 픽셀 검사 포함. 중간에 stop/dispose의 시간 초과 타이머가 테스트에 남던 문제는 중단 요청을 비동기 전송만 하도록 수정. 폰 테스트의 동적 목록 스크롤 좌표는 레이아웃 갱신 후 실제 Scrollable.ensureVisible로 안정화.

`dart run tool/audit_content.dart` 오류 0, 122학습·12화·120장면 유지, 배경/아틀라스/효과음 참조 검사 추가. 사전 녹음 338개·배경음악 미제작 유지. Android 에뮬레이터 `emulator-5554`는 ADB offline(실행 검증 불가). 실기기 청취·터치·프레임/메모리는 사용자 요청대로 후속. 실제 효과음 재생을 mock 결과만으로 확인했다고 보고하지 않는다. 테스트 로그 `docs/picturebook-test.log`, 초기 실패/수정 확인 `docs/picturebook-focused.log`, 시각 확인 `docs/picturebook-visual.log`는 로컬에 보관한다.

제작 정보: `docs/ARTWORK.md`, 정확한 내장 imagegen 프롬프트 `docs/story_motion_prompts.json`. 호스트 렌더 캡처 `docs/screenshots/motion-story-tablet.png`, `motion-story-phone.png`. 로컬 APK 빌드 결과는 아래에 이어 기록한다. **이번 작업은 커밋/푸시/Release 생성/업로드를 수행하지 않는다.**

최종 시각 수정: 페이지 넘김 중간 프레임에서 교차 투명도/과한 원근으로 글자가 커 보이던 현상을 발견해, 새 페이지 위에서 불투명한 이전 종이만 접히는 방식으로 수정. `docs/screenshots/book-page-turn.png`, `book-character-motion.png`를 재확인. 수정 후 analyze 오류 0 / 전체 **122개 재통과**(약 45초), 별도 캡처 테스트 통과. 이후 코드 변경 없음.

로컬 최종 APK: `tool/android.ps1 build apk --release --build-number=214205681` 성공(44.5초, 종료 코드 0). Android 신규 Kotlin 오디오 코드 컴파일 포함. 버전 `1.0.0 (214205681)`, `build/app/outputs/flutter-apk/app-release.apk`, **67,400,744 bytes(64.3MiB)**. 기존 공유용 키 apksigner v2 검증 통과(종료 코드 0), SHA256 `9ae076ee0306fde5cc61dd033268e33dab6c2d804214b0b50c037c1e230d61da`. APK 내부 신규 배경 4장·아틀라스·WAV 3개 포함과 WAV 비압축 저장 확인. 로그 `docs/picturebook-build.log`, `docs/picturebook-signature.log`.

기존 Built-in Kotlin 이전 안내 및 사용하지 않는 Cupertino 폰트 경고는 빌드를 막지 않았고 분석 오류는 없다. 변경은 기존 HEAD `44995b7` 위의 **로컬 작업 파일**로 보존되며 커밋·Git 푸시·APK 업로드 없음. 다음 검증은 연결 가능한 Android에서 효과음/음량/백그라운드 중단과 페이지·캐릭터 프레임을 확인하는 것. 다음 제작은 관절/프레임별 표정·걷기와 개별 장면 사건 삽화이며, 지속적 물리/충돌이 실제 필요해질 때 Flame을 재검토한다.

## 사용자 품질 피드백 — 필기 판정·그림책 UI 1차 보강 반영

사용자가 실제로 대충 문질러도 필기를 통과하며 화면과 스토리 아트가 투박하다고 보고했다. 기존 자동 테스트로 실제 학습 품질을 충분히 확인하지 못한 한계를 기록하고, 콘텐츠 수 확대보다 다음 품질 작업을 우선한다. 직전 TTS 무음 보고는 Android 메타데이터 해석 오류를 찾아 수정했으며 기기 재생 확인은 남아 있다.

- [x] 무작위 낙서/왕복 문지르기/작은 점/곡선 지름길/짧은 글자 자동 통과 재현 테스트 및 순차 경로 판정 보강. 2~3세 탐색 허용과 4~5세 방향 기준은 유지하되 의미 없는 입력은 완료로 취급하지 않는다.
- [x] imagegen 스킬로 따뜻한 그림책 삽화 제작·프로젝트 에셋 연결. 스토리 그림/대사/선택 버튼/장면 진행을 하나의 이야기 화면으로 재구성.
- [x] 필기 캔버스와 홈의 색/타이포/터치 피드백 일관화. 폰/태블릿에서 실제 렌더 캡처를 보고 수정.
- [x] TTS 현재 설치 패키지 Android 구현과 음성 선택 조건 확인, 확인된 원인 수정 및 진단/미검증 구분.
- [x] adversarial 판정/스토리 흐름/반응형/오디오 회귀, 최종 테스트·서명 APK·GitHub 배포.

모델 변경으로 품질 문제를 해결했다고 주장하지 않으며 현재 세션의 모델/추론 설정을 임의 변경하지 않는다. 모델 조언은 공식 OpenAI 문서와 구분하고 실제 구현·시각 검증을 우선한다.

### 이번 구현과 검증 근거

- 필기: 기존의 순서 없는 근접 점수만으로 통과하던 판정을 이동 거리 기반 80구간 순차 비교로 교체. 획 길이에 비례한 허용 오차, 시작/끝, 최소/최대 길이를 함께 검사. 2~3세는 역방향 전체 경로 허용. 짧은 획에서 이벤트 흔들림이 길이를 부풀리지 않도록 작은 잡음은 정리하되 실제 왕복 전환점은 보존. `StrokePath.samples` 끝점 부동소수 오차와 포인터 up 마지막 좌표 누락도 수정.
- 새 회귀: 전체 경로×4연령에서 반복 왕복/짧은 조각/고정 시드 무작위 낙서 거부, 곡선 지름길 및 적당한 길이의 역주행 거부. 정상 경로·소량 손 떨림·어린 연령 역방향은 허용. 과도한 필터가 왕복까지 지우거나 정상 짧은 획을 거부한 중간 실패를 수정해 필기 전용 25개 테스트 통과. 빠른 속도 자체는 오답 기준이 아니며 올바른 전체 경로는 빠르게 그려도 통과할 수 있음.
- 스토리: 벡터 도형 배경을 실제 번들 PNG 네 장으로 교체. 화자 표시, 종이색 대사 패널, 목표/장면 진행, 피드백 카드, 폰 세로/넓은 화면 분할. 홈 일러스트 배너·파스텔 카드·Jua 글꼴 및 필기 연습장/번호/도착점 추가. 모든 배경 ID와 번들 PNG 디코딩 검사. 네 장 공유·분리 캐릭터/장면별 연출 미완료는 `docs/ARTWORK.md`에 명시.
- TTS: 설치된 flutter_tts 4.2.5 Android Kotlin `readVoiceProperties`의 `network_required`는 `'0'`/`'1'`. 기존 false/`'false'` 전용 필터가 정상 오프라인 음성까지 거부한 원인 확인. `'0'`/0 허용, `'1'` 거부 회귀 추가. 실제 기기 소리·언어팩·발음 확인 완료로 보고하지 않음.
- 시각 확인: 호스트에서 1280×800 스토리/홈/필기, 360×780 및 780×360 스토리를 렌더해 눈으로 확인. 저장된 대표 캡처 `docs/screenshots/`. 폰 가로에서는 대사 패널 내부 스크롤, 세로에서는 전체 스크롤. 실기기 검증은 사용자 요청대로 후속.
- 콘텐츠 감사: 122학습/12화·120장면/참조 오류 0. 실제 녹음 338개 미제작, TTS 대안 유지. 기존 서명 키 보존, 새 서버·패키지·유료 서비스 없음.

최종 호스트 검증: `tool/test.ps1` analyze 오류 0 / 전체 **113개 통과**(약 45초), `dart run tool/audit_content.dart` 콘텐츠 오류 0. 로그 `docs/quality-test.log`, `docs/trace-quality.log`, `docs/visual-quality.log`는 로컬 실행 기록이며 Git에서 제외된다. APK 배포 결과는 아래에 기록한다. 다음 품질 단계는 장면별 사건 삽화·분리 캐릭터 표정/위치 연출, 퀴즈 그림의 통일, 기기에서 필기 난이도와 TTS 재검증이다.

### 공유 APK 배포 결과

- 소스 커밋 `3edcc28`을 main에 push. `tool/publish-apk.ps1` 배포 직전 analyze 오류 0 / 113개 테스트 재통과, release APK 빌드 성공, 기존 키의 apksigner v2 검증 통과(종료 코드 0). 로그 `docs/quality-publish.log`.
- 버전 `1.0.0 (214204016)`, APK 65,952,648 bytes(약 62.9MiB). 삽화 네 장·Jua 글꼴·OFL 라이선스가 APK ZIP 내부에 실제 포함됐는지도 확인.
- [GitHub Release](https://github.com/duafyd/kkoma_learning/releases/tag/apk-1.0.0-214204016) / [서명 APK 다운로드](https://github.com/duafyd/kkoma_learning/releases/download/apk-1.0.0-214204016/kkoma-1.0.0-214204016.apk).
- SHA256 `3769930a9fd977f2fc3f389197d53f9487cbc1fe9cb99b8c67428673aeeab8c4`. 공개 Release API의 draft=false, 자산 크기/해시와 로컬 산출물 일치 확인. 개인 키/비밀번호는 Git에 포함하지 않음.
- 실제 Android 새 설치·업데이트·손가락 난이도·TTS 청취·성능은 사용자 요청대로 후속 검증. 이 배포를 전체 명세/교육 검수 완료로 보고하지 않음.

## 큰 후속 단계 — 스토리 대체 미션·수학 조작 활동

실기기 검증은 사용자 요청으로 나중에 진행하고 아래 개발을 계속한다.
- [x] 이야기 퀴즈/필기에서 실제 쉬운 그림·글자 매칭으로 전환, 원래 미션 복귀, 저장·재개 및 장면 전이 검증.
- [x] 수량 드래그 매칭과 터치 선택 대안, 크기/색/도형 분류의 독립 활동·연령별 경로.
- [x] 활동 진도/중단 후 복원, 힌트·도움·사용 시간·저장 실패/빠른 입력 회귀 검증.
- [x] 휴대폰/태블릿·확대 글자·드래그 테스트, 전체 analyze/test, 문서/콘텐츠 감사, 동일 키 APK 배포.

새 서버·유료 서비스·패키지·키 생성 없이 기존 Riverpod/Repository 및 Flutter DragTarget을 사용한다. 실제 기기/교육 검수·음원 제작 완료로 보고하지 않는다.

구현: `/math/match` 짝꿍 바구니를 숫자 탐험대 상단에 연결. 수량/크기/색/도형 4유형×변형/반복 3회=학습 단계별 12라운드(4단계 총 48경로), 서로 다른 48개 개념이라는 의미는 아님. 2~3세 바구니 2개, 4~5세 3개. 직접 그린 원/별/도형으로 크기·색·수량을 보여 주며 드래그와 선택→바구니 터치를 모두 지원. 선택/배치/시도/힌트/도움 상태 저장. 연령별 수량 제한, 자동/수동 읽기, 사용 시간 경계, 부모 진도 초기화 포함. 넓은 화면에서 카드/바구니 좌우 배치, 항상 보이는 스크롤 막대 적용.

수학 상태/판정은 SortingRules, 저장은 SortingRepository, 입력/저장 조율은 SortingVM으로 분리. 저장 성공 전 화면 진행 없음. 중복 입력/저장 실패 재시도 보호. 완료 배지는 다음 놀이/완료 후 유형 전환 때 completeOnce로 기록하여 다음 상태 저장 실패 후 재시도해도 중복되지 않음. 배치 및 오답 시도 수를 첫 완료 배지 기록에 포함. 첫 완료 뒤 재연습은 별도 완료 수를 추가하지 않음.

스토리: supportSceneId nullable 필드로 이전 저장과 호환. 퀴즈/필기에서 공통 목적별 지원 문항 5개 또는 해당 필기 글자 매칭으로 전환, 원래 미션 복귀, 같은 이야기 장면의 성공 후 정상 이동. 장면 이동/에피소드 이동 때 지원 상태 해제. 필기에서 전환할 때 부분 획은 지우며 원래 미션으로 복귀 시 다시 그리기. 대체 문제 정답을 직접 고른 것은 도움 자동 통과로 기록하지 않음. 도움 자동 통과는 기존 설정/시도 횟수를 준수.

검증: analyze 문제 0 / 전체 **98개 통과**(이전 79 + 신규 19, 약 38초), `docs/large-stage-test.log`. Sorting 4연령 완주·오답/힌트/도움·불법 입력/손상 저장·재시작·저장 지연/실패/리셋 경합·중복 배지·초기화, 스토리 대체 경로 4연령×12화 완주/9화 3길/재개/복귀/도움 금지, 실제 드래그와 터치 매칭 3화면×2글자크기×4유형 테스트 포함. 기존 휴대폰 테스트에 스토리 필기→대체 퀴즈→원래 필기 왕복 추가. 전체 화면 6크기×2글자크기에 새 화면 포함.

중간에 발생한 한 줄 if lint는 중괄호로 정리. 제스처 테스트에서 지연 생성 목록/가로 AppBar 스크롤을 잘못 선택하던 문제를 세로 스크롤 영역과 빈 가장자리 스와이프로 수정. 실제 드래그가 스크롤을 잡는 영역은 스크롤 막대/반응형 보드/터치 대안으로 보강. 수정 후 실제 6개 드래그 테스트와 2개 휴대폰 활동 테스트 모두 통과. 로컬 임시 PNG 화면 검토 1개 통과 및 시각 점검(호스트 대체 글꼴이므로 실기기 폰트/아이콘 검증과 구분).

콘텐츠 감사 오류 0. 기존 122학습/122필기/57학습 퀴즈/12화120장면 유지, 별도 정적 스토리 지원 문항 5개와 필기 지원 및 단계별 분류 12라운드 검사 추가. 누락 녹음 **338파일**: 신규 문항 외에도 과거 감사에서 빠졌던 스토리 내장 문항까지 검사 범위를 확장한 결과. 효과음/배경음악은 계속 미제작, TTS 대안 유지. 최종 배포 검증은 아래에 기록한다.

최종 배포: `tool/publish-apk.ps1`에서 **analyze 문제 0 / 98개 모두 통과 / 서명 APK 빌드 및 apksigner v2 통과 / main push / Releases 업로드·공개 완료**. 로그 `docs/large-stage-publish.log`. source commit `dd2c260`, versionCode **214192067**, 기존 공유용 키 유지. 공개 API에서 draft=false 및 서버 SHA256 `bae33c27f78b359e081356504004483cc0db81a47c75877fd9884a25ff211b63` 일치 확인.

APK: https://github.com/duafyd/kkoma_learning/releases/download/apk-1.0.0-214192067/kkoma-1.0.0-214192067.apk

남은 개발: 구체물 연산 조작과 스토리 장면별 학습 활동 연계 확대, 실제 녹음/효과음/음악 제작 및 재생 파이프라인. 선 긋기 매칭은 아직 없으며 이번 것은 드래그/터치 매칭이다. 교육·발음/필순 검수와 S25/Tab 실기기 설치·성능 검증은 미완료, 사용자가 실기기는 나중에 진행하기로 했으므로 이를 개발 중단 사유로 삼지 않는다. 새 활동은 숫자 탐험대 상단 '짝꿍 바구니'에서 진입한다. 다음 세션은 현재 요구사항 대조표와 이 기록을 읽고 소규모 기능 단위로 검증을 이어갈 것.

## 다음 콘텐츠 단계 — 낱말 필기·수학

사용자 지시에 따라 실기기 테스트는 나중으로 보류하고 개발을 계속한다. Galaxy S25/Tab 실기기 미검증은 해소된 것으로 처리하지 않는다.

- [x] 기존 ID·획 경로를 유지하며 추가 음절과 사과/나무 등 낱말 필기 지원.
- [x] 같은 수량 찾기·분류·패턴·10 이하 구체물 연산 문항 보강.
- [x] 새 경로 4연령 판정·낱말 중간 저장/순서·문항 정답 유일성/수량 회귀 테스트.
- [x] analyze/test, 콘텐츠 감사/미녹음 목록·README 갱신, 서명 APK 빌드·배포 및 결과 기록.

교육 전문가 필순/문항 검수와 음원 제작은 계속 미완료로 구분. 신규 경로는 직접 작성한 기존 자모를 조합하며 낱말은 왼쪽 글자부터 진행한다.

구현 결과: 학습 **101→122**, 필기 **99→122**(한글 50/영어 52/숫자 20), 전체 과목 퀴즈 **19→57**. 한글 음절 16개와 새 낱말 5개를 추가하고 기존 사과/나무에도 경로 연결. 낱말 7개: 사과/나무/바다/사자/하마/나비/아기. 음절은 단계 4 이상, 과·낱말은 5. 기존 99개 경로/항목 ID/저장 형식 보존.

수학 추가 38문항: 같은 수량 그림 선택 5, 그림 덧셈 15/뺄셈 14(0 포함), 색 2/패턴 2. 유형 교대 배치, 정답/결과 그림 수량 검증. 신규 문항마다 더 낮은 단계의 실제 대체 문제 ID 연결. LearningSession에 nullable quizOverrideId 추가해 이전 저장 호환, VM이 과목/단계/ID를 검사하고 전환·복원을 처리. 다음 활동에서는 override를 지워 일반 흐름으로 돌아감. 이야기의 쉬운 문제는 아직 별도 보강 대상.

첫 analyze 문제 0 / 전체 **79개 통과**(약 30초), `docs/content-stage-test.log`. 신규 6개 테스트: 그림 연산/0 정답, 수량 매칭 정답 유일성, 대체 문제 참조·단계·비순환, 낱말 좌우/획 순서, 첫 글자 후 재시작·완료, 실제 대체 문제 전환/재시작/다음 복귀. 기존 전체 경로×4연령 테스트도 신규 획 포함 통과. 신규 수학 5유형의 질문/정답 결과를 휴대폰 가로·세로 1.5배 글자에서 추가 검증 2개 통과(`docs/content-stage-phone.log`).

콘텐츠 감사: 122학습/122필기/57퀴즈/12화120장면, 오류 0, **녹음 299파일 미제작**. 감사 도구에 중복 문항 ID 및 대체 문제 유효성 검사 추가. 경로 검토 이미지 재생성 테스트 1개 통과 후 docs/tracing_preview.png 시각 점검. 전문가 필순 검수 완료가 아님. 정규 검증 후 유형 교대 순서 및 감사 검사도 포함한 최종 재검증·배포를 이어서 실행한다.

배포 전 사전 검사에서 기존 릴리스 빌드 번호 비교의 PowerShell 자동 $Matches 접근이 null 배열 오류를 내는 경우 발견. 외부 상태에 의존하지 않는 Regex.Match 결과의 Groups로 교체. 이 시도는 빌드/push/릴리스 생성 전에 중단했으며 기존 APK·키·릴리스 변경 없음. 수정 후 배포 재실행.

최종 배포 성공: 정적 분석 문제 0 / 전체 79개 통과 / 서명 APK 빌드 및 apksigner v2 통과 / main push / Releases 업로드·공개. `docs/content-stage-publish.log`. source commit f8883ac, versionCode **214189695**, 기존 공유용 키 유지. 공개 API에서 draft=false 및 SHA256 `a563664a8720f9c051ce832645fc50cc392f7c553cd60e4d3c20fc5dd6da11d2` 일치 확인.

APK: https://github.com/duafyd/kkoma_learning/releases/download/apk-1.0.0-214189695/kkoma-1.0.0-214189695.apk

남은 개발 우선순위: 이야기 안의 별도 쉬운 대체 문제, 수량 선 연결/드래그와 크기 분류 조작, 실제 효과음/배경음악·녹음 재생 파이프라인. 녹음 299개 제작/전문가 검수는 미완료이며 실제 S25/Tab 테스트는 사용자가 나중에 진행하기로 명시했다. 이를 개발 중단 조건으로 삼지 않는다. 후속 세션은 docs/REQUIREMENTS_STATUS.md와 이 기록부터 확인하고, 테스트 후 tool/publish-apk.ps1로 동일 키의 업데이트 APK를 배포한다.

## 2026-10-15 휴대폰 반응형 보강

사용자 요청: Galaxy S25처럼 좁은 화면에서도 동작하도록 반응형 구성. 실제 S25가 연결되지 않았으므로 특정 기기 검증 완료로 보고하지 않는다. 테스트 크기는 물리 패널 해상도가 아닌 Flutter 논리 픽셀이다.

- [x] 기존 태블릿 테스트에 360×780/780×360/412×915 추가, 최초 가로 화면 보호자 관문 overflow 재현.
- [x] 공통 여백 축소 및 좁은 화면 AppBar 작업 버튼 별도 줄, 학습 카드 1열, 글자 확대 시 카드 높이 조정.
- [x] CanvasWorkspace로 필기/자유 그림/스토리 필기·그림 캔버스와 도구 스크롤 분리. 낮은 가로 화면은 캔버스·도구 좌우 배치. 터치 영역을 축소해 맞추지 않음.
- [x] 보호자 관문/쉬는 화면 스크롤 적용.
- [x] 6화면 크기×글자 1.0/1.5배 및 시스템 상하 여백, 학습 퀴즈/스토리 활동/실제 드래그·회전 복구 회귀 검증.
- [x] 전체 analyze/test, 서명 APK 빌드 및 GitHub Releases 배포 완료.

최초 분석에서 수정 중 기존 한 줄 if의 줄바꿈으로 lint 1건 발생, 중괄호 추가 후 재검증 통과. 빌드와 테스트는 생성 파일 충돌을 피하도록 순차 실행한다.

추가 발견/수정: 글자 1.5배에서 홈 카드의 고정 높이로 overflow 발생, 최소 높이만 두고 내용에 맞게 늘어나도록 수정. 이후 analyze 문제 0, 전체 **73개 통과**(기존 62개 + 레이아웃 조합 9개 + 휴대폰 활동 2개, 약 28초), `docs/responsive-test.log`. 키보드/잠금 해제 설정 스크롤 검증 추가 후 휴대폰 활동 2개도 재통과(`docs/phone-workspace-test.log`). 테스트의 지연 생성 ListView 항목은 ensureVisible 대신 scrollUntilVisible로 탐색하도록 수정했으며 제품 오류와 구분한다.

검증 범위: 논리 1280×800/800×1280/600×960/360×780/780×360/412×915 각각 글자 1.0/1.5배와 상하 24 여백. 과목별 보기·퀴즈·필기 완료→다음 소문자·수량 놀이·보호자·갤러리·쉬기 화면. 휴대폰에서는 포인터 이동으로 숫자 1 필기 완료, 자유 그림 드래그/회전 후 획 보존/도구 스크롤 접근, 키보드 표시 상태 보호자 관문과 잠금 해제 설정, 스토리 선택/퀴즈/필기/그림+도움 버튼을 확인. 캔버스 최소 180 논리 픽셀 확보도 검사. 캔버스 안에 페이지 스크롤을 겹치지 않음.

실제 Galaxy S25 실행·발열/성능·키보드 종류·네트워크 없는 TTS 검증은 미완료. 이 자동 테스트를 S25 실기기 검증으로 보고하지 않음. 저해상도 화면에서 도구 영역은 따로 스크롤하며 태블릿에서도 기존 크기 버튼과 캔버스를 유지한다. 다음 작업은 최신 서명 APK를 S25에 업데이트 설치하여 터치·회전·소리·그림 저장을 확인하는 것.

최종 배포 검증: `tool/publish-apk.ps1`에서 **analyze 문제 0 / 전체 73개 통과 / 릴리스 빌드·apksigner v2 검증 통과 / main push / APK 업로드·공개 성공**, 로그 `docs/responsive-publish.log`. 배포 source commit `05f2852`, versionCode **214189181**(이전 214188401보다 증가), 동일 공유용 키 유지. 공개 API에서 draft=false 및 서버 SHA256 `a480159ba587e60e7b747621e79000ac303982e02ca8f44cc7dd181cda3d16d5` 일치 재확인. 최신 연결 확인에서도 emulator-5554 offline, 실제 S25 미연결.

다운로드: https://github.com/duafyd/kkoma_learning/releases/download/apk-1.0.0-214189181/kkoma-1.0.0-214189181.apk

로컬 임시 화면 캡처 도구로 360×780 자유 그림/780×360 필기를 PNG로 생성해 시각 점검(.tool_tmp/phone-portrait.png, phone-landscape.png). 테스트 글꼴로 실제 기기의 아이콘/폰트와 동일하다는 의미는 아님. 도구 영역 스크롤 막대 상시 표시 추가. 캡처 도구의 호스트 파일 I/O는 tester.runAsync로 실행 후 1개 통과했으며 정규 73개 테스트와 별도다. 임시 캡처 파일·서명 비밀·APK/build는 Git에 포함하지 않는다.

## 2026-10-15 한 명령 APK 릴리스 배포

사용자가 로컬 명령으로 빌드·push·APK 업로드를 승인했다. `tool/publish-apk.ps1` 추가: clean main 확인, 원본 키 존재/미추적 확인, 기존 Git Credential Manager 인증 재사용, analyze/test와 빌드 순차 실행, APK 서명 검증 후 main push, GitHub Releases draft 생성·APK 업로드·크기/서버 SHA256 비교 후 공개. 서명 키나 암호를 GitHub Secrets 또는 저장소로 보내지 않는다. 일반 git push에 자동 훅을 추가하지 않음.

빌드 번호는 2020년 이후 경과 초로 증가하며 source commit과 APK tag/versionCode를 릴리스에 기록. 중복·이전 번호·미커밋 변경은 중단. 기존 릴리스나 APK를 덮어쓰거나 삭제하지 않음. 실패 시 남은 draft는 이름을 보고 확인해야 함. 실제 실행 결과는 아래 후속 기록/최종 보고에서 확인. README에 단일 실행 명령 추가.

실제 실행 성공: analyze 문제 0, 테스트 62개 통과(약 20초), 서명 릴리스 빌드 44.3초, apksigner v2 검증 통과, main push 및 APK 업로드·공개 완료. `docs/publish-apk.log`. GitHub 공개 API에서 draft=false, APK 크기 53,428,865 bytes와 SHA256 `1285a92aff62abd06cae5f6b71cfb51290c252799a5723c2c6dd13b148177b5c` 일치 확인. 배포 source commit 49e708d, versionCode 214188401.

릴리스: https://github.com/duafyd/kkoma_learning/releases/tag/apk-1.0.0-214188401

APK: https://github.com/duafyd/kkoma_learning/releases/download/apk-1.0.0-214188401/kkoma-1.0.0-214188401.apk

동일 빌드 번호 재실행은 기존 릴리스 덮어쓰기 없이 빌드 전 중단됨을 확인(`docs/publish-apk-repeat-check.log`). 최초 실행 출력에서 draft 자산의 임시 untagged URL이 남는 문제 발견: 공개 후 assets API 재조회로 최종 URL을 출력하도록 수정. 최종 다운로드 URL은 공개 API로 확인. 이 후속 수정은 URL 표시/문서만 변경하며 앱 APK는 위 source commit과 일치. 이번 배포를 새 설치/아동 사용성 검증 완료로 간주하지 않는다.

## 2026-10-15 GitHub 동기화

사용자 요청으로 필기 99항목 확장과 APK 공유용 서명 설정을 main에 커밋·업로드한다. 직전 검증 결과는 analyze 문제 0 / 테스트 62개 통과 / 릴리스 빌드 및 apksigner 검증 통과이며 이번 Git 작업에서 재실행한 결과로 간주하지 않는다. 키·key.properties는 ignore/미추적 확인, 커밋 대상에 실제 서명 비밀번호가 포함되지 않았음을 검사했다. APK/build와 실행 로그는 기존 ignore 정책에 따라 제외하며 소스·문서·경로 검토 이미지를 업로드한다. 다른 PC에서는 비공개 키와 설정을 별도로 복원해야 릴리스 빌드할 수 있다.

## 2026-10-15 APK 공유용 서명 — 사용자 승인으로 정책 변경

사용자가 '키 생성까지 진행'을 명시 승인했다. 이전 '서명 없이 유지' 기록은 당시 결정의 이력이며, 현재 릴리스는 공유용 전용 키로 서명한다. Play Store 업로드는 하지 않는다.

- [x] 기존 키/설정 확인, 전용 RSA 3072비트 PKCS12 키와 SHA256withRSA 인증서 생성(유효 기간 10000일).
- [x] 암호학적 난수 비밀번호 생성. keytool에 환경변수로 전달하고 정리. 비밀번호를 도구 출력/명령 인수/문서에 노출하지 않음.
- [x] `android/release-signing/kkoma-sharing.p12` 및 `android/key.properties` 생성, Git ignore 확인. 기존 키 덮어쓰기 금지 스크립트 추가.
- [x] Gradle 릴리스 자동 서명 연결. 키 설정이 없는 PC에서 릴리스 빌드 시 백업 복원 안내로 중단. 기존 앱 ID 유지.
- [x] 릴리스 빌드 및 apksigner 검증 완료.
- [x] analyze/test 완료: 정적 분석 문제 없음, 전체 62개 통과(약 27초). `docs/sharing-signing-test.log`.

첫 빌드에서 Kotlin DSL의 java 확장과 java.util 이름 충돌 발견. Properties 명시 import로 수정하고 같은 키로 재빌드. 키를 재생성하지 않음. 키와 설정을 안전한 별도 저장소에 백업하는 것은 사용자 후속 작업이며 외부 업로드/자동 백업은 수행하지 않음. 다른 PC에서는 원본 두 파일을 복원할 것.

빌드와 테스트 동시 실행 중 Flutter가 생성하는 플러그인 등록 파일의 integration_test 참조 충돌로 한 번 실패했다. 테스트 종료 후 빌드를 순차 재실행해 성공(18.6초, 종료 코드 0). 같은 워크스페이스에서 Flutter test/build는 순차 실행할 것.

최종 APK: `build/app/outputs/flutter-apk/app-release.apk`, 53,428,861 bytes(약 51MB). SHA256 `47AE7D17515DC1B54F1AAF77430381B245AEFB89F05206533D7359A62F90BC2E`. 빌드 로그 `docs/sharing-apk-build.log`.

`apksigner verify --verbose --print-certs`: **종료 코드 0 / Verifies / v2=true / 서명자 1명**. minSdk 24 대상 서명 검증 통과. 인증서 SHA256 `46c242dd02d91c563321bccadfce21905f87efdefd995a985a9203ea63f21d4f`. `docs/sharing-apk-signature.log`. 인증서 지문은 공개 식별값이며 비밀번호/개인 키가 아님. 기존 키를 덮어쓰거나 검증용 debug 키로 서명하지 않음.

`git check-ignore`에서 키와 key.properties 모두 제외됨 확인, `git ls-files`에서 두 파일 미추적 확인. 현재 emulator-5554는 offline이므로 실제 설치/실행 검증은 미완료. 사용자가 APK만 공유하고 원본 키/설정을 비공개 백업한 뒤 Galaxy Tab 새 설치 및 다음 버전 업데이트를 확인할 것. GitHub push는 이번 작업에서 수행하지 않음.

## 2026-10-15 필기 콘텐츠 확장

계획과 체크리스트:
- [x] 공식 명세 전체와 기존 경로·판정·저장 구조 확인. 기존 13개 경로와 항목 ID 유지.
- [x] 한글 자모 24개와 가/나/모, 영어 대문자 26개·소문자 26개, 숫자 1~20 경로 구현. 소문자 최소 학습 단계 4.
- [x] 획 수 안내 추가. 새 패키지 없음.
- [x] 첫 analyze/test 실행: 오류·경고 없음, 60개 통과.
- [x] 두 자리 숫자 저장 복원, 연속 필기, 경로 미리보기 시각 점검 및 최종 전체 회귀 검증.
- [x] 콘텐츠 감사, README/대조표 갱신.
- [x] 서명 없는 APK 재빌드 및 서명 없음 검증.

직접 작성한 중심선 좌표이며 폰트 외곽선 자동 변환을 사용하지 않음. a/g는 손글씨형 한 층 형태. 전문가 필순·모양 검수는 미완료. 사과/나무 낱말 필기는 아직 미지원. 0은 두 자리 수 구성용이며 독립 학습 항목은 아님. 사용자의 서명 없이 유지 결정을 준수한다.

최종 목표: kkoma_spec.md v1.1 전체 주요 기능 및 Android APK. 전체 문서(0~13장)를 읽음. 출시 검수와 구현 완료를 구분한다.

최신 검증(2026-10-15 필기 확장): 정적 분석 오류/경고 0, 호스트 테스트 62개 통과. 상세 변경은 아래 기록 및 `docs/REQUIREMENTS_STATUS.md` 참조. 과거 세션의 41/56개 결과는 이력이다.

### 필기 확장 결과와 검증
- 지원 필기 **13 → 99개**(한글 27 / 영어 52 / 숫자 20). 학습 항목 **75 → 101개**. 기존 항목 ID·13개 경로·저장 형식 유지. 기존 진도 삭제 없음.
- 현재 획/총 획 수, 완료 후 같은 과목 다음 항목으로 이동, 글자 목록 버튼 추가. 다음 항목은 VM에서 단계 필터 적용. 과목 끝에서는 목록으로 돌아감. 소문자 카드 대소문자 짝 표기 수정.
- `tool/test.ps1`: **analyze 문제 0, 전체 62개 통과**(약 21초). 추가 6개 회귀 테스트: 전체 지원 범위/소문자 단계, 모든 경로×4연령 정상 입력, 닫힌 원·8의 역방향/부분 입력 거부, 두 자리 숫자 좌우 순서, 두 자리 숫자 중단/재개·완료 후 중복 제출, 단계별 다음 항목/과목 끝. 기존 3해상도 화면 테스트에 모/g/20 및 A 완료→a 이동 추가. `docs/tracing-expansion-test.log`.
- 검사 중 미리보기 도구의 불필요한 import 1건을 발견해 제거 후 전체 analyze/test 재실행 통과. 판정 허용 오차를 낮추거나 기존 엔진을 변경하지 않음.
- `dart run tool/audit_content.dart`: **101학습/99필기/12화/120장면/19퀴즈, 참조 오류 0**, 미녹음 240파일. 소문자 26항목 증가분 포함. 녹음 제작 완료로 간주하지 않음.
- `flutter test tool/tracing_preview_test.dart`: 검토 이미지 생성 테스트 **1개 통과**. `docs/tracing_preview.png`를 눈으로 확인하고 신규 M/N을 분리된 획으로 정리, i/j의 몸통→점 순서 정리 후 다시 생성. 자동 모양 판별·전문가 검수 통과라는 의미는 아님.
- `adb devices -l`: emulator-5554 **offline**. Android 실행 검증 없음. 서명 키 생성/서명/설치 수행하지 않음.
- 릴리스 APK 빌드 **성공**, assembleRelease 42.7초, 종료 코드 0. `build/app/outputs/flutter-apk/app-release.apk`, **53,420,669 bytes**(약 50.9MB). SHA256 `C3A12C5663E9689CFDD55053020A84AAA41830D64A482826987DD97F4B4CA19C`. 로그 `docs/tracing-expansion-apk-build.log`.
- `apksigner verify` 종료 코드 1 / Missing META-INF/MANIFEST.MF로 **서명 없음 확인**, 로그 `docs/tracing-expansion-apk-signature.log`. 현재 APK는 설치할 수 없음. 빌드에는 기존 플러그인의 Built-in Kotlin 이행 및 미참조 CupertinoIcons 폰트 경고가 남음. lib에 CupertinoIcons 사용 없음. analyze 문제와 구분하며 플러그인 호환성은 후속 점검 대상.

### 남은 작업과 다음 세션
1. 전체 출시에 대한 기존 약 70% 추정은 유지. 이번 필기 확장만으로 교육·오디오·실기기 검수까지 완료한 비율로 올리지 않음.
2. 전문가가 `docs/tracing_preview.png`와 경로를 검토할 것. 특히 한글 필순, 소문자 손글씨 형태, 두 자리 숫자 허용 오차를 실기기에서 확인. 낱말 필기(사과/나무 등)와 추가 음절은 후속 확장 대상.
3. 수량 연결·색/크기 분류·쉬운 대체 문제 콘텐츠 다양화. 사전 녹음 240개·효과음·배경음악 제작 및 실제 재생 검증은 미완료.
4. 재개 명령: `tool/test.ps1`, `dart run tool/audit_content.dart`, `tool/android.ps1 build apk --release`. 서명 없이 유지 결정은 지속 적용. 이 변경은 로컬 작업이며 새 GitHub 업로드 결과로 보고하지 않음.

## 작업상황 보고 형식 (사용자 지정, 2026-10-15)
앞으로 작업상황 보고 요청에는 다음 순서로 답한다.
1. 전체 작업 대비 진행 정도: 기능 구현과 출시 검증을 구분하고, 진행률은 측정값이 아니면 추정임을 명시한다.
2. 작업된 내용: 구현 기능과 실제 실행한 테스트 결과, 검증 날짜.
3. 남은 내용: 미구현·대체 구현·미검증·사용자 결정으로 보류된 항목을 구분한다.
4. 다음 단계에서 작업할 내용: 우선순위와 기대 결과. 서명 없이 유지한다는 사용자 결정을 준수한다.

## 환경 (2026-10-14)
- Windows 10, Flutter stable 3.47.7 / Dart 3.13.5, Android SDK 36 / platform 37, JDK 25.0.3. flutter doctor 모두 정상.
- 기존 Flutter 카운터 템플릿. Riverpod 3.4.3 / go_router 18.0.2. Git 저장소/AGENTS.md 없음.
- Pixel_Tablet AVD 시작 요청. 실제 Galaxy Tab 미연결, 모델/OS 미확인.
- 추가: sqflite 2.4.4+1, path_provider 2.1.6, flutter_tts 4.2.5. 설정/진도/메타데이터 SQLite 하나로 통일.
- 기본: 만 3세, 도움 3회 후 허용, 20분, 자동 읽기 켬. Android TTS 대안; 녹음·발음 전문가 검수 미완료.
- 기존 앱 ID 유지, 릴리스 서명 제거(기존 키 없음). 배포용 서명 키 임의 생성 금지. 현재 APK는 서명 없는 컴파일 검증용.

## 전체 구현 계획
각 기능 완료 후 analyze/test 실행, 실패 수정, 회귀 테스트 추가.

## 후속 작업 계획 (2026-10-15)
- 서명 없이 유지. 키 생성/서명/자동 debug 키를 만들 수 있는 Android 실행은 수행하지 않는다.
- 코드 대조에서 확인한 문제: 음성 실패에도 듣기 완료 기록, 음성 오류가 화면에 표시되지 않음, 퀴즈 전환 중 힌트/쉬운 경로/다음 입력의 쓰기 경합, 동시 작품 저장의 메타데이터 유실 가능성.
- 순서: (1) 음성 결과·화면 안내·듣기 기록 수정 및 테스트 (2) 학습/필기 전환 경합 방지 및 저장 실패 회귀 테스트 (3) 작품 메타데이터 직렬 처리·삭제 실패 복구 검증 (4) 전체 analyze/test, 콘텐츠 검사, 서명 없는 APK 재빌드.
- 완료 기준: 실패한 읽기를 완료로 저장하지 않음, 취소된 이전 재생이 최신 상태를 덮지 않음, 연속 입력에도 저장/화면 일치, 동시 저장 작품 목록 보존, 실패 시 재시도 가능. 녹음 제작·교육 검수·실기기 검증은 별도 남긴다.
- 환경 재확인: Android emulator-5554는 여전히 offline. 오늘 기기 실행 성공으로 보고하지 않는다.

| 순서 | 기능 / 파일 | 검증 및 완료 기준 | 상태 |
|---|---|---|---|
|1|환경·문서 분석|도구/기기 확인|완료, 실기기 제외|
|2|app, storage, profile, home, parent|설정 복구, 큰 버튼, 보호자 관문|구현·테스트 통과|
|3|tracing domain/presentation, 획 데이터|방향/부분/취소/연령 판정 테스트|13글자 구현·테스트 통과, 전문가 검수 대기|
|4|drawing, progress|브러시/지우개/undo/redo/PNG/초안/복구|구현·테스트 통과|
|5|learning, audio|2~5세 한글/영어/수학, 난이도/읽기|75항목·19퀴즈 구현, TTS 대안|
|6|story|State Machine, 1화 저장·힌트·도움|구현·테스트 통과|
|7|별도 Dart 데이터 시즌 12화|연령별 장면/선택/필기/복습/결말|120장면 구현·연령별 완주 테스트 통과|
|8|보호자/시간/생명주기/콘텐츠 검증|오프라인, 복구, 접근성, 삭제 확인|구현·단위/화면 테스트 통과, 실기기 대기|
|9|README, integration_test, APK|analyze/test/에뮬레이터/release|서명 없는 릴리스 빌드 성공, 설치·실행 검증 대기|

## 출시 전 남는 검수
- 사전 녹음 한국어/영어 음원 및 발음 검수. TTS 오프라인 언어팩 확인.
- 교육 전문가의 연령별 문항/한글 필순 검수.
- 실제 Galaxy Tab 필기, 성능/메모리, 재부팅/새 설치, 아동 사용성.
- 배포 앱 ID/서명 확정(직접 작성한 벡터 책/별 아이콘 적용, 릴리스 서명 없음).

## 실행/재개
flutter pub get → flutter analyze → flutter test → flutter emulators --launch Pixel_Tablet → flutter devices → flutter run -d Android-ID → flutter build apk --release.
아래에 기능별 실제 결과와 후속 작업을 추가한다.

## 2~5단계 중간 검증
- 홈/설정/보호자 산술 관문, Notifier/AsyncNotifier + Repository, SQLite 저장 구현.
- 13개 글자(한글 7 / 영어 3 / 숫자 3)의 획 경로와 필기 판정/시범/취소/재시도 구현.
- 자유 그림: 6색, 굵기, 지우개, undo/redo, 배경/도장(4~5세), SQLite 초안 자동 저장, 내부 PNG/작품 메타데이터 구현.
- 학습: 한글 자음/모음/음절/낱말, A~Z/소문자 표시, 1~20 세기, 유형 혼합 퀴즈 및 한 단계 난이도 조정 구현 중.
- 첫 analyze 통과. 이후 캔버스 drawColor 인자 오류 수정. 현재 async context lint 수정 중.
- Windows flutter_tester 종료 코드 0xC0000409: 한글 사용자 TEMP 경로 대신 프로젝트 `.tool_tmp`로 TEMP/TMP를 설정하니 테스트 실행 가능.
- 실행된 필기 테스트: 4개 통과, B 경로 1개 실패(교차 구간에서 가장 가까운 점 투영의 방향 오판). 판정 개선 후 다시 실행할 것.
- 에뮬레이터는 offline 상태. crashpad_handler 이벤트가 있어 추가 진단 중.
- 사전 녹음/효과음/배경음악 파일 없음. TTS/텍스트 및 진동 대안, 완료로 주장하지 않음.

## 6~8단계 검증 및 빌드 환경 해결
- 스토리: 12화 / 기본 120장면. 연령 2/3/4/5별 4/6/8/10장면. 선택 플래그, 9화 세 갈래 복습, 7화 그림 저장, 12화 방 선택·결말 구현.
- StoryPhase State Machine: 대사/선택/퀴즈/필기/그림/성공/에피소드완료/시즌완료 명시적 전이. 오답 상태에서는 다음 장면 차단, 시범/힌트/함께 쉬운 길/설정에 따른 도움 통과 제공.
- 스토리·학습 세션·필기 완료 획·그림 초안을 저장, 다시 시작 시 복원. 빠른 중복 답변 방지. 설정 변경 쓰기는 직렬화하여 값 덮어쓰기 방지.
- 보호자 산술 관문, 하루 실제 전경 사용 시간 누적/일자 변경, 장면 종료 후 쉬기, 음성/진동/애니메이션 설정, 진도 초기화/작품 삭제 확인 구현.
- 그림책 배경 8종 및 4 캐릭터는 직접 작성한 Flutter 벡터 렌더러. 다운로드 이미지 의존성 없음. 학습 그림은 시스템 이모지이며 기기별 표시 차이 검수 필요.
- 28테스트 통과 후 PNG/오디오/화면 테스트 확대. 1280x800, 800x1280, 600x960 전체 주요 화면 레이아웃 테스트 통과(홈 카드 넘침 수정).
- content audit: 75학습 항목, 13필기 지원 글자, 12화, 19퀴즈, 참조 오류 0. 녹음 214파일 미제작. docs/content_audit.json 참조.
- Windows 테스트: tool/test.ps1에서 TEMP/TMP를 .tool_tmp로 지정. flutter analyze 통과.
- Android 수정: Kotlin 플러그인 누락 보완, kotlin.incremental=false(C:/PubCache와 D: 프로젝트 서로 다른 드라이브 오류 회피).
- 신규 SDK CLI는 세미콜론 대신 slash 패키지명을 사용. NDK 28.2.13676358 수동 설치, SDK 35/36 및 CMake 3.22.1 자동 설치.
- JNI CMake가 한글 사용자 SDK 경로를 처리 못하여 tool/android.ps1에 앱 작업 폴더 .tool_tmp/android-sdk Junction 경로 설정. 원본 SDK 이동/삭제 및 전역 Flutter 설정 변경 없음.
- 에뮬레이터: 시작 후 emulator-5554 offline. 기존 AVD 스냅샷 없는 부팅/SwiftShader/소프트웨어/읽기전용 부팅도 시도했으나 프로세스 잠금 및 WHPX에서 중단. 기존 AVD 데이터 삭제/초기화하지 않음. 실실행 통과로 보고하지 않음.
- 릴리스: 명세 11장의 '서명 키 생성 등 영향이 큰 결정은 임의로 수행하지 마'를 준수하여 서명 없는 APK 빌드로 컴파일 확인 중. 설치 가능한 APK에는 사용자가 허용한 키 필요.

## 이번 세션 최종 상태 (2026-10-14)

### 실제 실행 결과
- `tool/test.ps1`: `flutter analyze` 오류/경고 없음. `flutter test --concurrency=1` **41개 모두 통과**, 약 16초. 최종 로그: `docs/final-test.log`.
- `dart run tool/audit_content.dart`: 75학습 항목 / 13필기 항목 / 12화·120장면 / 19퀴즈 / 콘텐츠 참조 오류 0. 녹음 214개 미제작(TTS 대안); `docs/content_audit.json`에 전체 ID와 제작 상태 기록.
- `tool/android.ps1 build apk --release`: **성공**, 최종 빌드 42.0초, `build/app/outputs/flutter-apk/app-release.apk`, 약 50.8MB.
- 최종 APK SHA256: `A943CE34BFD6260D7DB9E10E0B8E297017E1F140210946E334E18A7EC9416227`.
- APK manifest 검사: minSdk 24, target/compileSdk 36, 앱 이름 '꼬마 탐험 공부방'. 책과 별을 직접 그린 Android 벡터 아이콘 적용. 자동 백업 끔.
- 서명 **없음**. apksigner 검증이 'DOES NOT VERIFY / Missing META-INF/MANIFEST.MF'로 서명 없음 확인. 컴파일 성공을 설치 가능한 APK로 오인하지 말 것.
- `adb devices -l`: emulator-5554 **offline**. Android 실실행/통합 테스트 **미실행**. 실제 Galaxy Tab **미검증**.
- 검증용 debug 키 및 정식 배포 키 **생성하지 않음**. Android 릴리스 설정에 자동 debug 서명 연결 없음. 사용자가 **서명 없이 유지**하기로 결정함. 승인 대기 상태가 아니며 키 생성·서명을 실행하지 않는다.
- Android 통합 테스트: `integration_test/app_flow_test.dart` 작성 및 정적 분석됨. 연결된 Android와 debug 서명 승인 후 실제 실행할 것.

### 구현 및 핵심 변경 파일
- `lib/main.dart`, `lib/app/{app,lifecycle}.dart`: SQLite 초기화/ProviderScope/go_router/생명주기/큰 버튼 테마.
- `lib/core/{storage/local_store,audio/audio_service,widgets/activity_scaffold}.dart`: 로컬 저장, 오프라인 TTS/텍스트 대안, 공통 화면 및 확인.
- `lib/features/profile/{domain/settings,data/profile_repository,presentation/profile_vm}.dart`: 연령 Strategy, 보호자 설정 직렬 저장. 나이 변경 시 기본 학습 경로도 변경.
- `lib/features/learning/{domain,data,presentation}`: 3과목 카탈로그/퀴즈/적응 경로 및 세션 저장. 준비된 필기만 활성화.
- `lib/features/tracing/{domain,data,presentation}`: 경로/방향/시작/완료 평가, 낮은 이벤트 빈도 보간, 시범/현재 획, 취소/재시도/완료 획 복원.
- `lib/features/drawing/{domain,data,presentation}`: 캔버스, PNG, 초안, undo/redo, 지우개/도장/배경, 파일 실패 롤백.
- `lib/features/story/{domain,data,presentation}`: 12화·분기/복습/필기/그림/결말, 명시적 전이/도움 통과, 학습 경로 변경 시 장면 ID 유지 또는 다음 지원 장면 이동.
- `lib/features/math/presentation/counting_page.dart`: 3/5/10/20개 사과 드래그/탭/하나 더·덜.
- `lib/features/{home,parent,progress}`: 메뉴, 보호자 확인, 진도/작품 관리, 사용 시간/쉬기. 시간은 Stopwatch로 전경 시간을 누적하여 빠른 장면 이동에서 소수 초가 사라지지 않게 처리.
- `test/`: 12개 테스트 파일, 41 테스트. 콘텐츠/전이/필기/저장/PNG/음성/보호자/시간/3크기 전체 화면/동시 입력 회귀 검증.
- `tool/{test,android,sign-debug}.ps1`, `tool/audit_content.dart`: 재현 가능한 실행·검증 도구. 서명 스크립트는 작성만 했고 키 생성·서명 단계는 미실행.
- `README.md`, `docs/DEVICE_VALIDATION.md`: 실행/설치/제한과 실기기 검증 체크리스트.

### 남는 작업 / 다음 세션 순서
1. 사용자 결정: **서명 없이 유지**. 키 생성·서명을 실행하지 않고 같은 승인을 다시 요청하지 않는다.
2. 사용자가 향후 명시적으로 결정을 변경할 때만 서명 작업을 재개한다. 현재 설치 가능한 APK 및 Android 기기 테스트는 보류하며, 소스 개발·정적 분석·호스트 테스트는 계속 가능하다.
3. Windows 재시작 또는 Android Studio에서 멈춘 AVD/QEMU 종료 후 Cold Boot. AVD 데이터 wipe/실제 앱 데이터 삭제를 임의로 하지 않는다.
4. Android 연결 확인 후 `tool/android.ps1 test integration_test/app_flow_test.dart -d <ID>` 및 실제 실행. 키 승인 전 flutter run/test on-device는 기본 debug 키를 만들 수 있으므로 실행하지 않는다.
5. Galaxy Tab 실기기 검증(DEVICE_VALIDATION.md), 한글 필순/문항/영어 발음 교육 전문가 검수.
6. 사전 녹음·효과음·배경음악 제작 및 재생 검증. 현재 음성은 오프라인 TTS, 효과 반응은 진동이며 음량을 조절하는 효과음으로 보고하지 않는다.
7. 필요 시 나머지 글자의 검수된 획 데이터 확장(현재 13글자). 시스템 이모지 표시 및 접근성/아동 사용성 확인.
8. 정식 배포 앱 ID/서명 결정, 설치/업데이트/재부팅/오프라인/프레임·메모리 검증 후에만 출시 완료로 판정한다.

전체 주요 기능의 실행 코드·자동 테스트·빌드 산출물은 준비했으나, **전체 명세의 출시 검수가 모두 완료된 상태는 아니다**. 미완료를 숨기지 않고 위 재개 지점부터 이어간다.

후속 빌드 종료 코드 확인: 동일한 최종 코드를 다시 빌드하여 PowerShell의 stderr 경고와 실제 프로세스 종료 코드를 구분했다. Android 빌드 프로세스 종료 코드 **0** 확인(전체 빌드 성공). 출력 로그는 docs/apk-build.log, 서명 검증 로그는 docs/apk-signature.log에 있다. 이후 사용자 답변 **서명 없이 유지**를 반영했다. 이번 갱신은 문서만 변경했으며 APK·키·코드 변경이나 테스트 재실행은 하지 않았다.

## 2026-10-15 후속 작업 결과

### 작업한 내용
- 명세 대조표 `docs/REQUIREMENTS_STATUS.md` 추가. 준비된 기능/일부 지원/대체 구현/미검증을 구분했다. 같은 수량 연결·색/크기 분류·쉬운 대체 문제 등 콘텐츠 보강 대상과 제한된 필기 범위를 명확히 기록했다.
- 음성: `AudioService`가 재생 성공/무음/오프라인 음성 없음/취소/실패를 구분해 반환. 최신 요청만 음성 상태를 갱신하며 이전 재생 완료가 최신 실패 안내를 지우지 않는다. 네이티브 재생 거절·시간 초과도 실패로 처리하고 정지 요청을 보낸다.
- UI: 공통 `AudioNotice`로 소리 없이도 계속할 수 있음을 안내. 안내 닫기 제공. 보호자 영역에 언어팩 확인 방법과 최근 진단 표시. 녹음이나 실제 기기 재생이 완료된 것으로 보고하지 않는다.
- 듣기 기록: `LearningVM.listen`에서 음성 호출과 진도 기록을 조율. 실패/무음은 시도만 기록하고 실제 재생 성공만 듣기 완료로 기록. 다른 요청으로 취소된 읽기는 완료/시도를 추가하지 않는다.
- 퀴즈: 답변뿐 아니라 힌트/쉬운 길/도움/다음 장면 입력에도 동일한 저장 중 가드 적용. 저장된 상태와 화면의 피드백이 일치하도록 처리. 저장 실패 후 다시 입력 가능.
- 필기: 획 저장 중 지우기/재시도가 경합하여 저장 상태를 덮지 않도록 보호.
- 작품: 저장·목록 조회·삭제를 Repository에서 순서대로 처리. 동시 PNG 저장 또는 저장/삭제 혼합에서 목록 유실 방지. 메타데이터 저장 실패 시 PNG 복구/정리. 삭제 전 파일을 임시 보관하고 실패 시 복구하며, 메타데이터 반영 전 중단된 삭제는 다음 목록 읽기에서 원래 PNG로 복구. PNG 렌더링 리소스도 실패 경로에서 해제.
- 사용 시간: 저장을 기다리는 동안에도 일시 중지 상태를 즉시 반영하여 백그라운드 시간 오산입 방지. 초기 로딩 도중 일시 중지·종료 처리. 저장 실패 이후 누적 시간을 다음 체크포인트에서 다시 저장. 테스트용 Stopwatch 주입으로 실제 수 분을 기다리지 않고 검증.
- 추가 패키지 없음. 키 생성·서명·Android 설치/실행 없음. 사용자 '서명 없이 유지' 결정 유지.

### 실제 테스트 결과
- `powershell -ExecutionPolicy Bypass -File tool/test.ps1`: `flutter analyze` 오류/경고 없음, **56개 모두 통과**, 약 19초. 이전 41개에서 회귀 테스트 15개 추가. 최신 로그 `docs/followup-test.log`.
- 추가 테스트: 음성 거절/시간 초과/이전 응답 경합, 읽기 완료 기록/안내 닫기와 학습 계속, 답변 중 힌트·쉬운 길·중복 다음/저장 실패 재시도, 필기 초기화 경합, 동시 작품 저장/삭제·삭제 실패·중단 복구, 저장 지연/초기 로딩 중 일시 중지·시간 저장 실패 재시도.
- 초기 수정 후 화면 전환 테스트에서 음성 정지 timeout 타이머가 남는 실패 발견. 화면 전환/해제는 네이티브 응답을 기다리지 않고 정지 요청을 보내도록 수정한 뒤 전체 테스트 통과. 실행되지 않은 Android 음성 검증을 mock 테스트로 대체했다고 주장하지 않는다.
- `dart run tool/audit_content.dart`: 75학습 항목, 13필기 항목, 12화·120장면, 19퀴즈. 콘텐츠 참조 오류 0. 녹음 214개 미제작 상태 유지.

### 남은 내용 및 다음 단계
1. 학습 콘텐츠 보강: 수량 연결·색/크기 분류와 연산 문항 다양화, 힌트 강조와 구분되는 쉬운 대체 문제 추가. 정답 유일성·연령별 경로 회귀 검증.
2. 한글 필순·영어 발음·문항의 교육 전문가 검수 및 검수된 필기 경로 확대. 현재 13개 지원을 전체 글자 지원으로 보고하지 않는다.
3. 사전 녹음 214개·효과음·배경음악 제작 및 재생 기능 연결. 현재 TTS/진동 대안 유지.
4. Android 에뮬레이터는 여전히 offline. 기기 통합 테스트·실제 Galaxy Tab 성능/오디오/아동 사용성 미검증. 서명 없이 유지한다는 결정에 따라 키 생성·서명·기기 실행은 보류.
5. 다음 세션 검증 명령: `tool/test.ps1`, `dart run tool/audit_content.dart`, `tool/android.ps1 build apk --release`. 최신 요구사항 범위는 `docs/REQUIREMENTS_STATUS.md`부터 확인한다.

진행률은 이전 약 70%라는 추정치를 기계적으로 올리지 않는다. 이번에는 기능 수보다 저장·오디오·생명주기의 안정성을 보강했으며, 출시 검수까지 끝난 상태는 아니다.

### 후속 APK 산출물
- 최종 변경 코드로 서명 없는 릴리스 빌드 성공: assembleRelease 42.7초, 프로세스 종료 코드 0.
- 경로: build/app/outputs/flutter-apk/app-release.apk, 53305981 bytes (약 50.8MB).
- SHA256: 9773097B480324370474B377D8062B55B25377DBB9BF2984F4DDFACFA1380E07
- apksigner 종료 코드 1, 서명 없음(DOES NOT VERIFY / Missing META-INF/MANIFEST.MF) 확인. 설치 가능한 서명 APK가 아니다.
- 최신 빌드 로그 docs/followup-apk-build.log, 서명 확인 로그 docs/followup-apk-signature.log.

## GitHub 소스 관리 설정 (2026-10-15)
- 원격 저장소: https://github.com/duafyd/kkoma_learning.git, main 브랜치.
- 기존 원격 초기 커밋과 .gitignore 규칙을 보존한 상태로 현재 Flutter 프로젝트 소스·테스트·문서·pubspec.lock을 추가한다.
- APK/build, .tool_tmp, .dart_tool, IDE 캐시, 로컬 SDK 설정, 실행 로그, 개인 키/서명 파일은 추적하지 않는다. 서명 없이 유지 결정도 그대로 적용한다.
- 이번 작업은 Git 설정과 업로드 범위 정리이며 앱 동작 코드는 수정하지 않았다. 기존 56개 테스트 통과 기록을 유지하며 테스트 재실행으로 보고하지 않는다.
- 업로드 결과: 최초 비대화형 인증은 거부되었으나 Git Credential Manager의 대화형 인증 허용으로 재시도하여 성공. 소스 커밋 898ebdb를 원격 main에 push했고 기존 초기 커밋 이력을 유지했다.
