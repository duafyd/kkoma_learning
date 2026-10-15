import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../profile/domain/settings.dart';
import '../../profile/presentation/profile_vm.dart';
import '../../tracing/domain/trace_engine.dart';
import '../data/story_repository.dart';
import '../domain/story_models.dart';
import '../domain/story_machine.dart';

final storyRepositoryProvider = Provider(
  (ref) => StoryRepository(ref.watch(storeProvider)),
);
final storyProvider = AsyncNotifierProvider<StoryVM, StorySnapshot>(
  StoryVM.new,
);

class StoryVM extends AsyncNotifier<StorySnapshot> {
  final machine = StoryMachine();
  bool busy = false;
  @override
  Future<StorySnapshot> build() async {
    final settings = await ref.watch(settingsProvider.future);
    final saved = await ref.read(storyRepositoryProvider).load();
    return saved == null
        ? machine.begin(settings.level)
        : machine.relevel(machine.restore(saved), settings.level);
  }

  Future<void> _transition(StorySnapshot Function(StorySnapshot) change) async {
    if (busy || !state.hasValue) return;
    busy = true;
    try {
      final next = change(state.requireValue);
      await ref.read(storyRepositoryProvider).save(next);
      state = AsyncData(next);
    } finally {
      busy = false;
    }
  }

  Future<void> advance() => _transition(machine.advance);
  Future<void> choose(int i) => _transition((s) => machine.choose(s, i));
  Future<void> answer(int i) => _transition((s) => machine.answer(s, i));
  Future<void> hint() => _transition(machine.hint);
  Future<void> easier() => _transition(machine.easier);
  Future<void> assist() => _transition(
    (s) => machine.assist(
      s,
      ref.read(settingsProvider).value ?? const ParentSettings(),
    ),
  );
  Future<void> trace(List<TracePoint> points) =>
      _transition((s) => machine.trace(s, points));
  Future<void> drawingComplete() => _transition(machine.drawingComplete);
  Future<void> resetStrokes() => _transition((s) => s.change({'strokes': []}));
}
