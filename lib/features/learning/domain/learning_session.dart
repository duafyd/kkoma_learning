class LearningSession {
  final int level, index, successes, failures, hint, baseLevel;
  final bool answered, assisted;
  final String message;
  final String? quizOverrideId;
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
  };
  factory LearningSession.fromJson(Map<String, dynamic> j) => LearningSession(
    level: (j['level'] as int? ?? 3).clamp(2, 5),
    baseLevel: j['baseLevel'] as int? ?? 3,
    index: j['index'] as int? ?? 0,
    successes: j['successes'] as int? ?? 0,
    failures: j['failures'] as int? ?? 0,
    answered: j['answered'] as bool? ?? false,
    assisted: j['assisted'] as bool? ?? false,
    message: j['message'] as String? ?? '',
    hint: j['hint'] as int? ?? 0,
    quizOverrideId: j['quizOverrideId'] as String?,
  );
  LearningSession change(Map<String, dynamic> j) =>
      LearningSession.fromJson({...toJson(), ...j});
}
