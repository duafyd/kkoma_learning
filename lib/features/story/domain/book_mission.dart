import '../../learning/domain/learning_models.dart';
import 'story_models.dart';

enum BookWorld { garden, wind, crossroads, paperForest, sky, library }

/// Direction projected from the machine's resolved quiz and committed ink.
/// No answer, progress or persistence is owned by the scene renderer.
class BookMission {
  final String sceneId, symbol, variation;
  final BookWorld world;
  final QuizDefinition? quiz;
  final bool solved;
  final int completed, total, hints;
  final List<int> observed;
  const BookMission({
    required this.sceneId,
    required this.world,
    required this.solved,
    required this.completed,
    required this.total,
    required this.observed,
    required this.hints,
    this.quiz,
    this.symbol = '',
    this.variation = '',
  });
  bool get tracing => quiz == null;
  double get energy => solved
      ? 1
      : tracing && total > 0
      ? (completed / total).clamp(0, 1)
      : 0;
  String get location => switch (world) {
    BookWorld.garden => '정원 바구니',
    BookWorld.wind => '휙휙의 바구니',
    BookWorld.crossroads => '이야기 길 표지',
    BookWorld.paperForest => '성장 그림책',
    BookWorld.sky => '하늘 책갈피',
    BookWorld.library => '도서관 책장',
  };
  String get purpose => switch (world) {
    BookWorld.garden => '내 그림으로 정원의 길을 만들어요',
    BookWorld.wind => 'C를 그려 휙휙과 바구니를 옮겨요',
    BookWorld.crossroads => 'ㅏ 빛줄기로 내가 고른 길을 이어요',
    BookWorld.paperForest => 'A를 그려 젖었던 그림책을 밝혀요',
    BookWorld.sky => '2를 그려 별 친구 둘을 이어요',
    BookWorld.library => 'ㅜ를 그려 우리 이야기책에 빛을 담아요',
  };

  static BookWorld? worldFor(StorySnapshot s, StoryScene scene) {
    if (s.level < 3 ||
        s.supportSceneId != null ||
        ![
          StoryPhase.quiz,
          StoryPhase.tracing,
          StoryPhase.success,
        ].contains(s.phase)) {
      return null;
    }
    if (![StoryPhase.quiz, StoryPhase.tracing].contains(scene.interaction)) {
      return null;
    }
    // The five-star placement has its own drag stage and rules.
    if (scene.id == 'ep11-quiz') return null;
    return switch (s.episodeId ?? s.episode + 1) {
      7 => BookWorld.garden,
      8 => BookWorld.wind,
      9 => BookWorld.crossroads,
      10 => BookWorld.paperForest,
      11 => BookWorld.sky,
      12 => BookWorld.library,
      _ => null,
    };
  }
}
