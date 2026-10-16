import 'story_models.dart';

enum LetterWorld { flowerGate, lighthouse, seedTree, soundTrain }

/// A view of committed story state, never a second source of mission progress.
class LetterMission {
  final LetterWorld world;
  final bool tracing, solved;
  final int completed, total;
  final List<String> choices;
  final int? hintChoice;
  const LetterMission({
    required this.world,
    required this.tracing,
    required this.solved,
    required this.completed,
    required this.total,
    required this.choices,
    this.hintChoice,
  });

  double get energy => solved
      ? 1
      : tracing
      ? (completed / total).clamp(0, 1)
      : 0;
  String get location => switch (world) {
    LetterWorld.flowerGate => '꽃문',
    LetterWorld.lighthouse => '등대 빛',
    LetterWorld.seedTree => '자음 열매',
    LetterWorld.soundTrain => '기차 표지',
  };
  String get invitation => '$location의 글자를 톡 눌러 골라요.';
  String get purpose => switch (world) {
    LetterWorld.flowerGate => 'ㅏ를 이으면 꽃길에 빛이 피어나요',
    LetterWorld.lighthouse => 'A를 이으면 등대 빛이 바다로 뻗어요',
    LetterWorld.seedTree => 'ㄱ을 그려 씨앗 꾸러미에 이름표를 달아요',
    LetterWorld.soundTrain => 'ㄴ을 그리면 다음 칸의 출발 신호가 켜져요',
  };

  static LetterMission? forScene(StorySnapshot s, StoryScene scene) {
    if (s.level < 3 ||
        s.supportSceneId != null ||
        ![
          StoryPhase.quiz,
          StoryPhase.tracing,
          StoryPhase.success,
        ].contains(s.phase)) {
      return null;
    }
    final world = switch (scene.id) {
      'ep2-quiz' || 'ep2-trace' => LetterWorld.flowerGate,
      'ep5-quiz' || 'ep5-trace' => LetterWorld.lighthouse,
      'ep3-quiz' || 'ep3-trace' => LetterWorld.seedTree,
      'ep4-quiz' || 'ep4-trace' => LetterWorld.soundTrain,
      _ => null,
    };
    if (world == null) return null;
    final tracing = scene.interaction == StoryPhase.tracing;
    return LetterMission(
      world: world,
      tracing: tracing,
      solved: s.phase == StoryPhase.success,
      completed: s.strokes.length,
      total: switch (world) {
        LetterWorld.flowerGate => 2,
        LetterWorld.lighthouse => 3,
        _ => 1,
      },
      hintChoice: s.hints >= 2 && !tracing ? scene.quiz!.answer : null,
      choices: tracing
          ? const []
          : [
              for (final choice in scene.quiz!.artwork!.choices)
                choice.single.symbol!,
            ],
    );
  }
}
