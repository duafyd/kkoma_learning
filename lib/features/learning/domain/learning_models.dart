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

enum QuizGlyph {
  star('별'),
  circle('동그라미'),
  triangle('세모'),
  flower('꽃'),
  leaf('잎'),
  seed('씨앗'),
  vowelA('아', 'ㅏ'),
  vowelEo('어', 'ㅓ'),
  vowelO('오', 'ㅗ'),
  vowelU('우', 'ㅜ'),
  giyeok('기역', 'ㄱ'),
  nieun('니은', 'ㄴ'),
  mieum('미음', 'ㅁ'),
  ga('가', '가'),
  na('나', '나'),
  ma('마', '마'),
  latinA('에이', 'A'),
  latinB('비', 'B'),
  latinC('시', 'C'),
  lowerA('작은 에이', 'a'),
  lowerB('작은 비', 'b'),
  apple('사과'),
  banana('바나나'),
  stone('돌'),
  book('책'),
  sprout('싹'),
  tree('나무'),
  redFlower('빨간 꽃'),
  blueFlower('파란 꽃'),
  one('하나', '1'),
  two('둘', '2'),
  three('셋', '3');

  final String label;
  final String? symbol;
  const QuizGlyph(this.label, [this.symbol]);
}

/// Structured picture content; answer rules remain in QuizDefinition/VM.
enum QuizArrangement { tray, bridge, constellation }

class QuizArtwork {
  final List<QuizGlyph> objects;
  final List<List<QuizGlyph>> choices;
  final bool countOnTap;
  final String objectName;
  final QuizArrangement arrangement;
  const QuizArtwork({
    required this.objects,
    required this.choices,
    this.countOnTap = false,
    this.objectName = '별조각',
    this.arrangement = QuizArrangement.tray,
  });
}

class QuizDefinition {
  final String id, prompt, visual, hint, subject;
  final List<String> options;
  final int answer, minimumLevel;
  final QuizKind kind;

  /// Exploration has no wrong option; [answer] is unused in that mode.
  final bool isExploration;
  final String? resultVisual, easierId;
  final QuizArtwork? artwork;
  const QuizDefinition({
    required this.id,
    required this.prompt,
    required this.visual,
    required this.options,
    required this.answer,
    required this.hint,
    this.minimumLevel = 2,
    this.kind = QuizKind.matching,
    this.isExploration = false,
    this.subject = 'math',
    this.resultVisual,
    this.easierId,
    this.artwork,
  });
  bool accepts(int choice) =>
      choice >= 0 &&
      choice < options.length &&
      (isExploration || choice == answer);
}
