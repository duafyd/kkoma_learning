import 'learning_models.dart';

/// Structural checks, not an assessment of educational suitability.
List<String> validateQuiz(QuizDefinition quiz) {
  final issues = <String>[];
  if (quiz.id.trim().isEmpty ||
      quiz.prompt.trim().isEmpty ||
      quiz.hint.trim().isEmpty) {
    issues.add('missing identity, prompt or hint');
  }
  if (!['hangul', 'english', 'math'].contains(quiz.subject) ||
      quiz.minimumLevel < 2 ||
      quiz.minimumLevel > 5) {
    issues.add('invalid subject or level');
  }
  final options = quiz.options.map((o) => o.trim()).toList();
  if (options.length < 2 ||
      options.any((o) => o.isEmpty) ||
      options.toSet().length != options.length) {
    issues.add('empty or duplicate options');
  }
  if (!quiz.isExploration &&
      (quiz.answer < 0 || quiz.answer >= options.length)) {
    issues.add('answer outside options');
  }
  final art = quiz.artwork;
  if (art == null) return issues;
  if (art.objects.isEmpty ||
      art.choices.length != options.length ||
      art.choices.any((c) => c.isEmpty)) {
    issues.add('invalid picture choices');
  }
  final pictures = art.choices
      .map((c) => c.map((g) => g.name).join('/'))
      .toList();
  if (pictures.toSet().length != pictures.length) {
    issues.add('visually identical choices');
  }
  if (!quiz.isExploration &&
      quiz.kind == QuizKind.count &&
      quiz.answer >= 0 &&
      quiz.answer < art.choices.length) {
    final matching = [
      for (var i = 0; i < art.choices.length; i++)
        if (art.choices[i].length == art.objects.length) i,
    ];
    if (matching.length != 1 || matching.single != quiz.answer) {
      issues.add('picture count does not identify the answer uniquely');
    }
  }
  return issues;
}
