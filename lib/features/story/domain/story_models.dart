import '../../learning/domain/learning_models.dart';
import '../../drawing/domain/drawing.dart';
import '../../tracing/domain/trace_engine.dart';

enum StoryPhase {
  dialogue,
  choice,
  quiz,
  tracing,
  drawing,
  success,
  episodeComplete,
  finished,
}

enum StoryReaction { greet, search, point, celebrate }

class StorySpeech {
  final String id, label, text, language;
  const StorySpeech({
    required this.id,
    required this.label,
    required this.text,
    this.language = 'ko-KR',
  });
}

class StoryScene {
  final String id, text, background, character;
  final StoryPhase interaction;
  final int minimumLevel;
  final QuizDefinition? quiz;
  final String? traceId, flag;
  final List<String> choices;
  final StoryReaction reaction;
  final String successText;
  final String? successBackground;
  final QuizDefinition? exploreQuiz;
  final String exploreSuccessText;
  final String? exploreText;
  final List<StorySpeech> speeches;
  final String? variationFlag;
  final Map<String, QuizDefinition> quizVariants;
  final Map<String, String> backgroundVariants;
  final Map<String, String> successBackgroundVariants;
  final Map<String, List<StorySpeech>> speechVariants;
  const StoryScene({
    required this.id,
    required this.text,
    this.background = 'library',
    this.character = '모아',
    this.interaction = StoryPhase.dialogue,
    this.minimumLevel = 2,
    this.quiz,
    this.traceId,
    this.flag,
    this.reaction = StoryReaction.greet,
    this.successText = '',
    this.successBackground,
    this.exploreQuiz,
    this.exploreSuccessText = '마음에 드는 모양을 찾았어요. 친구와 함께 가요!',
    this.exploreText,
    this.speeches = const [],
    this.variationFlag,
    this.quizVariants = const {},
    this.backgroundVariants = const {},
    this.successBackgroundVariants = const {},
    this.speechVariants = const {},
    this.choices = const [],
  });

  StoryScene reword({
    required String text,
    String? success,
    String? exploreSuccess,
    String? explore,
  }) => StoryScene(
    id: id,
    text: text,
    background: background,
    character: character,
    interaction: interaction,
    minimumLevel: minimumLevel,
    quiz: quiz,
    traceId: traceId,
    flag: flag,
    choices: choices,
    reaction: reaction,
    successText: success ?? successText,
    successBackground: successBackground,
    exploreQuiz: exploreQuiz,
    exploreSuccessText: exploreSuccess ?? exploreSuccessText,
    exploreText: explore ?? exploreText,
    speeches: speeches,
    variationFlag: variationFlag,
    quizVariants: quizVariants,
    backgroundVariants: backgroundVariants,
    successBackgroundVariants: successBackgroundVariants,
    speechVariants: speechVariants,
  );
}

class StoryEpisode {
  final int id;
  final String title, goal, reward;
  final List<StoryScene> scenes;
  const StoryEpisode({
    required this.id,
    required this.title,
    required this.goal,
    required this.reward,
    required this.scenes,
  });
  List<StoryScene> forLevel(int level) =>
      scenes.where((s) => s.minimumLevel <= level).toList();
}

class StorySnapshot {
  final int episode, scene, level, attempts, hints;
  final int? episodeId;
  final String? sceneId;
  final StoryPhase phase;
  final Map<String, String> flags;
  final List<int> completed;
  final List<List<TracePoint>> strokes;
  final bool assisted;
  final String message;
  final String? supportSceneId;
  final List<int> observedObjects;
  final List<int> sceneFinds;
  final Artwork? pendingDrawing;
  const StorySnapshot({
    this.episode = 0,
    this.scene = 0,
    this.episodeId,
    this.sceneId,
    this.level = 3,
    this.attempts = 0,
    this.hints = 0,
    this.phase = StoryPhase.dialogue,
    this.flags = const {},
    this.completed = const [],
    this.strokes = const [],
    this.assisted = false,
    this.message = '',
    this.supportSceneId,
    this.observedObjects = const [],
    this.sceneFinds = const [],
    this.pendingDrawing,
  });
  Map<String, dynamic> toJson() => {
    'episode': episode,
    'scene': scene,
    'episodeId': episodeId,
    'sceneId': sceneId,
    'level': level,
    'attempts': attempts,
    'hints': hints,
    'phase': phase.name,
    'flags': flags,
    'completed': completed,
    'strokes': strokes.map((s) => s.map((p) => p.toJson()).toList()).toList(),
    'assisted': assisted,
    'message': message,
    'supportSceneId': supportSceneId,
    'observedObjects': observedObjects,
    'sceneFinds': sceneFinds,
    'pendingDrawing': pendingDrawing?.toJson(),
  };
  factory StorySnapshot.fromJson(Map<String, dynamic> j) => StorySnapshot(
    episode: j['episode'] as int? ?? 0,
    scene: j['scene'] as int? ?? 0,
    episodeId: j['episodeId'] as int?,
    sceneId: j['sceneId'] as String?,
    level: (j['level'] as int? ?? 3).clamp(2, 5),
    attempts: j['attempts'] as int? ?? 0,
    hints: j['hints'] as int? ?? 0,
    phase: StoryPhase.values.firstWhere(
      (p) => p.name == j['phase'],
      orElse: () => StoryPhase.dialogue,
    ),
    flags: Map<String, String>.from(j['flags'] as Map? ?? {}),
    completed: List<int>.from(j['completed'] as List? ?? []),
    strokes: (j['strokes'] as List? ?? [])
        .map(
          (s) =>
              (s as List).map((p) => TracePoint.fromJson(p as List)).toList(),
        )
        .toList(),
    assisted: j['assisted'] as bool? ?? false,
    message: j['message'] as String? ?? '',
    supportSceneId: j['supportSceneId'] as String?,
    pendingDrawing: j['pendingDrawing'] is Map
        ? Artwork.fromJson(
            Map<String, dynamic>.from(j['pendingDrawing'] as Map),
          )
        : null,
    observedObjects: (j['observedObjects'] as List? ?? const [])
        .whereType<int>()
        .where((i) => i >= 0)
        .toSet()
        .toList(),
    sceneFinds: (j['sceneFinds'] as List? ?? const [])
        .whereType<int>()
        .where((i) => i >= 0)
        .toSet()
        .toList(),
  );
  StorySnapshot change(Map<String, dynamic> fields) =>
      StorySnapshot.fromJson({...toJson(), ...fields});
}
