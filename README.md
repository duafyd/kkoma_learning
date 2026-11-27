# 꼬마런닝 · 오늘의 가게

만 2~5세가 가게 주인이 되어 과일이나 빵 주문을 처리하는 태블릿 학습지 프로토타입입니다. 이번 버전에서 확인할 점은 아이가 안내를 듣고 스스로 첫 행동을 할 수 있는지, 새 주문을 시작했을 때 활동이 충분히 달라지는지입니다.

## 실행

[프로토타입 ZIP 받기](https://github.com/duafyd/kkoma_learning/archive/refs/heads/prototype/worksheet.zip). 압축을 풀고 브라우저로 `index.html`을 엽니다. 별도 패키지 설치나 빌드 과정 없이 동작합니다. 로컬 서버에서 확인할 때는 이 디렉터리에서 `python -m http.server 8000`을 실행한 뒤 `http://localhost:8000`을 엽니다.

1. 보호자가 연령을 고르고 아이가 과일 가게나 빵집을 선택합니다.
2. **골고루 놀기**는 한글·영어·수학·관찰·규칙을 하나씩 섞은 다섯 장입니다. 과목을 직접 고르면 세 장입니다.
3. 틀렸을 때 나오는 도움말과 **다시 듣기**를 확인합니다. 만 5세 수학에서는 물건을 담거나 덜어낸 다음 **상자 보내기**를 누릅니다.
4. **새 주문으로 또 놀기**를 눌러 다음 판을 비교합니다. 같은 브라우저에서 최근 문항 조합을 기억합니다. 한국어·영어 발음은 기기에서 제공하는 음성을 사용합니다.

## 이어서 작업하기

작업 브랜치는 `prototype/worksheet`입니다. 새 채팅에서는 **“duafyd/kkoma_learning의 prototype/worksheet 브랜치에서 docs/HANDOFF.md를 읽고 이어서 작업해”**라고 하면 됩니다. [현재 상태와 검토 항목](docs/HANDOFF.md) · [기존 앱 보관 브랜치](https://github.com/duafyd/kkoma_learning/tree/archive/original-app)
