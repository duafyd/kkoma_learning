# 꼬마런닝 Android 1.0 후보

[현재 상태와 인수인계](HANDOFF.md) · [1.0 제작 계획](PRODUCTION_PLAN.md)

## 설치와 업데이트

갤럭시탭에서 [APK 다운로드](https://raw.githubusercontent.com/duafyd/kkoma_learning/prototype/worksheet/trial/momo-apple-arm64.apk)를 열어 설치합니다. 내려받은 APK를 열 때 Android가 해당 앱의 설치 권한을 요청하면 이번 설치에 사용한 브라우저나 파일 앱에서 허용합니다. 지원 빌드는 64비트 ARM용이며 최소 Android 버전은 7.0입니다.

이 후보는 앱 ID `org.kkoma.prototype.applemarket`와 기존 테스트 서명을 사용합니다. 기존 테스트판을 사용 중이면 설치 화면에서 **업데이트**를 선택하고 앱을 지우지 않은 상태에서 진행합니다. Godot의 저장 호환 검사는 통과했으며 실제 갤럭시탭 업데이트 결과는 실기기 검수 때 기록합니다.

앱을 열어 처음이라면 연령을 고릅니다. 이전에 중단한 놀이가 있으면 해당 버튼을 눌러 이어갑니다. 과일 가게와 빵집에는 각각 다섯 장, 독립 과목과 따라 쓰기에는 각각 세 장으로 구성된 판이 열립니다. 주문 음성과 그림은 APK에 들어 있습니다.

## 빌드와 확인

Godot 4.7.2와 같은 버전의 Android release 템플릿, Android SDK, JDK를 준비합니다. Godot 편집기에서 SDK/JDK를 지정하고, 배포 경로에 맞는 키의 경로·별칭·암호를 편집기 내보내기 자격 증명 또는 환경 변수로 전달합니다. 직접 설치용 후보를 이전 시험판에 덮어쓰려면 같은 인증서를 사용합니다. 키 파일과 암호는 저장소 밖에 보관합니다.

```sh
mkdir -p godot/build
godot --headless --editor --path godot --import
godot --headless --path godot --export-release "Galaxy Tab" build/momo-1.0-rc1.apk
```

키를 환경 변수로 넘길 때 Godot이 읽는 이름은 `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`입니다.

내보낸 APK는 Android 빌드 도구의 `apksigner verify --print-certs`와 `aapt dump badging`으로 검사합니다. 인수인계의 네 Godot 회귀 검사와 빌드에 포함된 주문·음성 목록을 연결해 확인합니다. 출시 후보에는 검사용 스크립트가 제외됩니다. 패키지 자체를 재검사할 때는 APK의 `assets/` 접두사를 걷어 낸 ZIP을 Godot의 `--main-pack`으로 열고, 저장소의 검증 스크립트를 절대 경로로 지정합니다.

## 실기기 검토와 공개 배포

검토 항목은 첫 실행, 이전 테스트판 위로 업데이트, 비행기 모드 재실행·이어하기, 만 2세 조작, 만 5세 여러 획 쓰기, 음량입니다. 확인한 기기·Android 버전·문항 ID·관찰 내용을 [인수인계](HANDOFF.md)에 추가하고 개선 사항은 다음 빌드에 반영합니다.

현재 인도 경로는 APK 직접 설치입니다. Google Play 공개 배포 시 앱 등록 주체와 서명을 정하고 AAB와 스토어 자료를 준비합니다. 공개 배포용 인증서가 기존 시험판과 다를 경우 설치 경로와 진도 이전을 따로 검증합니다.

### 스토어 소개 초안

**앱 이름** · 꼬마런닝 모모의 놀이

**짧은 소개** · 모모와 함께 가게를 열고 한글·영어·숫자를 손가락으로 놀아요.

**설명** · 만 2~5세를 위한 갤럭시탭 가로 놀이 앱입니다. 한글 이름표 고르기, 영어 주문 듣기, 숫자 세기와 따라 쓰기를 각각 즐길 수 있습니다. 과일 가게와 빵집에서는 모모의 주문에 맞춰 물건을 담고, 그림을 맞추고, 규칙을 완성합니다. 설치 후에는 인터넷 연결 없이 놀이를 시작하고, 중간에 멈춘 자리를 이어갈 수 있습니다.

[놀이마당](preview/play-menu-07.jpg) · [빵집](preview/bakery-07.jpg) · [한글 따라 쓰기](preview/writing-07.jpg)
