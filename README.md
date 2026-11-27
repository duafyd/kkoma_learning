# 꼬마런닝 · 오늘의 가게

만 2~5세가 가게 주인이 되어 과일이나 빵 주문을 처리하는 태블릿 학습지 프로토타입입니다. 이번 버전에서 확인할 점은 아이가 안내를 듣고 스스로 첫 행동을 할 수 있는지, 새 주문을 시작했을 때 활동이 충분히 달라지는지입니다.

[첫 버전 기획안 · 모모의 동네](docs/PRODUCT_PLAN.md) · [과일 가게 첫 한 판 · 여섯 장면 보기](docs/FRUIT_ROUND.md)

## 갤럭시탭에서 모모의 사과 주문 체험

[Godot 시제품 APK 받기](https://raw.githubusercontent.com/duafyd/kkoma_learning/prototype/worksheet/trial/momo-apple-arm64.apk) · [첫 화면](docs/preview/apple-order.jpg) · [완료 화면](docs/preview/apple-done.jpg)

그림 주문표를 보고 사과를 톡 누르거나 바구니로 끌어 놓습니다. 바구니를 빗나가면 다시 시도할 수 있습니다. 소리를 꺼도 이동 시범과 수량, 모모의 표정으로 끝까지 놀 수 있습니다. 무음 상태의 ‘다시 보기’는 시범을 다시 보여 주며 소리 선택은 다음 실행에도 적용됩니다. 한국어 주문·수 세기·칭찬 음성은 APK에 들어 있습니다. `다시 듣기`, `소리 켜짐/꺼짐`, 완료 후 `한 번 더 놀기`를 사용할 수 있습니다.

모모 음성 0.3은 선택된 A 목소리로 주문을 1.35초에 읽습니다. [현재 APK 음성 듣기](https://raw.githubusercontent.com/duafyd/kkoma_learning/prototype/worksheet/docs/preview/voices/momo-a-warm.mp3) · [직전 A 음성 듣기](https://raw.githubusercontent.com/duafyd/kkoma_learning/prototype/worksheet/docs/preview/voices/momo-a.mp3)

Godot 4.7.2에서 [godot/project.godot](godot/project.godot)을 가져와 **F5(프로젝트 실행)** 로 시작합니다. Android 시험판은 arm64 디버그 빌드이며 앱 ID는 `org.kkoma.prototype.applemarket`입니다.

## 브라우저 학습지 실행

[프로토타입 ZIP 받기](https://github.com/duafyd/kkoma_learning/archive/refs/heads/prototype/worksheet.zip). 압축을 풀고 브라우저로 `index.html`을 엽니다. 별도 패키지 설치나 빌드 과정 없이 동작합니다. 로컬 서버에서 확인할 때는 이 디렉터리에서 `python -m http.server 8000`을 실행한 뒤 `http://localhost:8000`을 엽니다.

1. 보호자가 연령을 고르고 아이가 과일 가게나 빵집을 선택합니다.
2. **골고루 놀기**는 한글·영어·수학·관찰·규칙을 하나씩 섞은 다섯 장입니다. 과목을 직접 고르면 세 장입니다.
3. 틀렸을 때 나오는 도움말과 **다시 듣기**를 확인합니다. 만 5세 수학에서는 물건을 담거나 덜어낸 다음 **상자 보내기**를 누릅니다.
4. **새 주문으로 또 놀기**를 눌러 다음 판을 비교합니다. 같은 브라우저에서 최근 문항 조합을 기억합니다. 한국어·영어 발음은 기기에서 제공하는 음성을 사용합니다.

## 이어서 작업하기

작업 브랜치는 `prototype/worksheet`입니다. 새 채팅에서는 **“duafyd/kkoma_learning의 prototype/worksheet 브랜치에서 docs/HANDOFF.md를 읽고 이어서 작업해”**라고 하면 됩니다. [현재 상태와 검토 항목](docs/HANDOFF.md) · [기존 앱 보관 브랜치](https://github.com/duafyd/kkoma_learning/tree/archive/original-app)

## 갤럭시탭 에셋 시안

[모모와 가게 · 에셋 한눈에 보기](docs/preview/momo.jpg) · [움직임과 효과음 · 8초 MP4](docs/preview/momo.mp4). 캐릭터와 색감을 먼저 검토하기 위한 시안입니다.
