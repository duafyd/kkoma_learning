import 'learning_models.dart';

class LearningSession {
  final int level, index, successes, failures, hint, baseLevel;
  final bool answered, assisted;
  final String message;
  final String? quizOverrideId, quizId;
  const LearningSession({
    required this.level,
    this.baseLevel = 3,
    this.index = 0,
    this.successes = 0,
    this.failures = 0,
    this.answered = false,
    this.assisted = false,
    this.message = '',
    this.hint = 0,
    this.quizOverrideId,
    this.quizId,
  });
  Map<String, dynamic> toJson() => {
    'level': level,
    'baseLevel': baseLevel,
    'index': index,
    'successes': successes,
    'failures': failures,
    'answered': answered,
    'assisted': assisted,
    'message': message,
    'hint': hint,
    'quizOverrideId': quizOverrideId,
    'quizId': quizId,
  };
  factory LearningSession.fromJson(Map<String, dynamic> j) {
    final level = (j['level'] as int? ?? 3).clamp(2, 5);
    final base = j['baseLevel'] as int? ?? 3;
    final index = j['index'] as int? ?? 0;
    if (index < 0) return LearningSession(level: level, baseLevel: base);
    return LearningSession(
      level: level,
      baseLevel: base,
      index: index,
      successes: (j['successes'] as int? ?? 0).clamp(0, 1000000000),
      failures: (j['failures'] as int? ?? 0).clamp(0, 1000000000),
      answered: j['answered'] as bool? ?? false,
      assisted: j['assisted'] as bool? ?? false,
      message: j['message'] as String? ?? '',
      hint: (j['hint'] as int? ?? 0).clamp(0, 1000000000),
      quizOverrideId: j['quizOverrideId'] as String?,
      quizId: j['quizId'] as String?,
    );
  }
  LearningSession change(Map<String, dynamic> j) =>
      LearningSession.fromJson({...toJson(), ...j});

  /// A different eligible question can occupy the same index after capping.
  /// Keep the position, but never carry its old answer/hints onto that question.
  LearningSession cappedAt(int maximum) => level <= maximum
      ? this
      : LearningSession(level: maximum, baseLevel: baseLevel, index: index);

  QuizDefinition question(List<QuizDefinition> available) {
    for (final id in [quizOverrideId, quizId]) {
      if (id == null) continue;
      for (final q in available) {
        if (q.id == id) return q;
      }
    }
    return available[index % available.length];
  }

  LearningSession restoredFor(List<QuizDefinition> available) {
    final ids = available.map((q) => q.id).toList();
    if ((quizOverrideId != null && !ids.contains(quizOverrideId)) ||
        (quizId != null && !ids.contains(quizId)) ||
        (quizOverrideId != null &&
            quizId != null &&
            quizOverrideId != quizId)) {
      final fresh = LearningSession(
        level: level,
        baseLevel: baseLevel,
        index: index,
      );
      return fresh.change({'quizId': fresh.question(available).id});
    }
    final current = question(available);
    return change({
      'quizId': current.id,
      if (quizOverrideId == null && quizId != null)
        'index':
            index ~/ available.length * available.length +
            ids.indexOf(current.id),
    });
  }
}
