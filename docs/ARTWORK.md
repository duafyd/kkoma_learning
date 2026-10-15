# 그림책 에셋 제작 기록

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
