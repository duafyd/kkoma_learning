import '../../tracing/domain/trace_engine.dart';

class LearningItem {
  final String id, subject, symbol, name, example, picture, language;
  final int minimumLevel;
  final List<StrokePath> strokes;
  const LearningItem({
    required this.id,
    required this.subject,
    required this.symbol,
    required this.name,
    required this.example,
    required this.picture,
    this.language = 'ko-KR',
    this.minimumLevel = 2,
    this.strokes = const [],
  });
}

enum QuizKind {
  matching,
  count,
  compare,
  classify,
  pattern,
  addition,
  subtraction,
  order,
  combination,
}

class QuizDefinition {
  final String id, prompt, visual, hint, subject;
  final List<String> options;
  final int answer, minimumLevel;
  final QuizKind kind;
  final String? resultVisual;
  const QuizDefinition({
    required this.id,
    required this.prompt,
    required this.visual,
    required this.options,
    required this.answer,
    required this.hint,
    this.minimumLevel = 2,
    this.kind = QuizKind.matching,
    this.subject = 'math',
    this.resultVisual,
  });
  bool accepts(int choice) => choice == answer;
}
