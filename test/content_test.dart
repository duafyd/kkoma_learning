import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';

void main() {
  test('all quizzes have one correct option and unique choices', () {
    final quizzes = [
      ...learningQuizzes,
      ...storyEpisodes
          .expand((e) => e.scenes)
          .where((s) => s.quiz != null)
          .map((s) => s.quiz!),
    ];
    for (final q in quizzes) {
      expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: q.id);
      expect(q.options.toSet().length, q.options.length, reason: q.id);
      expect(q.hint, isNotEmpty);
    }
  });
  test('all trace references exist and paths remain inside canvas', () {
    final ids = learningItems.map((i) => i.id).toSet();
    expect(ids.length, learningItems.length);
    for (final s in storyEpisodes.expand((e) => e.scenes)) {
      if (s.traceId != null) {
        expect(ids.contains(s.traceId), true);
        expect(
          learningItems.firstWhere((i) => i.id == s.traceId).strokes,
          isNotEmpty,
        );
      }
    }
    for (final item in learningItems) {
      for (final stroke in item.strokes) {
        expect(stroke.length, greaterThan(0));
        for (final p in stroke.points) {
          expect(p.x, inInclusiveRange(0, 1));
          expect(p.y, inInclusiveRange(0, 1));
        }
      }
    }
  });
  test('all age strategies stay in bounds and adjust at most one step', () {
    for (var level = 2; level <= 5; level++) {
      final strategy = AgeStrategy(level);
      expect(strategy.adapt(3, 0), (level + 1).clamp(2, 5));
      expect(strategy.adapt(0, 2), (level - 1).clamp(2, 5));
      expect(strategy.adapt(1, 0), level);
    }
  });
}
