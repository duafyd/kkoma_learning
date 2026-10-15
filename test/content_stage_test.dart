import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/learning/data/additional_quizzes.dart';
import 'package:flutter_application_1/features/learning/data/learning_repository.dart';
import 'package:flutter_application_1/features/learning/presentation/learning_vm.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_vm.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';

int occurrences(String text, String symbol) => text.split(symbol).length - 1;

void main() {
  test('arithmetic answers and concrete pictures agree, including zero', () {
    for (final q in learningQuizzes) {
      final match = RegExp(r'^(add|subtract)-(\d+)-(\d+)$').firstMatch(q.id);
      if (match == null) continue;
      final a = int.parse(match[2]!), b = int.parse(match[3]!);
      final expected = match[1] == 'add' ? a + b : a - b;
      expect(int.parse(q.options[q.answer]), expected, reason: q.id);
      expect(occurrences(q.visual, '🍎'), a + b, reason: q.id);
      expect(q.options.toSet().length, 3);
      expect(expected, inInclusiveRange(0, 10));
      expect(occurrences(q.resultVisual!, '🍎'), expected, reason: q.id);
      if (expected == 0) expect(q.resultVisual, contains('0개'));
    }
  });
  test(
    'quantity matching has exactly one answer with matching object count',
    () {
      final activities = additionalQuizzes();
      for (var i = 1; i < activities.length; i++) {
        expect(
          activities[i].kind,
          isNot(activities[i - 1].kind),
          reason: 'alternate activities',
        );
      }
      for (final q in learningQuizzes.where(
        (q) => q.id.startsWith('quantity-match-'),
      )) {
        final count = occurrences(q.visual, '🍎');
        final counts = q.options.map((o) => occurrences(o, '🐟')).toList();
        expect(counts.where((n) => n == count).length, 1);
        expect(counts[q.answer], count);
        expect(counts.every((n) => n >= 1 && n <= 5), true);
      }
    },
  );
  test('fallback references exist, are simpler, remain in subject and cannot cycle', () {
    expect(
      learningQuizzes.map((q) => q.id).toSet().length,
      learningQuizzes.length,
    );
    for (final q in learningQuizzes.where((q) => q.easierId != null)) {
      final target = learningQuizzes.singleWhere((t) => t.id == q.easierId);
      expect(target.minimumLevel, lessThan(q.minimumLevel));
      expect(target.subject, q.subject);
      final seen = <String>{q.id};
      var current = q;
      while (current.easierId != null) {
        expect(seen.add(current.easierId!), true);
        current = learningQuizzes.singleWhere((t) => t.id == current.easierId);
      }
    }
  });
  test('word guides preserve syllable order and refuse right letter first', () {
    for (final word in ['사과', '나무', '바다', '사자', '하마', '나비', '아기']) {
      final item = learningItems.singleWhere((i) => i.symbol == word);
      expect(item.minimumLevel, 5);
      final split = tracePaths[word[0]]!.length;
      expect(item.strokes.length, split + tracePaths[word[1]]!.length);
      expect(
        item.strokes.take(split).expand((s) => s.points).every((p) => p.x < .5),
        true,
      );
      expect(
        item.strokes.skip(split).expand((s) => s.points).every((p) => p.x > .5),
        true,
      );
      expect(
        const TraceStrategy(AgeStrategy(5))
            .evaluate(item.strokes.first, item.strokes[split].samples(80))
            .accepted,
        false,
      );
    }
  });
  test(
    'word resumes after first letter and completes after the second',
    () async {
      final store = MemoryStore();
      final paths = tracePaths['사과']!;
      final split = tracePaths['사']!.length;
      var c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      var sub = c.listen(traceProvider('h-사과'), (_, _) {});
      await c.read(traceProvider('h-사과').future);
      for (final path in paths.take(split)) {
        await c
            .read(traceProvider('h-사과').notifier)
            .submit(path.samples(80), 5);
      }
      expect(c.read(traceProvider('h-사과')).requireValue.done, false);
      sub.close();
      c.dispose();
      c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      sub = c.listen(traceProvider('h-사과'), (_, _) {});
      addTearDown(() {
        sub.close();
        c.dispose();
      });
      expect((await c.read(traceProvider('h-사과').future)).strokeIndex, split);
      for (final path in paths.skip(split)) {
        await c
            .read(traceProvider('h-사과').notifier)
            .submit(path.samples(80), 5);
      }
      expect(c.read(traceProvider('h-사과')).requireValue.done, true);
    },
  );
  test('real easier question survives reload and clears after next', () async {
    final store = MemoryStore();
    await ProfileRepository(store)
        .save(const ParentSettings(age: 5, level: 5, autoRead: false));
    final math = learningQuizzes.where((q) => q.subject == 'math').toList();
    await LearningRepository(store).save(
      'math',
      LearningSession(
        level: 5,
        baseLevel: 5,
        index: math.indexWhere((q) => q.id == 'add-5-3'),
        failures: 2,
      ),
    );
    var c = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    var sub = c.listen(learningProvider('math'), (_, _) {});
    await c.read(learningProvider('math').future);
    expect(c.read(learningProvider('math').notifier).quiz.id, 'add-5-3');
    await c.read(learningProvider('math').notifier).easier();
    expect(
      c.read(learningProvider('math').notifier).quiz.id,
      'quantity-match-5',
    );
    sub.close();
    c.dispose();
    c = ProviderContainer(overrides: [storeProvider.overrideWithValue(store)]);
    sub = c.listen(learningProvider('math'), (_, _) {});
    addTearDown(() {
      sub.close();
      c.dispose();
    });
    await c.read(learningProvider('math').future);
    final vm = c.read(learningProvider('math').notifier);
    expect(vm.quiz.id, 'quantity-match-5');
    await vm.answer(vm.quiz.answer);
    await vm.next();
    expect(
      c.read(learningProvider('math')).requireValue.quizOverrideId,
      isNull,
    );
    expect(c.read(learningProvider('math')).requireValue.assisted, false);
  });
}
