import 'dart:math' as math;

import 'trace_engine.dart';

enum TraceCue { start, path, direction, flowing, release }

class TracePreview {
  final double progress;
  final TraceCue cue;
  const TracePreview(this.progress, this.cue);
  String get message => switch (cue) {
    TraceCue.start => '빛나는 시작점에서 출발해요',
    TraceCue.path => '괜찮아요, 밝은 길로 돌아와요',
    TraceCue.direction => '화살표 쪽으로 천천히 가요',
    TraceCue.flowing => '좋아요, 길을 따라 이어 가요',
    TraceCue.release => '끝점에 왔어요. 손을 떼어 볼까요?',
  };
  bool get onPath => cue == TraceCue.flowing || cue == TraceCue.release;
}

/// A transient, incremental guide, never an acceptance test or a saved score.
/// Bounded sample search means long gestures do not re-scan all earlier input.
class TraceCoach {
  final TraceStrategy strategy;
  final StrokePath stroke;
  late List<TracePoint> guide = stroke.samples(100);
  int frontier = 0;
  TracePoint? previous;
  bool wrongStart = false, directionChosen = false;
  TraceCoach(this.stroke, this.strategy);

  TracePreview add(TracePoint point) {
    if (strategy.acceptsTap(stroke)) {
      final near =
          point.distance(stroke.points.first) <= strategy.toleranceFor(stroke);
      return TracePreview(
        near ? 1 : 0,
        near ? TraceCue.release : TraceCue.start,
      );
    }
    if (stroke.length == 0 || !point.x.isFinite || !point.y.isFinite) {
      return const TracePreview(0, TraceCue.start);
    }
    final tolerance = strategy.toleranceFor(stroke);
    final last = previous;
    previous = point;
    if (last == null) {
      if (!strategy.age.requireDirection &&
          point.distance(guide.last) < point.distance(guide.first)) {
        guide = guide.reversed.toList();
      }
      wrongStart = point.distance(guide.first) > tolerance * 1.7;
    } else if (!directionChosen && last.distance(point) > .004) {
      directionChosen = true;
      // Closed letters have the same two endpoints. Young learners can explore
      // either direction without a misleading "return to the path" cue.
      if (!strategy.age.requireDirection &&
          guide.first.distance(guide.last) < tolerance &&
          point.distance(guide[guide.length - 3]) < point.distance(guide[2])) {
        guide = guide.reversed.toList();
      }
    }
    if (wrongStart) return TracePreview(frontier / 100, TraceCue.start);
    var nearest = 0;
    var distance = double.infinity;
    // Search near the visited prefix, allowing advancement in proportion to
    // this pointer movement, rather than jumping across intersections/loops.
    final step = last == null ? 0.0 : last.distance(point);
    final allowance = math.max(
      4,
      ((step + tolerance) / stroke.length * 100).ceil(),
    );
    final end = math.min(100, frontier + allowance);
    for (var i = math.max(0, frontier - 12); i <= end; i++) {
      final candidate = point.distance(guide[i]);
      if (candidate < distance) {
        distance = candidate;
        nearest = i;
      }
    }
    if (distance > tolerance) {
      return TracePreview(frontier / 100, TraceCue.path);
    }
    if (strategy.age.requireDirection && nearest < frontier - 4) {
      return TracePreview(frontier / 100, TraceCue.direction);
    }
    frontier = math.max(frontier, nearest);
    return TracePreview(
      frontier / 100,
      frontier >= 97 ? TraceCue.release : TraceCue.flowing,
    );
  }
}
