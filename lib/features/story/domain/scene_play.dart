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
      '별 조각',
      '책장에 숨은 별빛을 톡, 깨워 볼까?',
      '별빛이 돌아왔어! 이제 친구들을 만나러 가자.',
    ),
    ScenePlay(
      ScenePropKind.flower,
      '꽃봉오리',
      '잠든 꽃봉오리를 톡톡 피워 줘.',
      '꽃길이 깨어났어. 모음 문 너머에는 무엇이 있을까?',
    ),
    ScenePlay(
      ScenePropKind.fruit,
      '글자 열매',
      '반짝이는 열매를 바구니에 모아 줘.',
      '열매가 모였어! 루루와 글자 씨앗을 찾아보자.',
    ),
    ScenePlay(
      ScenePropKind.ticket,
      '기차표',
      '바람에 날린 기차표를 잡아 줘!',
      '표를 찾았어! 기차의 소리도 함께 되찾아 볼까?',
    ),
    ScenePlay(
      ScenePropKind.beacon,
      '등대 불빛',
      '작은 불빛을 모아 등대를 깨워 줘.',
      '등대에 빛이 모였어. 알파벳으로 더 환하게 밝혀 보자.',
    ),
    ScenePlay(
      ScenePropKind.stone,
      '징검돌',
      '빛나는 돌을 톡, 다리로 보내 줘.',
      '돌들이 모였어. 토토와 차례대로 놓아 볼까?',
    ),
    ScenePlay(
      ScenePropKind.drop,
      '물감 방울',
      '물감 방울을 톡, 정원에 색을 돌려줘.',
      '색이 돌아왔어! 우리만의 정원도 그려 보자.',
    ),
    ScenePlay(
      ScenePropKind.page,
      '이야기 조각',
      '휙휙과 날아간 이야기 조각을 잡아 줘.',
      '조각을 찾았어. 실수해도 함께 고치면 돼!',
    ),
    ScenePlay(
      ScenePropKind.lantern,
      '길잡이 등불',
      '등불을 켜서 숲속 길을 밝혀 줘.',
      '길이 보인다! 어느 길로 가고 싶어?',
    ),
    ScenePlay(
      ScenePropKind.leaf,
      '반짝 잎사귀',
      '나무가 들려주는 이야기를 톡, 깨워 줘.',
      '나뭇잎이 반짝여! 우리가 만난 모양을 기억해 볼까?',
    ),
    ScenePlay(
      ScenePropKind.comet,
      '별빛 조각',
      '친구들과 마지막 별빛을 모아 줘.',
      '친구들의 빛이 모였어. 이제 도서관으로 돌아가자.',
    ),
    ScenePlay(
      ScenePropKind.book,
      '별빛 책',
      '별빛 책을 톡, 책장에 돌려놓아 줘.',
      '이야기가 집으로 돌아왔어! 우리 도서관을 함께 꾸미자.',
    ),
  ];
}
