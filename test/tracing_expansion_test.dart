import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_vm.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';

void main() {
  test(
    'multi digit trace resumes before the second digit and completes once',
    () async {
      final store = MemoryStore();
      var container = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      var subscription = container.listen(traceProvider('n-20'), (_, _) {});
      await container.read(traceProvider('n-20').future);
      final paths = tracePaths['20']!;
      await container
          .read(traceProvider('n-20').notifier)
          .submit(paths.first.samples(80), 5);
      expect(container.read(traceProvider('n-20')).requireValue.done, false);
      subscription.close();
      container.dispose();
      container = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      subscription = container.listen(traceProvider('n-20'), (_, _) {});
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      final restored = await container.read(traceProvider('n-20').future);
      expect(restored.strokeIndex, 1);
      expect(restored.completed.length, 1);
      await container
          .read(traceProvider('n-20').notifier)
          .submit(paths.last.samples(80), 5);
      expect(container.read(traceProvider('n-20')).requireValue.done, true);
      final before = container
          .read(traceProvider('n-20'))
          .requireValue
          .completed
          .length;
      await container
          .read(traceProvider('n-20').notifier)
          .submit(paths.last.samples(80), 5);
      expect(
        container.read(traceProvider('n-20')).requireValue.completed.length,
        before,
      );
    },
  );
  test('next guide respects age and ends at the subject boundary', () {
    expect(TraceVM('e-A').nextItemId(3), 'e-B');
    expect(TraceVM('e-A').nextItemId(4), 'e-a');
    expect(TraceVM('n-3').nextItemId(2), isNull);
    expect(TraceVM('n-9').nextItemId(4), 'n-10');
    expect(TraceVM('n-20').nextItemId(5), isNull);
  });
  test('every alphabet case, basic jamo, syllable and number has a guide', () {
    final symbols = [
      ...'ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎㅏㅑㅓㅕㅗㅛㅜㅠㅡㅣ가나모'.split(''),
      ...'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split(''),
      for (var n = 1; n <= 20; n++) '$n',
    ];
    for (final symbol in symbols) {
      expect(
        learningItems.singleWhere((i) => i.symbol == symbol).strokes,
        isNotEmpty,
        reason: symbol,
      );
    }
    for (final item in learningItems.where(
      (i) => RegExp(r'^[a-z]$').hasMatch(i.symbol),
    )) {
      expect(item.minimumLevel, 4, reason: item.id);
    }
  });
  test('all guides accept complete forward input at all four ages', () {
    for (var age = 2; age <= 5; age++) {
      for (final entry in tracePaths.entries) {
        for (var i = 0; i < entry.value.length; i++) {
          final path = entry.value[i];
          expect(
            TraceStrategy(AgeStrategy(age))
                .evaluate(path, path.samples(80))
                .accepted,
            true,
            reason: '${entry.key} stroke $i age $age',
          );
        }
      }
    }
  });
  test(
    'closed loops reject reverse direction and incomplete arcs at age five',
    () {
      const evaluator = TraceStrategy(AgeStrategy(5));
      for (final symbol in ['ㅇ', 'O', 'o', '0', '8']) {
        final path = tracePaths[symbol]!.first;
        expect(
          evaluator.evaluate(path, path.samples(80).reversed.toList()).accepted,
          false,
          reason: '$symbol reverse',
        );
        expect(
          evaluator.evaluate(path, path.samples(80).take(25).toList()).accepted,
          false,
          reason: '$symbol partial',
        );
      }
    },
  );
  test(
    'two digit guides keep left digit before right with separated bounds',
    () {
      for (var n = 10; n <= 20; n++) {
        final digits = '$n'.split('');
        final paths = tracePaths['$n']!;
        final split = tracePaths[digits[0]]!.length;
        expect(paths.length, split + tracePaths[digits[1]]!.length);
        expect(
          paths.take(split).expand((s) => s.points).every((p) => p.x < .5),
          true,
        );
        expect(
          paths.skip(split).expand((s) => s.points).every((p) => p.x > .5),
          true,
        );
        expect(
          const TraceStrategy(AgeStrategy(5))
              .evaluate(paths.first, paths.last.samples(80))
              .accepted,
          false,
          reason: '$n right digit first',
        );
      }
    },
  );
}
