import 'story_models.dart';

enum ScenePropKind {
  star,
  flower,
  fruit,
  ticket,
  beacon,
  stone,
  drop,
  page,
  lantern,
  leaf,
  comet,
  book,
}

/// Authored, optional cause-and-effect moments. Never replace a learning task.
class ScenePlay {
  final ScenePropKind kind;
  final String object, invitation, response;
  const ScenePlay(this.kind, this.object, this.invitation, this.response);

  int count(int level) => level == 2
      ? 1
      : level == 3
      ? 2
      : 3;

  static ScenePlay? forSnapshot(StorySnapshot s) {
    final episode = s.episodeId ?? s.episode + 1;
    final opening = s.sceneId == null
        ? s.scene == 0
        : s.sceneId == 'ep$episode-start';
    return opening &&
            s.phase == StoryPhase.dialogue &&
            episode >= 1 &&
            episode <= moments.length
        ? moments[episode - 1]
        : null;
  }

  static const moments = [
    ScenePlay(
      ScenePropKind.star,
      '작은 불빛',
      '책장에 숨은 별빛을 톡, 깨워 볼까?',
      '책 밑에 큰 별조각이 보여! 어떤 모양인지 친구와 살펴보자.',
    ),
    ScenePlay(
      ScenePropKind.flower,
      '꽃봉오리',
      '잠든 꽃봉오리를 톡톡 피워 줘.',
      '작은 꽃들이 깨어났네! 큰 꽃문은 아직 닫혀 있어. 안쪽 별조각을 꺼내러 가자.',
    ),
    ScenePlay(
      ScenePropKind.fruit,
      '글자 열매',
      '반짝이는 열매를 바구니에 모아 줘.',
      '떨어진 열매를 모았네! 별조각은 아직 가지에 걸려 있어. 바구니를 함께 채우자.',
    ),
    ScenePlay(
      ScenePropKind.ticket,
      '기차표',
      '바람에 날린 기차표를 잡아 줘!',
      '기차표를 찾았어! 별조각이 있는 지붕에 닿으려면 기차 표지부터 고치자.',
    ),
    ScenePlay(
      ScenePropKind.beacon,
      '등대 불빛',
      '작은 불빛을 모아 등대를 깨워 줘.',
      '작은 불빛이 켜졌어. 아직 바위틈의 별조각은 안 보여. A 등불로 비춰 주자.',
    ),
    ScenePlay(
      ScenePropKind.stone,
      '징검돌',
      '빛나는 돌을 톡, 다리로 보내 줘.',
      '돌들을 준비했어! 다리 건너 별조각에 닿도록 빈자리에 놓아 주자.',
    ),
    ScenePlay(
      ScenePropKind.drop,
      '물감 방울',
      '흩어진 물감 방울을 톡, 모아 줘.',
      '물감을 모았어! 별조각이 있는 화단은 아직 뒤섞였네. 색과 모양을 정리하자.',
    ),
    ScenePlay(
      ScenePropKind.page,
      '종이 표지',
      '휙휙과 날아간 종이 표지를 잡아 줘.',
      '종이 표지를 잡았네! 바구니 밑 별조각을 꺼내도록 휙휙과 함께 정리하자.',
    ),
    ScenePlay(
      ScenePropKind.lantern,
      '길잡이 등불',
      '등불을 켜서 숲속 길을 밝혀 줘.',
      '숲길 입구가 보여! 안쪽 별조각을 찾으러 어느 길로 가고 싶어?',
    ),
    ScenePlay(
      ScenePropKind.leaf,
      '반짝 잎사귀',
      '나무가 들려주는 이야기를 톡, 깨워 줘.',
      '잎사귀가 젖은 책을 가리켜! 책장 사이 별조각이 보여. 책을 함께 말리자.',
    ),
    ScenePlay(
      ScenePropKind.comet,
      '길잡이 빛',
      '친구들과 하늘 계단의 길잡이 빛을 깨워 줘.',
      '길잡이 빛이 켜졌어! 계단 끝 별조각까지 가도록 별자리를 이어 보자.',
    ),
    ScenePlay(
      ScenePropKind.book,
      '별빛 책',
      '떨어진 책을 톡, 책장에 돌려놓아 줘.',
      '떨어진 책을 올려놓았어! 마지막 별조각은 아직 서랍 안이야. 앞을 함께 정리하자.',
    ),
  ];
}
