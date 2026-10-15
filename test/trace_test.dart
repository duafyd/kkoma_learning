import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';

void main() {
  test(
    'sparse straight input is interpolated while a curved shortcut is rejected',
    () {
      const evaluator = TraceStrategy(AgeStrategy(5));
      final straight = tracePaths['1']!.single;
      expect(evaluator.evaluate(straight, straight.points).accepted, true);
      final curved = tracePaths['C']!.single;
      expect(
        evaluator.evaluate(curved, [
          curved.points.first,
          curved.points.last,
        ]).accepted,
        false,
      );
    },
  );
  final path = tracePaths['ㄱ']!.first;
  const strict = TraceStrategy(AgeStrategy(5));
  test('ordered full trace succeeds for every supported stroke', () {
    for (final entry in tracePaths.entries) {
      for (final path in entry.value) {
        expect(
          strict.evaluate(path, path.samples(80)).accepted,
          true,
          reason: entry.key,
        );
      }
    }
  });
  test('reverse and wrong start rejected for older learners', () {
    expect(
      strict.evaluate(path, path.samples().reversed.toList()).accepted,
      false,
    );
    expect(
      strict.evaluate(path, [
        const TracePoint(.8, .8),
        const TracePoint(.1, .1),
      ]).accepted,
      false,
    );
  });
  test('tap, incomplete and out-of-canvas do not complete', () {
    expect(strict.evaluate(path, [path.points.first]).accepted, false);
    expect(
      strict.evaluate(path, path.samples().take(8).toList()).accepted,
      false,
    );
    expect(
      strict.evaluate(path, [
        const TracePoint(-1, -1),
        const TracePoint(2, 2),
      ]).accepted,
      false,
    );
  });
  test('younger learners can explore reversed strokes', () {
    expect(
      const TraceStrategy(AgeStrategy(2))
          .evaluate(path, path.samples().reversed.toList())
          .accepted,
      true,
    );
  });
  test('a small tremor and an outlier do not defeat a good stroke', () {
    final points = path.samples(80);
    points.insert(20, const TracePoint(1.2, 1.2));
    points[40] = TracePoint(points[40].x + .02, points[40].y + .02);
    expect(strict.evaluate(path, points).accepted, true);
  });
}
