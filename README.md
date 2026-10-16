# 꼬마 탐험 공부방

만 2~5세를 위한 Android 태블릿 학습 앱입니다. 공식 요구사항은 [docs/kkoma_spec.md](docs/kkoma_spec.md), 실제 구현·검증·재개 기록은 [docs/PROGRESS.md](docs/PROGRESS.md)에 있습니다. 기능 코드와 자동 테스트를 구현했으며, 녹음 음원·교육 전문가 검수·실제 태블릿 검증까지 모두 끝난 출시 제품으로 보고하지 않습니다.

## 구현된 기능

- **음원·실기기 외 로컬 완성도 보완(최신):** 손가락 준비 운동 6종(점/가로/세로/원/물결/산길), 현재 화를 보여주는 홈, 12화 모험 표지 지도와 작품 확대 전시, 그림 도장/도구·수학 원인과 결과 안내를 보완했습니다. 짝꿍 바구니는 선으로 잇기와 탭 대안을 함께 제공합니다. 영문·숫자 25개 곡선을 부드럽게 만들고 획 수·순서·시작/끝점과 기존 저장을 유지합니다. 기존 학습122 + 준비 운동6 = 경로128항목입니다. 캐릭터 4인×4포즈의 [새 16프레임](assets/story/cast-motion-v1.png)을 내장 이미지 도구로 제작해 등장/이동/표정에 연결했습니다([프롬프트](docs/cast_motion_prompt.txt)); 두 이동 포즈와 열린 입 표정이며 음소 립싱크는 아닙니다. [검토 자료](docs/review/README.md)는 경로128·문항118·연령/화별 경로48개이며 전문가 승인은 대기입니다. 호스트 analyze 문제0/전체415개 통과, 3크기×글자1/1.5배 캡처54장을 확인했습니다. 별도 태블릿 에뮬레이터의 Android 저장/재개 통합1개도 통과했고 로컬 서명 APK **1.0.0 (214290482)** 빌드·v2 검증을 마쳤습니다([결과](docs/polish_build.json)). Git/APK 업로드는 하지 않았습니다. [홈](docs/screenshots/polish-home-tablet-1.0.png) · [작품함](docs/screenshots/polish-gallery-tablet-1.0.png) · [곡선](docs/review/english-lower.png).
- **7~12화 본문 상호작용(이전 로컬):** 꽃 색/모양, 휙휙 바구니, 세 갈래 복습, 종이숲 성장, 하늘 복습, 선택한 도서관 방의 총 17개 퀴즈를 그림 속 Flame 소품으로 고릅니다. 8~12화 필기 5곳도 이야기 그림을 유지하고 저장된 획에 따라 바구니·길·책·별이 변합니다. 성공 후 선택판은 사라지고 장면 결과가 남습니다. 7화에서 저장한 실제 그림을 정확한 작품 ID로 다시 보여줍니다. 만 2세/도움·버튼 대안·기존 11화 별 배치와 저장 복구를 유지합니다. [휙휙 바구니](docs/screenshots/book-8-choices-tablet.png) · [마지막 필기](docs/screenshots/book-12-written-tablet.png). analyze 문제0 / 전체 **393개 테스트 통과**, 3크기 캡처84장. 로컬 APK **1.0.0 (214274816)** 빌드·v2 서명 검증 성공([결과](docs/chapters_build.json)). Git/APK 업로드는 하지 않았습니다. 실기기 검증과 실제 연기 음원 제작은 남아 있습니다.
- **스토리 연기 음원 준비·3/4화 확장(이전 로컬):** 스토리 자동/수동 읽기와 글자 소리 버튼이 장면별 정확한 녹음 ID를 요청해 같은 대사를 다른 인물의 파일로 재생하지 않도록 했다. 모아·루루·토토·휙휙의 연기/감정/호흡 지침, 352개 스토리 take의 제작 자료와 PCM 품질 경고를 추가했다. **실제 녹음 0개이며 현재 소리는 TTS 대안**이다. [성우 연기 제작 지침](docs/audio/STORY_DIRECTION.md). 사용자 선택은 캐릭터별 AI 연기이며 [시연 4개 생성 계획](docs/audio/AI_AUDITIONS.md)과 무료 dry-run 도구를 준비했다. 사용자가 비용 사용을 보류했으므로 실제 생성은 대기한다. 3화 열매 선택·씨앗 꾸러미/ㄱ 이름표, 4화 표지 선택·ㄴ 필기/출발 신호와 증기를 연결했다. 새 기차 주행 프레임은 아니다. [열매 선택](docs/screenshots/letter-3-choices-tablet.png) · [기차 필기](docs/screenshots/letter-4-complete-tablet.png). 최종 analyze 문제 0 / 전체 **370개 통과**, 로컬 APK **1.0.0 (214272709)** 빌드·v2 서명 검증 성공([결과](docs/adventure_build.json)). Git/APK 업로드는 하지 않았다.

- **꽃문·등대와 필기 연결(이전 로컬):** 2화 꽃문의 ㅓ/ㅏ, 5화 등대의 B/A를 그림 속에서 직접 누릅니다. 필기 중에도 그림책 장면을 유지하고, 저장된 ㅏ의 2획·A의 3획에 따라 꽃길과 바다 빛길이 차례로 살아납니다. 완료한 필기와 다음 이야기 버튼을 함께 보여줍니다. 잘못된 선·취소·저장 실패에는 빛을 채우지 않으며, 재개·무동작·백그라운드는 성공 연출을 반복하지 않습니다. 만 2세/쉬운 길과 버튼 대안도 유지합니다. [꽃길 필기](docs/screenshots/letter-2-complete-tablet.png) · [등대 선택](docs/screenshots/letter-5-choices-phone.png). analyze 문제 0 / 전체 **353개 통과**, 로컬 APK **1.0.0 (214266319)** 빌드·v2 서명 검증 성공([결과](docs/letter_build.json)). 남은 작업은 PROGRESS 상단을 따릅니다. 기존 배경의 전환과 코드로 그린 빛 연출이며 새 캐릭터 프레임 제작은 아닙니다. Git/APK 업로드는 하지 않았습니다.

- **그림 속 돌다리·별자리 미션(이전 로컬):** 6화는 삽화의 실제 빈자리에 돌 3개를 끌어 놓고, 11화는 하늘에 별 5개를 놓아 빛길을 잇습니다. 배치 저장 뒤에만 그림이 바뀌고 정답 성공 후 동료가 이동합니다. 기존 버튼 방식·만 2세/도움 경로·진도 저장을 유지하며, 재개 시 성공 연출을 반복하지 않습니다. [돌다리](docs/screenshots/world-6-after-tablet.png) · [별자리](docs/screenshots/world-11-after-tablet.png). 동료 이동은 기존 투명 그림의 위치 연출이며 새 걷기 프레임은 아닙니다. analyze 문제 0 / 전체 **342개 통과**, 로컬 APK **1.0.0 (214265371)** 빌드·v2 서명 검증 성공([결과](docs/world_build.json)). 남은 작업과 재개 기록은 PROGRESS 상단을 기준으로 합니다.

- **Flame 장면 놀이·필기 경험 보강(직전 로컬):** 12화 각 도입 장면에서 사건에 맞는 소품을 찾고 빛을 모읍니다. 2/3/4~5단계의 1/2/3개 탐색, 실제 탭/접근성 조작, 저장 후 반응과 이어하기, 유한 연출 후 엔진 정지를 구현했습니다. 한글·영어·숫자 공용 필기에 획별 자동 시범/펜 끝·실시간 경로 코칭·곡선 화살표·태블릿 옆 안내판을 추가했습니다. 기존 낙서/부분 획 판정과 ㅊ 보완을 유지합니다. [장면 놀이](docs/screenshots/experience-story-tablet.png) · [빛 회수](docs/screenshots/experience-restored-tablet.png) · [한글 필기](docs/screenshots/experience-hangul-tablet.png) · [영어 필기](docs/screenshots/experience-english-phone.png). analyze 문제 0 / 전체 **331개 테스트 통과**, 로컬 APK **1.0.0 (214240100)** 빌드·v2 서명 검증 성공([결과](docs/experience_build.json)). 상세 기록은 PROGRESS 상단을 따릅니다. 전 장면 게임화·캐릭터 걷기 프레임·실제 음원 제작을 완료한 것은 아니며 Git/APK 업로드는 하지 않았습니다.

- **화면 품질 1차 개편(로컬 후속):** 태블릿 홈을 모험 표지·그림 책장으로 구성하고, 과목별 학습 카드와 공용 글꼴/색/버튼을 정리했습니다. 스토리는 그림 비중을 키우고 짧은 대사의 빈 상자를 줄이며, 낮은 가로 폰은 전체 폭 대사로 읽습니다. [홈 캡처](docs/screenshots/design-home-tablet.png) · [스토리 캡처](docs/screenshots/design-story-tablet.png). analyze 문제 0 / 전체 312개 통과, 로컬 APK `1.0.0 (214238199)` 빌드·v2 서명 검증 성공([결과](docs/design_build.json)). 캡처는 호스트 렌더이며 실기기·아동 사용성 검증은 남아 있습니다. 기존 GitHub 배포 APK에는 아직 이 개편과 아래 ㅊ 수정이 없습니다.
- **ㅊ 첫 획 입력 보완(후속 로컬 수정):** 짧은 직선에서 작은 손가락 위치·끝점 오차를 허용하고, 좁은 화면의 번호 배지를 옆으로 옮겨 선과 화살표를 가리지 않게 했습니다. 탭·부분 획·낙서·4~5단계 역방향 거절은 유지합니다. analyze 문제 0 / 전체 309개 테스트 통과. 아래의 기존 배포 APK에는 이 수정이 아직 포함되지 않았습니다.
- **녹음 우선 재생:** 대본 원문·언어가 일치하는 번들 WAV를 먼저 재생하고, 누락/실패에는 오프라인 TTS로 대체합니다. 완료 응답·반복·음량·중단·백그라운드 취소를 처리합니다. 실제 녹음 파일은 아직 **0개**이며, 현재는 TTS를 사용합니다. [음원 등록 절차](docs/audio/README.md)를 따릅니다.
- **저장 복구·음성 제작 준비:** 7화 그림 제출을 먼저 저장하고 고정 작품 ID로 PNG/작품/진도를 마무리해, 중단 후 재시작과 저장 실패 재시도에서 중복 제출을 막습니다. 부모 진도 초기화를 늦은 저장이 덮지 않도록 조건부 저장을 사용합니다. 영어 소문자는 표시를 유지하면서 글자 이름 읽기는 대문자로 요청합니다. [음성 대본 671개와 검수 안내](docs/audio/README.md)는 제작 준비 자료이며 녹음·실제 청취 검수가 완료된 것은 아닙니다.
- **6~12화 전체 보강:** 돌다리 세 돌 배치 → 색 정원과 그림 지도 → 휙휙과 글자/숫자 정리 → 세 갈래 복습 → 종이숲 성장 순서 → 다섯 별 배치 → 도서관 재개장까지 70개 기본 장면을 개별 작성했습니다. 전용 그림 15장, 일반 그림 퀴즈 28종과 만 2세 탐색 7종을 추가했습니다. 9화는 고른 길에 따라 세 번의 복습이 달라지고, 12화는 꽃 방/별 방 선택이 실제 결말 그림에 반영됩니다. 7화 그림은 자유 그림과 별도로 이어 그리며 6색·지우개·undo/redo·작품 저장을 제공합니다. [돌다리](docs/screenshots/ep6-after-tablet.png) · [색 정원](docs/screenshots/ep7-after-tablet.png) · [별자리](docs/screenshots/ep11-after-tablet.png) · [꽃 방](docs/screenshots/ep12-flowers-tablet.png) · [마지막 장면](docs/screenshots/ep12-ending-tablet.png). 캡처는 Flutter 호스트 렌더입니다.
- **4·5화 이야기 보강:** 씨앗을 가·나 표지의 기차에 싣고, 꺼진 등대에서 A 빛을 켭니다. 한글 조합/순서·A/a 짝·Apple 과일 카드와 만 2세 자유 탐색을 제공합니다. `A 이름 듣기`와 `Apple 단어 듣기`는 영어 음성으로 각각 재생하며, 가/나 소리는 한국어로 들려줍니다. 듣기만으로 미션을 통과시키지 않습니다. [소리 기차](docs/screenshots/ep4-ready-tablet.png) · [켜진 등대](docs/screenshots/ep5-lit-tablet.png) · [폰 듣기 버튼](docs/screenshots/ep5-speech-phone.png).
- **2·3화 이야기 보강:** 모음 소리로 꽃문을 열고, 기역 열매를 찾아 앞 화의 아와 합쳐 가를 만듭니다. 전용 배경 4장, 꽃문/열매의 Flutter 글자 이름표, 한글 카드·씨앗 세기·만 2세 탐색 변형을 추가했습니다. 성공 저장 후 그림이 바뀌며 오답/저장 실패에는 바뀌지 않습니다. [닫힌 꽃문](docs/screenshots/ep2-gate-tablet.png) · [열린 꽃문](docs/screenshots/ep2-open-tablet.png) · [기역 열매](docs/screenshots/ep3-tree-tablet.png) · [가 만들기](docs/screenshots/ep3-ga-tablet.png).
- **1화 사건 연출 보강:** 별빛이 꺼진 책 → 책장 아래 조각 찾기 → 숫자 1의 빛줄기 → 꽃밭 지도 발견을 장면별 배경 3장과 찾기/가리키기 포즈로 연결했습니다. 별 모양·별 세기·같은 별 짝의 그림 선택 카드, 만 2세 자유 선택을 제공합니다. 별을 누른 순서와 개수를 저장하고 같은 별 중복 세기를 막습니다. 1~12화의 모든 에피소드가 전용 사건 삽화로 연결됩니다.
- **필기 품질 보강:** 이동 거리로 다시 샘플링한 경로를 순서대로 비교하며, 획 크기에 비례한 허용 오차·시작과 끝·과도한 길이·왕복 낙서를 검사합니다. 작은 터치 흔들림을 정리하되 의도적인 되돌아가기는 보존합니다. 2~3세 역방향 탐색은 허용합니다. 실제 아동의 손가락 입력 난이도 검수는 남아 있습니다.
- **움직이는 그림책:** 1~12화 전용 26장과 공용 네 장의 배경, 투명 캐릭터 모아·루루·토토·휙휙을 합성합니다. 다음 버튼/그림 왼쪽 스와이프로 650ms 페이지 넘김, 등장·인사·성공 반응을 보여 줍니다. 퀴즈/필기 미션은 스와이프로 건너뛰지 못하며 저장 성공 후에만 페이지와 효과음이 진행됩니다. 종이색 대사 패널·화자·진행 정보·Jua 글꼴을 사용합니다. 캐릭터 동작은 정적 그림의 위치·기울기·크기 애니메이션이며 관절/프레임별 걷기 애니메이션은 아닙니다. [제작·프롬프트 기록](docs/ARTWORK.md).
- **오프라인 이야기 효과음:** 책장 넘김·친구 인사·성공 세 가지 짧은 WAV를 번들하고 Android SoundPool로 재생합니다. 음성과 효과음 음량은 독립이며, 효과음 0/연타 제한/화면 이동/백그라운드 취소를 지원합니다. 보호자 설정에서 효과음을 미리 들어 볼 수 있습니다. 실제 기기 청취 확인은 남아 있습니다.

1화 미리보기(Flutter 호스트 렌더): [시작](docs/screenshots/ep1-start-tablet.png), [그림 퀴즈](docs/screenshots/ep1-shape-tablet.png), [별 세기](docs/screenshots/ep1-count-tablet.png), [꽃밭 지도](docs/screenshots/ep1-map-tablet.png), [휴대폰](docs/screenshots/ep1-count-phone.png). 기존 [페이지 넘김 중간 프레임](docs/screenshots/book-page-turn.png), [캐릭터 인사 반응](docs/screenshots/book-character-motion.png).
- **Android TTS 수정:** flutter_tts 4.2.5 Android가 반환하는 `network_required: '0'`을 오프라인 음성으로 인식하도록 수정했습니다. 기존 코드는 이 값을 거부해 로컬 음성이 있어도 읽지 못했습니다. 네트워크 음성 `'1'`은 계속 거부합니다. 기기에 한국어/영어 오프라인 음성이 설치돼 있어야 하며 실제 기기 재생 확인은 별도입니다.

- 만 나이 2~5세와 별도 학습 경로 설정. 나이를 바꾸면 기본 학습 경로도 바뀝니다. 퀴즈 성공이 이어지면 한 단계씩 조정하고, 반복 시도에는 힌트·다른 길·도움 통과를 제공합니다.
- 새 수학 활동 38개: 같은 수량 찾기 5개, 사과 그림 덧셈 15개·뺄셈 14개(0개 포함), 색 분류 2개·패턴 2개. 유형을 번갈아 배치합니다. 새 문항의 '다른 길'은 별도 쉬운 문제로 전환하며 앱 재시작 후에도 해당 문제를 이어합니다. 그림 선택 방식 수량 매칭이며 선 연결/드래그 매칭으로 보고하지 않습니다.
- **짝꿍 바구니:** 숫자 탐험대 상단에서 여는 독립 조작 놀이입니다. 수량 드래그 매칭·크기/색/도형 분류 4유형, 단계별 12라운드(반복 연습과 배치 변화 포함). 드래그 또는 친구→바구니 터치로 진행하며 선택·배치·힌트·도움 상태를 저장합니다. 2~3세는 2개 바구니, 4~5세는 3개 바구니이며 힌트·도움 통과와 사용 시간 쉬기를 제공합니다. 부모 진도 초기화에 포함하고 다음 놀이에서 완료 배지를 한 번 기록합니다.
- **스토리 대체 미션:** 퀴즈와 필기에서 '함께 쉬운 길로'를 선택하면 별도의 두 가지 선택 매칭 미션으로 바뀝니다. '원래 미션'으로 돌아가거나 대체 미션을 완료해 같은 이야기의 다음 장면으로 진행합니다. 변환 상태를 저장하며 보호자의 도움 통과 설정은 그대로 적용합니다.
- 한글 자음·모음·쉬운 음절/낱말, A~Z·a~z, 1~20 숫자: 122항목. 소문자는 학습 단계 4 이상에서 제공. 세기·비교·분류·패턴·조합·기초 더하기/빼기 등 57퀴즈.
- Android 오프라인 TTS 읽기. 알파벳 이름과 대표 단어, 자음 이름과 예시를 구분해 읽습니다. 기기에 해당 언어의 오프라인 음성이 없으면 글과 그림으로 계속 진행합니다.
- 음성 재생 실패 시 안내를 표시하고 보호자 영역에서 최근 상태를 확인할 수 있습니다. 음성 실패·무음은 듣기 시도로만 기록하며 실제 재생 성공만 듣기 완료로 기록합니다. 취소된 이전 재생은 완료로 기록하지 않습니다.
- 따라 그리기: 시작점·화살표·현재 획·시범·재시도, 연령별 판정. 시작·방향·경로 거리·완료도 평가와 손 떨림 허용. 완료 획을 저장해 앱 재시작 후 복원합니다.
- 자유 그림: 6색, 굵기, 지우개, undo/redo, 전체 지우기 확인, 4~5세 도장/배경. 초안 자동 보관, PNG 저장/다시 그리기, 보호자 확인 후 작품 삭제.
- 《별빛 도서관과 사라진 이야기》 시즌 1의 12화: 120개 기본 장면, 경로별 4/6/8/10장면. 대사·선택·퀴즈·필기·그림·보상, 9화 세 갈래 복습과 12화 결말. 장면/선택/시도/도움/필기를 저장해 이어합니다.
- 사과를 바구니로 드래그하거나 눌러 모으기, 연령별 3/5/10/20개, 4~5세 하나 더/하나 덜 조작.
- 보호자 산술 관문, 자동 읽기/반복/음량/반응/애니메이션, 하루 사용 시간, 진도 초기화/작품 삭제/앱 종료 확인. 장면 마무리 후 쉬는 화면.
- 가로/세로 화면, 큰 터치 영역, 비율을 유지하는 그림책 배경과 독립 캐릭터 레이어, 자체 벡터 앱 아이콘.
- 휴대폰 반응형: 좁은 화면 학습 카드 1열과 상단 작업 버튼 별도 줄, 낮은 가로 화면은 캔버스/도구 좌우 배치. 도구 영역만 스크롤해 필기·그림 터치와 분리. 보호자 확인은 키보드가 떠도 스크롤 가능. 홈 카드는 글자 확대에 따라 높이가 늘어납니다.

따라 그리기는 **122항목**입니다: 한글 자모·음절·낱말 50개, 영어 A~Z·a~z 52개, 숫자 1~20 20개. 낱말은 사과/나무/바다/사자/하마/나비/아기 7개이며 왼쪽 글자부터 쓰고 획마다 저장합니다. 음절은 학습 단계 4 이상, 과와 낱말은 5에서 제공합니다. 현재 획 수·시범·다음 글자 연습을 지원하며 기존 경로와 진도는 유지합니다. 소문자 a/g는 한 층 손글씨 형태입니다. **교육 전문가의 모양·필순 검수는 미완료**입니다. [전체 경로 미리보기](docs/tracing_preview.png)를 확인하세요.

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

새 화면 캡처는 `POLISH_CAPTURE=true`, 경로 검토 자료는 `REVIEW_EXPORT=true`로 해당 테스트를 실행합니다. [교육 검토 자료 재생성](docs/review/README.md)과 PROGRESS의 검사 명령을 참고하세요. 별도 Pixel Tablet 에뮬레이터(API35)의 Android 통합1개도 통과했습니다. 고유한 테스트 DB로 저장/이동/필기 완료/DB 재개를 검사하며 실제 아이 진도를 사용하지 않습니다. 실행 중인 대상 ID를 확인한 다음 `tool/android.ps1 test integration_test/app_flow_test.dart --device-id=<에뮬레이터ID> --timeout=120s`로 실행합니다. PowerShell에서는 옵션의 값에 `=`를 사용합니다.

## APK와 설치

2026-10-15 사용자 승인으로 기존 서명 보류를 해제하고 **APK 직접 공유용 전용 키**를 생성했습니다. 릴리스 빌드는 로컬 `android/key.properties`를 읽어 자동 서명합니다. Play Store 업로드는 하지 않습니다.

최신 테스트·로컬 APK·기존 배포 APK는 PROGRESS의 해당 기록을 확인하세요. **Git 푸시와 APK 업로드는 사용자가 명시적으로 요청했을 때만 수행합니다.** 로컬 빌드와 GitHub 배포를 구분합니다. 서명 설정은 [Flutter 공식 서명 안내](https://docs.flutter.dev/deployment/android#sign-the-app)를 따릅니다. Flutter test와 APK build는 생성 파일 충돌을 피하도록 순차 실행하세요.

1~12화 사건 연출·그림 저장 복구·녹음 우선 재생 연결 반영 후 analyze 문제 0 / 전체 **297개 테스트 통과**. 서명 APK `1.0.0 (214232596)`(139.6MiB) 빌드·v2 서명 검증 통과. 테스트/빌드 로컬 로그는 `docs/recorded-test.log`, `docs/recorded-build.log`, Git에 포함한 결과 요약은 `docs/recorded_build.json`과 PROGRESS에 있습니다. 후속 사용자 요청으로 **[APK 다운로드](https://github.com/duafyd/kkoma_learning/releases/download/apk-1.0.0-214232596/kkoma-1.0.0-214232596.apk)** / [Release](https://github.com/duafyd/kkoma_learning/releases/tag/apk-1.0.0-214232596)에 공개했으며 서버 크기·SHA256 일치를 확인했습니다. 실제 Android 설치·소리·프레임·저사양 메모리 검증은 남아 있습니다. 녹음 재생 구조는 구현했지만 고정 대본 기준 녹음 609개와 배경음악은 미제작이며 현재 음성은 오프라인 TTS를 사용합니다.

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

테스트는 필기 방향/부분/터치/떨림, 4연령×12화 완주, 힌트/도움/분기/저장 복구, 빠른 중복 입력, 설정 동시 쓰기, 하루 사용 시간, PNG 동시 저장/다시 열기/삭제 및 실패 롤백, 중단된 삭제/제출 복구, 녹음 우선/실패 TTS 대체/반복/취소/생명주기, 음성 중복/무음/누락/시간 초과, 태블릿 3크기 전체 화면을 검증합니다. 최신 실제 실행 결과는 PROGRESS와 로컬 `docs/recorded-test.log`를 확인하세요. 오디오는 호스트의 채널 mock 테스트이며 Android 기기 재생 검증과 구분합니다.

2026-10-15 필기 확장 검증 기록은 `docs/tracing-expansion-test.log`에 있습니다. 모든 경로의 4연령 정상 입력, 원형/교차 획의 역방향·부분 입력, 두 자리 숫자 순서·중단 후 복원, 연령별 다음 글자 선택을 검증합니다. 경로 검토 이미지 재생성: `flutter test tool/tracing_preview_test.dart` (Windows에서는 먼저 TEMP/TMP를 `.tool_tmp`로 설정).

명세 대비 구현 범위와 누락 사항은 [docs/REQUIREMENTS_STATUS.md](docs/REQUIREMENTS_STATUS.md)에 정리했습니다.

`dart run tool/audit_content.dart`는 콘텐츠 참조·배경·캐릭터·이야기 효과음 리소스를 검사하고 `docs/content_audit.json`을 생성합니다. `--require-recordings`를 추가하면 녹음이 누락될 때 실패합니다. 현재 고정 대본 **671개에 대한 등록 음원은 0개**이며 배경음악도 미제작입니다. 대본은 `export_voice_scripts.dart`, 스토리 연기 지침은 `export_story_studio.dart`로 재생성합니다. `generate_ai_auditions.dart`의 기본 실행은 계획만 만들며 API를 호출하지 않습니다. 유료 생성은 계속 보류합니다. 이야기 효과음 3개는 `dart run tool/generate_story_sounds.dart`로 재현할 수 있는 자체 합성 소리이며 녹음 대사가 아닙니다. 시스템 이모지와 TTS 발음은 기기마다 다를 수 있습니다.

다른 PC로 소스를 옮겨 개발하거나 Git에 올리기 전에는 `tool/verify-source.ps1`을 실행합니다. 비공개 파일 경로, analyze/전체 테스트, 생성 자료 일치와 콘텐츠 감사를 묶어 검사하며 자동 푸시나 APK 업로드는 하지 않습니다. [소스 전달·보류 항목·다음 검수](docs/SOURCE_HANDOFF.md)를 참고하세요.

실제 Galaxy Tab의 필기·음성·프레임/메모리·재부팅/업데이트, 아동 사용성, 교육 전문가의 문항/필순/발음 검수, 정식 앱 ID/서명은 미완료입니다. 앱 ID는 `com.example.flutter_application_1`을 유지했습니다.

패키지 API는 공식 [Riverpod](https://pub.dev/packages/flutter_riverpod), [go_router](https://pub.dev/packages/go_router), [sqflite](https://pub.dev/packages/sqflite), [path_provider](https://pub.dev/packages/path_provider), [flutter_tts](https://pub.dev/packages/flutter_tts) 문서와 설치된 소스를 확인했습니다. 불필요한 템플릿 cupertino_icons는 제거했습니다.
