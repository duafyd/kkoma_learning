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
    final tolerance = age.traceTolerance;
    final samples = stroke.samples();
    final tracedSamples = StrokePath(valid).samples(80);
    final coverage =
        samples
            .where((p) => tracedSamples.any((v) => p.distance(v) <= tolerance))
            .length /
        samples.length;
    final inputLength = StrokePath(valid).length;
    if (inputLength < stroke.length * (age.level <= 3 ? .35 : .65)) {
      return TraceResult(false, TraceFeedback.keepGoing, coverage);
    }
    if (age.requireDirection &&
        valid.first.distance(stroke.points.first) > tolerance * 1.7) {
      return TraceResult(false, TraceFeedback.startHere, coverage);
    }
    // Project the trace onto the guide; ignore small tremor and occasional outliers.
    var previous = 0;
    var reversed = 0;
    var transitions = 0;
    var near = 0;
    for (final p in valid) {
      var index = 0, distance = double.infinity, score = double.infinity;
      for (var i = 0; i < samples.length; i++) {
        final d = p.distance(samples[i]);
        final candidate = d + (i - previous).abs() * .002;
        if (candidate < score) {
          score = candidate;
          distance = d;
          index = i;
        }
      }
      if (distance <= tolerance * 1.5) near++;
      if ((index - previous).abs() >= 3) {
        transitions++;
        if (index < previous) reversed++;
        previous = index;
      }
    }
    if (age.requireDirection &&
        transitions > 0 &&
        reversed / transitions > .25) {
      return TraceResult(false, TraceFeedback.followArrow, coverage);
    }
    if (coverage < (age.level <= 3 ? .55 : .85)) {
      return TraceResult(false, TraceFeedback.keepGoing, coverage);
    }
    if (near / valid.length < .65) {
      return TraceResult(false, TraceFeedback.tryPath, coverage);
    }
    return TraceResult(true, TraceFeedback.complete, coverage);
  }
}
