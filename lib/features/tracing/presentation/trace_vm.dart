import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/trace_catalog.dart';
import '../data/prewriting_content.dart';
import '../../profile/domain/settings.dart';
import '../../progress/data/progress_repository.dart';
import '../domain/trace_engine.dart';

import '../domain/trace_state.dart';
import '../data/trace_repository.dart';
export '../domain/trace_state.dart';

final traceProvider = AsyncNotifierProvider.autoDispose
    .family<TraceVM, TraceState, String>(TraceVM.new);

class TraceVM extends AsyncNotifier<TraceState> {
  final String itemId;
  bool busy = false;
  late TraceRepository repository;
  TraceVM(this.itemId);
  String? nextItemId(int level) {
    final current = traceItems.firstWhere((i) => i.id == itemId);
    final available = traceItems
        .where(
          (i) =>
              i.subject == current.subject &&
              i.minimumLevel <= level &&
              i.strokes.isNotEmpty,
        )
        .toList();
    final index = available.indexWhere((i) => i.id == itemId);
    return index >= 0 && index + 1 < available.length
        ? available[index + 1].id
        : null;
  }

  @override
  Future<TraceState> build() async {
    repository = ref.read(traceRepositoryProvider);
    final item = traceItems.firstWhere((i) => i.id == itemId);
    return TraceState.restore(
      await repository.load(itemId),
      item.strokes.length,
    );
  }

  Future<void> _save(TraceState next) async {
    await repository.save(itemId, next);
    if (ref.mounted) state = AsyncData(next);
  }

  Future<void> submit(List<TracePoint> input, int level) async {
    if (busy || !state.hasValue || state.requireValue.done) return;
    busy = true;
    final progress = ref.read(progressRepositoryProvider);
    try {
      final old = state.requireValue,
          item = traceItems.firstWhere((i) => i.id == itemId);
      final strategy = item.subject == 'prewriting'
          ? PrewritingStrategy(AgeStrategy(level))
          : TraceStrategy(AgeStrategy(level));
      final result = strategy.evaluate(item.strokes[old.strokeIndex], input);
      if (!result.accepted) {
        const messages = {
          TraceFeedback.startHere: '빛나는 점에서 다시 시작해 볼까요?',
          TraceFeedback.followArrow: '화살표 방향으로 천천히 가요.',
          TraceFeedback.tryPath: '넓은 길을 따라 함께 가요.',
          TraceFeedback.keepGoing: '조금 더 길게 이어 보아요.',
        };
        await _save(
          TraceState(
            strokeIndex: old.strokeIndex,
            completed: old.completed,
            message: messages[result.feedback] ?? '다시 해 보아요.',
          ),
        );
        await progress.record('trace-$itemId', false);
        return;
      }
      final next = old.strokeIndex + 1, done = next == item.strokes.length;
      if (done) {
        await progress.record('trace-$itemId', true);
      }
      await _save(
        TraceState(
          strokeIndex: next,
          completed: [...old.completed, input],
          done: done,
          message: done ? '끝까지 따라 그렸어요! 멋진 집중이에요.' : '좋아요! 다음 빛나는 점을 찾아요.',
        ),
      );
    } finally {
      busy = false;
    }
  }

  Future<void> reset() async {
    if (busy || !state.hasValue) return;
    busy = true;
    try {
      await _save(const TraceState());
    } finally {
      busy = false;
    }
  }
}
