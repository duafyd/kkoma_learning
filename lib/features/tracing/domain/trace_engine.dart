import 'dart:math' as math;

import '../../profile/domain/settings.dart';

class TracePoint {
  final double x, y;
  const TracePoint(this.x, this.y);
  double distance(TracePoint p) =>
      math.sqrt(math.pow(x - p.x, 2) + math.pow(y - p.y, 2));
  List<double> toJson() => [x, y];
  factory TracePoint.fromJson(List<dynamic> j) =>
      TracePoint((j[0] as num).toDouble(), (j[1] as num).toDouble());
}

class StrokePath {
  final List<TracePoint> points;
  const StrokePath(this.points);

  /// Remove sub-pixel touch noise without rounding off intentional corners.
  StrokePath simplified(double tolerance) {
    if (points.length < 3) return this;
    final keep = <int>{0, points.length - 1};
    final pending = <(int, int)>[(0, points.length - 1)];
    while (pending.isNotEmpty) {
      final (first, last) = pending.removeLast();
      final a = points[first], b = points[last];
      final dx = b.x - a.x, dy = b.y - a.y;
      final squareLength = dx * dx + dy * dy;
      var farthest = tolerance, split = -1;
      var peak = 0.0, peakIndex = first;
      for (var i = first + 1; i < last; i++) {
        final p = points[i];
        final t = squareLength == 0
            ? 0.0
            : (((p.x - a.x) * dx + (p.y - a.y) * dy) / squareLength).clamp(
                0.0,
                1.0,
              );
        final distance = p.distance(TracePoint(a.x + t * dx, a.y + t * dy));
        // Spatial simplification alone erases a collinear out-and-back scribble.
        // Keep turning points whenever motion reverses beyond the noise budget.
        if (squareLength > 0 &&
            peakIndex > first &&
            (peak - t) * math.sqrt(squareLength) > tolerance * 2) {
          split = peakIndex;
          break;
        }
        if (t > peak) {
          peak = t;
          peakIndex = i;
        }
        if (distance > farthest) {
          farthest = distance;
          split = i;
        }
      }
      if (split != -1) {
        keep.add(split);
        pending.addAll([(first, split), (split, last)]);
      }
    }
    return StrokePath((keep.toList()..sort()).map((i) => points[i]).toList());
  }

  double get length {
    var n = 0.0;
    for (var i = 1; i < points.length; i++) {
      n += points[i - 1].distance(points[i]);
    }
    return n;
  }

  List<TracePoint> samples([int count = 40]) {
    final total = length;
    if (total == 0) return points;
    final result = <TracePoint>[];
    for (var s = 0; s <= count; s++) {
      if (s == count) {
        result.add(points.last);
        continue;
      }
      final target = s / count * total;
      var consumed = 0.0;
      for (var i = 1; i < points.length; i++) {
        final a = points[i - 1], b = points[i];
        final segment = a.distance(b);
        if (consumed + segment >= target && segment > 0) {
          final t = (target - consumed) / segment;
          result.add(TracePoint(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t));
          break;
        }
        consumed += segment;
      }
    }
    return result;
  }
}

enum TraceFeedback { complete, tryPath, startHere, followArrow, keepGoing }

class TraceResult {
  final bool accepted;
  final TraceFeedback feedback;
  final double coverage;
  const TraceResult(this.accepted, this.feedback, this.coverage);
}

class TraceStrategy {
  final AgeStrategy age;
  const TraceStrategy(this.age);
  TraceResult evaluate(StrokePath stroke, List<TracePoint> input) {
    // A tap and excursions outside the canvas cannot complete a stroke.
    final valid = input
        .where((p) => p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1)
        .toList();
    if (valid.length < 2) {
      return const TraceResult(false, TraceFeedback.keepGoing, 0);
    }
    // Small strokes need a proportionately small corridor too. A fixed canvas
    // tolerance used to let a scribble cover an entire syllable component.
    final tolerance = math.min(
      age.traceTolerance,
      math.max(.018, stroke.length * (age.requireDirection ? .16 : .22)),
    );
    final samples = stroke.samples(80);
    final drawn = StrokePath(valid).simplified(math.min(.01, tolerance * .6));
    final tracedSamples = drawn.samples(80);
    final coverage =
        samples
            .where((p) => tracedSamples.any((v) => p.distance(v) <= tolerance))
            .length /
        samples.length;
    final inputLength = drawn.length;
    if (inputLength < stroke.length * (age.requireDirection ? .78 : .68)) {
      return TraceResult(false, TraceFeedback.keepGoing, coverage);
    }
    if (inputLength > stroke.length * (age.requireDirection ? 1.65 : 1.9)) {
      return TraceResult(false, TraceFeedback.tryPath, coverage);
    }
    if (age.requireDirection &&
        valid.first.distance(stroke.points.first) > tolerance * 1.7) {
      return TraceResult(false, TraceFeedback.startHere, coverage);
    }
    // Both paths are sampled by travelled distance, so drawing speed does not
    // affect matching. Corresponding positions must follow the whole guide;
    // passing near the same points in a different order is insufficient.
    double orderedDistance(List<TracePoint> guide) {
      var distance = 0.0;
      for (var i = 0; i < tracedSamples.length; i++) {
        distance = math.max(distance, tracedSamples[i].distance(guide[i]));
      }
      return distance;
    }

    var distance = orderedDistance(samples);
    if (!age.requireDirection) {
      final reverse = samples.reversed.toList();
      final reverseDistance = orderedDistance(reverse);
      if (reverseDistance < distance) {
        distance = reverseDistance;
      }
    }
    if (distance > tolerance) {
      return TraceResult(false, TraceFeedback.tryPath, coverage);
    }
    return TraceResult(true, TraceFeedback.complete, coverage);
  }
}
