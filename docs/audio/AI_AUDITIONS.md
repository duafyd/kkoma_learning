# 캐릭터별 AI 연기 음성 시연

사용자는 2026-10-16에 **캐릭터별 AI 연기 음성**을 선택했다. 인물별 한 장면씩 4개의 짧은 시연으로 캐스팅과 한국어 발음·감정·호흡을 먼저 확인한다. 현재 실제 음원은 0개다. API 키·유료 사용 승인 없이 호출하지 않았으며, 제작 도구의 mock 테스트는 실제 음원 생성/청취 검증이 아니다.

**현재 비용 결정:** 사용자가 같은 날 유료 시연 생성 비용을 보류했다. 새로운 명시 요청 전까지 실제 API 호출과 --execute를 수행하지 않는다. 무료 계획/앱 개발은 계속할 수 있다.

## 준비된 시연

`ai_audition_plan.json`에는 실제 대상 대본 4개, 인물, 목소리 후보, 연기 지시, 요청 본문이 있다. 모아/marin, 루루/coral, 토토/cedar, 휙휙/ash는 **미청취 시연 후보**이며 최종 캐스팅이 아니다.

```powershell
# 무료·오프라인 계획 생성: 키를 읽거나 네트워크에 접속하지 않는다.
dart run tool/generate_ai_auditions.dart
```

실제 호출은 별도 비용 승인과 이 PC의 `OPENAI_API_KEY` 환경변수가 준비된 다음에만 `--execute`로 실행한다. 키 값은 채팅·소스·APK에 넣지 않는다. 이번에는 실행하지 않았다. 요청은 최대 4개이며 자동 재시도하지 않는다. 각 요청의 출력 토큰 상한은 1024지만 이것을 달러 결제 한도로 표현하지 않는다. 실제 비용은 당시 입력/출력 토큰 단가와 계정 사용량으로 확인한다.

생성 파일은 `.tool_tmp/voice-auditions`에 WAV와 receipt JSON으로 저장한다. 반환 원문, 요청 원문과의 일치 여부, 모델/목소리, 토큰 사용량, PCM 경고, 청취 미검수 상태를 함께 남긴다. 기존 파일은 덮어쓰지 않으며 앱 에셋에 자동으로 넣지 않는다. 원문 불일치·잘린 응답·무음·발음·감정 연기를 확인한 다음에만 `assets/audio/<id>.wav`로 등록하고 번들/콘텐츠 검사를 수행한다.

## 공식 API 확인과 범위

2026-10-16의 [공식 음성 Chat Completions 문서](https://developers.openai.com/api/docs/guides/audio-chat-completions)와 [요청 스키마](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create)를 기준으로 일반 REST 요청의 `gpt-audio-1.5`, text/audio 출력, WAV 및 인물별 지시를 구성했다. 계정의 실제 접근 권한·한국어 연기 품질은 유료 시연 전에는 검증할 수 없다.

[기존 TTS 모델의 종료 일정](https://developers.openai.com/api/docs/deprecations)을 확인했으므로 해당 구형 모델을 새 기본 제작 경로로 고정하지 않았다. 이 도구는 **개발 PC에서 사전 음원을 제작하는 후보 도구**이며 앱에 Realtime API·서버·계정·네트워크 의존성을 추가하지 않는다. [후보 모델과 가격](https://developers.openai.com/api/docs/models/gpt-audio-1.5)은 실제 생성 전에 재확인한다.

생성 음원은 AI 음성임을 보호자에게 안내한다. 보호자 설정에 AI 제작 방식과 미준비 장면의 기기 TTS 대안을 표시했다. 이 안내와 파일 검사만으로 성우급 품질 또는 전문가 검수가 끝난 것은 아니다. 본문 연기는 [STORY_DIRECTION.md](STORY_DIRECTION.md)를 따른다.
