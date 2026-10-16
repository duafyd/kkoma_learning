import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/settings.dart';
import '../domain/counting.dart';
export '../domain/counting.dart';

final countingProvider = NotifierProvider.autoDispose
    .family<CountingVM, CountingState, int>(CountingVM.new);

class CountingVM extends Notifier<CountingState> {
  final int level;
  CountingVM(this.level);
  @override
  CountingState build() => CountingState(AgeStrategy(level).maxCount);
  void collect(int id) {
    if (id < 0 || id >= state.available || state.basket.contains(id)) return;
    state = CountingState(
      state.available,
      basket: {...state.basket, id},
      change: CountingChange(state.basket.length, state.basket.length + 1),
    );
  }

  void add() {
    if (level < 4 || state.basket.length >= state.available) return;
    collect(
      List.generate(
        state.available,
        (i) => i,
      ).firstWhere((i) => !state.basket.contains(i)),
    );
  }

  void remove() {
    if (level < 4 || state.basket.isEmpty) return;
    state = CountingState(
      state.available,
      basket: {...state.basket}..remove(state.basket.last),
      change: CountingChange(state.basket.length, state.basket.length - 1),
    );
  }

  void reset() => state = CountingState(state.available);
}
