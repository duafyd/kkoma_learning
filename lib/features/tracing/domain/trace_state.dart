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
}
