# 그림책 에셋 제작 기록

## 6~12화 전용 사건 그림과 두 결말

내장 imagegen의 **기존 스타일 그림 참조 생성**으로 시작 장면 7장을 만들고, 각 시작 그림을 **편집**해 성공 장면 8장을 만들었다. 최종 15장의 정확한 프롬프트·참조·원본 출력 경로는 [finale_story_prompts.json](finale_story_prompts.json)에 있다. 원본 출력을 보존하고 프로젝트로 복사했다. 외부 API/CLI 모드는 사용하지 않았다.

| 프로젝트 경로 (`assets/story/`) | 사건 |
|---|---|
| `ep6-bridge.png` / `ep6-built.png` | 다리의 세 빈자리 / 세 돌 완성 |
| `ep7-faded.png` / `ep7-color.png` | 옅어진 종이꽃 / 빨강·파랑·노랑 정원 |
| `ep8-scattered.png` / `ep8-sorted.png` | 흩어진 페이지 / 가지런한 바구니 |
| `ep9-fork.png` / `ep9-joined.png` | 세 갈래 길 / 이어진 빛길 |
| `ep10-damp.png` / `ep10-open.png` | 젖어 붙은 책장 / 펼쳐진 성장 그림 |
| `ep11-empty.png` / `ep11-lit.png` | 빈 별자리판 / 다섯 별 점등 |
| `ep12-return.png` / `ep12-flowers.png` / `ep12-stars.png` | 돌아온 도서관 / 꽃 방 / 별 방 |

모두 1536×1024 PNG이며 원본과 Flutter 합성 화면을 열어 확인했다. 총 번들 배경은 30장(화별 26 + 공용 4), 아틀라스 2장과 효과음 3개는 기존 리소스를 재사용한다. 그림 안 빈 표지판의 글자를 생성 이미지에 의존하지 않는다. 학습 대상 글자/수량은 별도 Flutter 카드에 정확하게 표시한다. 돌·책·싹·나무·빨강/파랑 꽃은 CustomPainter의 명확한 벡터 그림이다. 120장면에 모두 다른 배경이나 새 캐릭터 프레임을 제작한 것은 아니다.

돌 세 개와 별 다섯 개는 별도 조작판에서 끌기 또는 터치로 차례로 놓으며 상태를 저장한다. 성공 저장 후 사건 그림을 교체한다. 12화는 저장된 방 선택에 따라 장식 그림이 달라지며, 가구 자유 배치 편집기는 아니다. 호스트 캡처 24장: `docs/screenshots/ep6-*`~`ep12-*` 중 `before/after-tablet`, 9화 세 길, 12화 꽃/별 결말, 7화 그림 도구, 폰/낮은 가로 화면과 만 2세 탐색. 호스트 캡처를 Android 기기 검증으로 간주하지 않는다. 좁거나 낮은 화면의 조작/답 영역은 스크롤한다.

## 4·5화 소리 기차와 알파벳 등대

내장 imagegen의 기존 그림 참조 생성과 편집 모드 사용. 참조는 `stage-coast.png`, 최종 점등 편집은 `ep5-dark.png`. 정확한 프롬프트·참조·출력 경로는 [episode_train_lighthouse_prompts.json](episode_train_lighthouse_prompts.json)에 기록했다. 외부 API/CLI 모드나 앱 실행 중 AI는 사용하지 않는다.

| 최종 프로젝트 경로 | 용도 |
|---|---|
| `assets/story/ep4-station.png` | 아직 씨앗을 싣지 않은 기차와 닫힌 승강장 문 |
| `assets/story/ep4-ready.png` | 씨앗 바구니를 실은 두 칸과 열린 승강장 문 |
| `assets/story/ep5-dark.png` | 가까이 본 꺼진 등대와 사과 탁자 |
| `assets/story/ep5-beam-v2.png` | 같은 등대·같은 구도에서 켜진 불과 다리를 향한 빛 |

각 1536×1024 PNG. 첫 점등 출력 `ep5-lit.png`는 원경으로 돌아가 장면 연속성을 해쳤으므로 채택하지 않았다. 소스로 보존하되 APK 번들에는 제외하고 가까운 등대 원본을 편집한 v2만 사용한다. 기차 그림의 방향 때문에 '앞 칸'이 모호해지는 문제는 '왼쪽 가 → 오른쪽 나' 안내로 정리했다. 기차의 두 표지가 크롭되거나 캐릭터 뒤에 가리지 않도록 공통 cover 초점 데이터와 기차 장면 캐릭터 크기를 조정했다. 글자 표지 가/나/A는 실제 Flutter Jua 글꼴로 얹으며 생성 이미지의 문자에 의존하지 않는다.

기존 캐릭터 포즈/유한 움직임을 재사용한다. 실제 기차 운행·문짝 관절·등대 광원 물리 애니메이션을 구현한 것은 아니며, 저장된 성공 상태에 따른 사건 그림 교체다. 사과/바나나 카드 그림은 CustomPainter의 단순 명확한 과일 도형이고 녹음/청취 검수 완료를 뜻하지 않는다. 최종 호스트 캡처는 `docs/screenshots/ep4-*`, `ep5-*`다.

## 2·3화 꽃문과 자음 열매

내장 imagegen 도구의 기존 그림 참조 생성 모드로 `stage-forest.png`의 그림체·세계관을 이어 제작했다. CLI/API 대체 모드는 사용하지 않았다. 정확한 프롬프트·참조·저장 경로는 [episode_garden_tree_prompts.json](episode_garden_tree_prompts.json)에 있다. 기존 그림을 덮어쓰지 않았다.

| 프로젝트 저장 경로 | 용도 |
|---|---|
| `assets/story/ep2-gate.png` | 모음 꽃 이름표가 있는 닫힌 꽃문 |
| `assets/story/ep2-open.png` | 꽃문이 열린 뒤 보이는 자음 나무 길 |
| `assets/story/ep3-tree.png` | 빈 바구니와 낮은 글자 열매 가지 |
| `assets/story/ep3-seeds.png` | 씨앗 꾸러미를 담은 바구니와 소리 기차로 가는 길 |

각 1536×1024 PNG이며 네 그림을 실제로 열어 구도·분리된 캐릭터 공간·일관성을 확인했다. 그림 안의 이름표는 빈 채로 제작하고, `storyLetterSigns` 데이터와 `StoryLetterSigns`의 Flutter TextPainter로 ㅏ/ㅓ/ㅗ/ㅜ, ㄱ/ㄴ/ㅁ을 올린다. 배경과 같은 cover 크롭/정렬을 적용하며 폰트는 번들 Jua다. 생성 이미지의 글자 정확도에 학습을 의존하지 않는다. 열린 문·열매 이름표 위치는 최종 호스트 렌더에서 조정했다. 퀴즈 카드에는 별도로 큰 글자와 음가/이름 라벨을 표시한다. 세기 과제는 배경 꾸러미 수가 아닌 작은 판 위 씨앗 3개만 대상으로 한다.

정답 또는 도움 통과가 저장되면 꽃문/씨앗 바구니의 완료 그림으로 바뀐다. 문짝 관절이 회전하거나 열매를 직접 드래그해 따는 애니메이션은 아니다. 기존 캐릭터 인사·찾기·가리키기·성공 반응을 재사용한다. 당시 후속 대상이던 6~12화도 위 최신 기록처럼 전용 삽화 연결을 완료했다.

## 1화 사건별 배경과 탐색 포즈

내장 imagegen 편집 모드로 기존 도서관/캐릭터를 참조해 1화 전용 에셋을 추가했다. 정확한 입력·프롬프트와 출력 경로는 [episode_one_prompts.json](episode_one_prompts.json), 칸 분리 재편집은 [episode_one_atlas_fix_prompt.json](episode_one_atlas_fix_prompt.json)에 기록했다. 런타임 AI나 추가 패키지는 없다.

| 프로젝트 저장 경로 | 용도 |
|---|---|
| `assets/story/ep1-quiet.png` | 별빛이 빠진 빈 책과 바람에 흩어진 종이, 안전하고 따뜻한 시작 |
| `assets/story/ep1-search.png` | 낮은 책장/러그에서 반짝이는 조각을 찾는 다른 구도 |
| `assets/story/ep1-map.png` | 열린 책 위 꽃밭 지도와 돌아온 빛 |
| `assets/story/cast-search-v3.png` | 찾는 루루, 세는 토토, 가리키는 모아, 미안해하는 휙휙의 추가 포즈 |

배경은 각각 1536×1024, 최종 탐색 아틀라스는 1280×1280. 첫 출력의 여우가 옆 칸까지 넘어간 문제를 실제 렌더에서 찾아 imagegen으로 네 칸 사이 여백을 늘려 수정했다. 중앙 가로/세로 띠에 불투명 캐릭터 픽셀이 없는지 회귀 검사한다. 화면의 세기 과제는 삽화 속 장식 별이 아닌 별도 작은 판의 도형만 대상으로 한다. 도형은 CustomPainter로 그려 정답 그림과 개수를 검사한다. 새 배경은 1화만 사용하며 다른 11화의 사건별 삽화 제작 완료를 의미하지 않는다. 포즈가 바뀐 정적 캐릭터에 유한 Transform 움직임을 적용하는 방식이며 관절·프레임별 걷기/입모양 애니메이션은 아니다.

## 현재: 움직이는 그림책용 레이어

내장 imagegen 모드로 기존 그림을 참조해 인물이 빠진 배경 4장과 2×2 투명 캐릭터 아틀라스를 제작했다. CLI/API 대체 모드는 사용하지 않았다. 원본 PNG는 덮어쓰지 않고 보존했다. 정확한 도구 입력·프롬프트는 [story_motion_prompts.json](story_motion_prompts.json)에 저장했다.

| 프로젝트 저장 경로 | 용도 |
|---|---|
| `assets/story/stage-library.png` | 인물이 없는 도서관 |
| `assets/story/stage-forest.png` | 인물이 없는 숲/정원 |
| `assets/story/stage-coast.png` | 인물이 없는 해안/기차/다리 |
| `assets/story/stage-night.png` | 인물이 없는 비/바람/밤 |
| `assets/story/cast-v2.png` | 2×2 투명 아틀라스: 좌상 루루, 우상 토토, 좌하 모아, 우하 휙휙 |

배경은 각 1536×1024, 아틀라스는 1280×1280. 실제 출력을 눈으로 확인했고 네 칸 각각의 투명/불투명 픽셀·모든 화자 매핑·PNG 디코딩을 검사한다. 런타임에서는 각 칸을 ClipRect로 분리해 위치·기울기·크기를 독립적으로 바꾼다. 오른쪽 친구는 왼쪽을 향하게 뒤집는다. 동작은 등장/인사/기쁨의 유한 애니메이션이며 프레임별 걷기·입모양·관절 애니메이션은 아직 아니다.

기존 합성 삽화 네 장은 아래 이전 제작 기록과 함께 소스로 보존하지만, 새 앱은 분리된 배경/캐릭터만 번들해 이전 그림의 중복 용량을 피한다. 1~12화에는 사건별 배경 26장을 추가했고 공용 네 테마도 유지한다. 120개 모든 장면의 개별 삽화를 제작한 것은 아니다.

효과음은 `tool/generate_story_sounds.dart`의 결정적 난수/사인파 합성으로 직접 제작한 WAV 세 개다. 다운로드한 녹음/음악 샘플은 사용하지 않았다. 22050Hz, PCM16 mono, 0.28/0.36/0.66초, fade-in/out 및 peak 0.35FS 이하. 경로는 `assets/audio/effects/{pageTurn,friend,sparkle}.wav`. 실제 Android 기기 음량·청취 검증은 별도다.

## 이전: 정적인 합성 삽화 1차 기록

2026-10-15, 사용자 첨부의 따뜻한 아동용 그림책 분위기를 참고해 내장 imagegen 도구로 신규 제작했다. 외부 이미지 검색 결과나 첨부 이미지 자체를 앱에 복사하지 않았다. 앱 실행 중 AI 생성/인터넷 연결은 없다.

| 저장 경로 | 사용 배경 |
|---|---|
| `assets/story/library.png` | 도서관, 홈 이야기 배너 |
| `assets/story/forest.png` | 숲, 정원 |
| `assets/story/coast.png` | 기차, 등대, 다리 |
| `assets/story/night.png` | 바람, 비, 밤하늘 |

각 1536×1024 PNG. 네 장을 공유하며 120개 장면별 삽화 제작 완료를 의미하지 않는다. 인물과 배경이 합쳐진 정적 삽화이므로 개별 캐릭터 표정·동작·장면별 사건 연출은 추가 제작이 필요하다. 현재는 배경/화자 전환에 짧은 페이드, 설정에 따른 애니메이션 끄기를 제공한다. 렌더는 비율을 유지하는 cover 방식이며 좁은 영역에서는 가장자리가 잘릴 수 있다. 대사·선택지·진행 상태는 이미지에 굽지 않고 Flutter 위젯으로 표시한다.

공통 프롬프트:

> Use case: illustration-story. Production landscape background illustration for an offline Korean educational picture-book app for children ages 2–5. Beautiful premium hand-painted gouache with soft 3D clay depth, lush rounded forms, rich warm illumination, tactile paper and fur, polished cinematic storybook art. Wide 3:2 landscape, scene fills frame, no border, no text, no letters, no logos, no UI. Consistent adorable original cast: Lulu a small orange fox with cream muzzle and fluffy tail wearing a teal vest and tiny satchel; Toto a small sage-green turtle with moss shell and ochre scarf; Moa a tiny human-like fairy with chestnut bob hair, lavender dress and glowing star wand. Friendly expressive faces and rounded silhouettes. Characters in lower middle, large enough to see on phone, keep lowest 15% calm for an app dialogue overlay. No scary characters, no flat geometric placeholder art.

장면별 프롬프트 주제:

- library: 구름 위 도서관, 휘어진 목재 책장, 열린 마법 책, 창밖 별자리, 호박색·청록·라벤더 조명.
- forest: 나무 아치와 꽃 정원, 반딧불이·버섯·나무굴 책방, 황금 별빛 길과 따뜻한 햇살.
- coast: 산호색 등대, 청록색 물과 다리, 멀리 달리는 기차, 별빛을 따라 걷는 친구들.
- night: 비가 그친 평화로운 숲, 등불과 물웅덩이, 떠오른 책·별자리·웃는 바람 친구. 무섭지 않은 밤.

네 그림 모두 눈으로 확인했고 프로젝트 경로로 복사했다. 최종 화면 캡처는 `docs/screenshots/`에 있다. 캡처는 Flutter 호스트 렌더이며 Android 실기기 캡처가 아니다.

## 글꼴

둥근 한글 글꼴 Jua Regular를 앱에 포함했다. 출처: [Google Fonts Jua](https://github.com/google/fonts/tree/main/ofl/jua). Copyright 2018 The Jua Project Authors. SIL Open Font License 1.1 전문은 `assets/fonts/OFL.txt`에 앱 에셋으로 포함한다. 글꼴 파일을 수정하지 않았다.
