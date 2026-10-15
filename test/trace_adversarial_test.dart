import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';

void main() {
  test(
    'a backtrack of modest total length is not a clean older-child stroke',
    () {
      const stroke = StrokePath([TracePoint(.2, .5), TracePoint(.8, .5)]);
      const input = [
        TracePoint(.2, .5),
        TracePoint(.56, .5),
        TracePoint(.44, .5),
        TracePoint(.8, .5),
      ];
      expect(
        const TraceStrategy(AgeStrategy(5)).evaluate(stroke, input).accepted,
        false,
      );
    },
  );
  for (final age in [2, 3, 4, 5]) {
    final evaluator = TraceStrategy(AgeStrategy(age));
    test(
      'age $age rejects deterministic canvas scribbles but accepts small tremor',
      () {
        final random = Random(4021);
        for (final entry in tracePaths.entries) {
          for (final stroke in entry.value) {
            final scribble = List.generate(
              40,
              (_) => TracePoint(random.nextDouble(), random.nextDouble()),
            );
            expect(
              evaluator.evaluate(stroke, scribble).accepted,
              false,
              reason: entry.key,
            );
          }
        }
        for (final symbol in ['A', 'C', '8', '사과']) {
          for (final stroke in tracePaths[symbol]!) {
            final input = stroke
                .samples(80)
                .indexed
                .map(
                  (v) => TracePoint(
                    v.$2.x + sin(v.$1 * .7) * .004,
                    v.$2.y + cos(v.$1 * .7) * .004,
                  ),
                )
                .toList();
            expect(
              evaluator.evaluate(stroke, input).accepted,
              true,
              reason: '$symbol tremor',
            );
          }
        }
      },
    );
    test(
      'age $age rejects repeated scribbles and tiny partial marks on every guide',
      () {
        for (final entry in tracePaths.entries) {
          for (final stroke in entry.value) {
            final guide = stroke.samples(80);
            final scribble = [...guide, ...guide.reversed, ...guide];
            expect(
              evaluator.evaluate(stroke, scribble).accepted,
              false,
              reason: '${entry.key}: repeated traversal',
            );
            expect(
              evaluator.evaluate(stroke, guide.take(10).toList()).accepted,
              false,
              reason: '${entry.key}: short fragment',
            );
          }
        }
      },
    );
    test('age $age rejects a chord across a curved C', () {
      final curve = tracePaths['C']!.first;
      expect(
        evaluator.evaluate(curve, [
          curve.points.first,
          curve.points.last,
        ]).accepted,
        false,
      );
    });
  }
}
