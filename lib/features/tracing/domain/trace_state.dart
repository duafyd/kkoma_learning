import 'trace_engine.dart';

class TraceState {
  final int strokeIndex;
  final List<List<TracePoint>> completed;
  final String message;
  final bool done;
  const TraceState({
    this.strokeIndex = 0,
    this.completed = const [],
    this.message = '빛나는 점에서 시작해요.',
    this.done = false,
  });
  Map<String, dynamic> toJson() => {
    'strokeIndex': strokeIndex,
    'completed': completed
        .map((s) => s.map((p) => p.toJson()).toList())
        .toList(),
    'message': message,
    'done': done,
  };
  factory TraceState.fromJson(Map<String, dynamic> j) => TraceState(
    strokeIndex: j['strokeIndex'] as int? ?? 0,
    completed: (j['completed'] as List? ?? [])
        .map(
          (s) =>
              (s as List).map((p) => TracePoint.fromJson(p as List)).toList(),
        )
        .toList(),
    message: j['message'] as String? ?? '빛나는 점에서 시작해요.',
    done: j['done'] as bool? ?? false,
  );

  /// Derive completion from committed ink, never from a contradictory flag.
  /// Invalid documents stay in storage; the visible activity starts safely.
  static TraceState restore(Map<String, dynamic>? raw, int strokeCount) {
    if (raw == null || strokeCount <= 0) return const TraceState();
    try {
      final saved = TraceState.fromJson(raw);
      if (saved.strokeIndex < 0 ||
          saved.strokeIndex > strokeCount ||
          saved.completed.length != saved.strokeIndex) {
        return const TraceState();
      }
      final ink = [
        for (final line in saved.completed)
          line
              .where(
                (p) =>
                    p.x.isFinite &&
                    p.y.isFinite &&
                    p.x >= 0 &&
                    p.x <= 1 &&
                    p.y >= 0 &&
                    p.y <= 1,
              )
              .toList(),
      ];
      if (ink.any((line) => line.isEmpty)) return const TraceState();
      final done = saved.strokeIndex == strokeCount;
      return TraceState(
        strokeIndex: saved.strokeIndex,
        completed: ink,
        done: done,
        message: saved.done == done
            ? saved.message
            : done
            ? '끝까지 따라 그렸어요! 멋진 집중이에요.'
            : '빛나는 점에서 이어서 그려요.',
      );
    } on TypeError {
      return const TraceState();
    } on RangeError {
      return const TraceState();
    }
  }
}
