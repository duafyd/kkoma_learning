import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_coach.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';

void main() {
  for (var level = 2; level <= 5; level++) {
    test(
      'coaching follows every authored stroke without changing final judgement at $level',
      () {
        for (final item in learningItems) {
          for (final stroke in item.strokes) {
            final strategy = TraceStrategy(AgeStrategy(level));
            final coach = TraceCoach(stroke, strategy);
            final input = stroke.samples(100);
            var before = 0.0;
            for (final p in input) {
              final result = coach.add(p);
              expect(
                result.onPath,
                isTrue,
                reason: '${item.id} at ${p.toJson()}',
              );
              expect(result.progress, greaterThanOrEqualTo(before));
              before = result.progress;
            }
            expect(before, closeTo(1, .03), reason: item.id);
            expect(strategy.evaluate(stroke, input).accepted, isTrue);
          }
        }
      },
    );
  }
  test('preview warns for wrong start, detour and backtracking without awarding completion', () {
    const stroke = StrokePath([TracePoint(.2, .2), TracePoint(.8, .2)]);
    const strategy = TraceStrategy(AgeStrategy(5));
    expect(
      TraceCoach(stroke, strategy).add(const TracePoint(.8, .2)).cue,
      TraceCue.start,
    );
    final coach = TraceCoach(stroke, strategy);
    coach.add(stroke.points.first);
    expect(coach.add(const TracePoint(.3, .7)).cue, TraceCue.path);
    for (final p in stroke.samples(100).take(60)) {
      coach.add(p);
    }
    expect(coach.add(const TracePoint(.49, .2)).cue, TraceCue.direction);
    final half = stroke.samples(100).take(50).toList();
    expect(strategy.evaluate(stroke, half).accepted, isFalse);
    expect(
      strategy.evaluate(stroke, [
        ...stroke.points,
        ...stroke.points.reversed,
        ...stroke.points,
      ]).accepted,
      isFalse,
    );
  });
  test('young learner may follow an open or closed stroke in reverse', () {
    final examples = [
      const StrokePath([TracePoint(.2, .2), TracePoint(.8, .2)]),
      learningItems.firstWhere((i) => i.symbol == 'O').strokes.first,
    ];
    for (final stroke in examples) {
      final coach = TraceCoach(stroke, const TraceStrategy(AgeStrategy(2)));
      TracePreview? result;
      for (final p in stroke.samples(100).reversed) {
        result = coach.add(p);
      }
      expect(result!.progress, greaterThan(.96));
      expect(result.cue, TraceCue.release);
    }
  });
}
