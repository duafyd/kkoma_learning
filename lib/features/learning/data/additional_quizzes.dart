import '../domain/learning_models.dart';

String _objects(String object, int count) =>
    List.filled(count, object).join(' ');

List<QuizDefinition> additionalQuizzes() {
  final result = <QuizDefinition>[];
  for (var count = 1; count <= 5; count++) {
    final quantities = [
      count,
      count == 5 ? 1 : count + 1,
      count <= 2 ? count + 2 : count - 1,
    ];
    final shift = count % 3;
    final ordered = [...quantities.skip(shift), ...quantities.take(shift)];
    result.add(
      QuizDefinition(
        id: 'quantity-match-$count',
        easierId: 'count2',
        prompt: '사과와 같은 수의 물고기를 찾아요',
        visual: _objects('🍎', count),
        options: ordered.map((n) => _objects('🐟', n)).toList(),
        answer: ordered.indexOf(count),
        hint: '사과 하나에 물고기 하나씩 짝을 지어 보아요.',
        minimumLevel: 3,
        kind: QuizKind.matching,
      ),
    );
  }
  for (var a = 1; a <= 5; a++) {
    for (var b = 1; b <= 3; b++) {
      final total = a + b;
      final choices = [total - 1, total, total + 1];
      final shift = total % 3;
      final ordered = [...choices.skip(shift), ...choices.take(shift)];
      result.add(
        QuizDefinition(
          id: 'add-$a-$b',
          easierId: 'quantity-match-${total.clamp(1, 5)}',
          prompt: '사과 $a개에 $b개를 더 모으면?',
          visual: '${_objects('🍎', a)}\n+ ${_objects('🍎', b)}',
          options: ordered.map((n) => '$n').toList(),
          answer: ordered.indexOf(total),
          hint: '$a개부터 하나씩 더 세어 보아요.',
          minimumLevel: total <= 5 ? 4 : 5,
          kind: QuizKind.addition,
          resultVisual: _objects('🍎', total),
        ),
      );
    }
  }
  for (var a = 2; a <= 8; a++) {
    for (var b = 1; b <= 2; b++) {
      final remaining = a - b;
      final choices = [
        remaining,
        remaining + 1,
        remaining == 0 ? 2 : remaining - 1,
      ];
      final shift = a % 3;
      final ordered = [...choices.skip(shift), ...choices.take(shift)];
      result.add(
        QuizDefinition(
          id: 'subtract-$a-$b',
          easierId: 'quantity-match-${a.clamp(1, 5)}',
          prompt: '사과 $a개에서 $b개를 먹으면 몇 개 남을까요?',
          visual: '${_objects('🍎', a)}\n− ${_objects('🍎', b)}',
          options: ordered.map((n) => '$n').toList(),
          answer: ordered.indexOf(remaining),
          hint: '$a개에서 $b개를 가리고 남은 사과를 세어요.',
          minimumLevel: 5,
          kind: QuizKind.subtraction,
          resultVisual: remaining == 0
              ? '모두 먹어서 0개예요.'
              : _objects('🍎', remaining),
        ),
      );
    }
  }
  result.addAll(const [
    QuizDefinition(
      id: 'color-red',
      easierId: 'same',
      prompt: '빨간 공과 같은 색을 찾아요',
      visual: '🔴',
      options: ['🔵 파랑', '🔴 빨강', '🟡 노랑'],
      answer: 1,
      hint: '공의 색은 빨강이에요.',
      minimumLevel: 3,
      kind: QuizKind.classify,
    ),
    QuizDefinition(
      id: 'color-blue',
      easierId: 'same',
      prompt: '파란 공과 같은 색을 찾아요',
      visual: '🔵',
      options: ['🔵 파랑', '🔴 빨강', '🟡 노랑'],
      answer: 0,
      hint: '공의 색은 파랑이에요.',
      minimumLevel: 3,
      kind: QuizKind.classify,
    ),
    QuizDefinition(
      id: 'pattern-pairs',
      easierId: 'pattern',
      prompt: '다음 모양은 무엇일까요?',
      visual: '● ● ▲ ● ● ▲ ?',
      options: ['▲', '■', '●'],
      answer: 2,
      hint: '동그라미 둘, 세모 하나가 반복돼요.',
      minimumLevel: 4,
      kind: QuizKind.pattern,
    ),
    QuizDefinition(
      id: 'pattern-three',
      easierId: 'pattern',
      prompt: '다음 모양을 이어 보아요',
      visual: '● ▲ ■ ● ▲ ?',
      options: ['■', '▲', '●'],
      answer: 0,
      hint: '동그라미, 세모, 네모 순서예요.',
      minimumLevel: 4,
      kind: QuizKind.pattern,
    ),
  ]);
  // Alternate activities rather than repeating an entire arithmetic block.
  final groups = <QuizKind, List<QuizDefinition>>{};
  var longest = 0;
  for (final quiz in result) {
    final group = groups.putIfAbsent(quiz.kind, () => []);
    group.add(quiz);
    if (group.length > longest) longest = group.length;
  }
  return List.unmodifiable([
    for (var round = 0; round < longest; round++)
      for (final group in groups.values)
        if (round < group.length) group[round],
  ]);
}
