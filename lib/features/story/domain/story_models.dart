import '../../learning/domain/learning_models.dart';
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

class StoryScene {
  final String id, text, background, character;
  final StoryPhase interaction;
  final int minimumLevel;
  final QuizDefinition? quiz;
  final String? traceId, flag;
  final List<String> choices;
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
    this.choices = const [],
  });
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
  final StoryPhase phase;
  final Map<String, String> flags;
  final List<int> completed;
  final List<List<TracePoint>> strokes;
  final bool assisted;
  final String message;
  const StorySnapshot({
    this.episode = 0,
    this.scene = 0,
    this.level = 3,
    this.attempts = 0,
    this.hints = 0,
    this.phase = StoryPhase.dialogue,
    this.flags = const {},
    this.completed = const [],
    this.strokes = const [],
    this.assisted = false,
    this.message = '',
  });
  Map<String, dynamic> toJson() => {
    'episode': episode,
    'scene': scene,
    'level': level,
    'attempts': attempts,
    'hints': hints,
    'phase': phase.name,
    'flags': flags,
    'completed': completed,
    'strokes': strokes.map((s) => s.map((p) => p.toJson()).toList()).toList(),
    'assisted': assisted,
    'message': message,
  };
  factory StorySnapshot.fromJson(Map<String, dynamic> j) => StorySnapshot(
    episode: j['episode'] as int? ?? 0,
    scene: j['scene'] as int? ?? 0,
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
  );
  StorySnapshot change(Map<String, dynamic> fields) =>
      StorySnapshot.fromJson({...toJson(), ...fields});
}
