import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../profile/presentation/profile_vm.dart';
import '../../profile/domain/settings.dart';
import '../../progress/data/progress_repository.dart';
import '../data/sorting_content.dart';
import '../data/sorting_repository.dart';
import '../domain/sorting.dart';

final sortingProvider = AsyncNotifierProvider.autoDispose
    .family<SortingVM, SortingState, int>(SortingVM.new);

class SortingVM extends AsyncNotifier<SortingState> {
  final int level;
  late final rules = SortingRules(sortingRounds(level));
  bool busy = false;
  SortingVM(this.level);
  @override
  Future<SortingState> build() async => rules.restore(
    await SortingRepository(ref.read(storeProvider)).load(level),
  );
  Future<void> _change(
    SortingState Function(SortingState) action, {
    bool complete = false,
  }) async {
    if (busy || !state.hasValue) return;
    busy = true;
    try {
      final old = state.requireValue, next = action(old);
      if (identical(old, next)) return;
      final repository = SortingRepository(ref.read(storeProvider));
      final progress = ref.read(progressRepositoryProvider);
      if (complete && rules.done(old)) {
        await progress.completeOnce(
          'sorting-$level-${rules.activity(old).id}',
          assisted: old.assisted,
          attempts: old.failures + old.placed.length,
        );
      }
      await repository.save(level, next);
      if (ref.mounted) state = AsyncData(next);
    } finally {
      busy = false;
    }
  }

  Future<void> select(int piece) => _change((s) => rules.select(s, piece));
  Future<void> place(int piece, int target) =>
      _change((s) => rules.place(s, piece, target));
  Future<void> hint() => _change(rules.hint);
  Future<void> assist() => _change((s) {
    final settings = ref.read(settingsProvider).value ?? const ParentSettings();
    return rules.assist(s, allowed: settings.help, after: settings.helpAfter);
  });
  Future<void> next() => _change(rules.next, complete: true);

  Future<void> reset() => _change((s) => SortingState(round: s.round));
  Future<void> mode(SortingKind kind) => _change(
    (s) => rules.activity(s).kind == kind
        ? s
        : SortingState(round: rules.rounds.indexWhere((r) => r.kind == kind)),
    complete: true,
  );
}
