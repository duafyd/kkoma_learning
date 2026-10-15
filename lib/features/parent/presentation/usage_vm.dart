import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../profile/presentation/profile_vm.dart';
import '../data/usage_repository.dart';
import '../domain/usage.dart';

final usageRepositoryProvider = Provider(
  (ref) => UsageRepository(ref.watch(storeProvider)),
);
final usageProvider = AsyncNotifierProvider<UsageVM, UsageRecord>(UsageVM.new);
final usageClockProvider = Provider<Stopwatch>((ref) => Stopwatch());

class UsageVM extends AsyncNotifier<UsageRecord> {
  Timer? timer;
  late Stopwatch clock;
  int consumedMilliseconds = 0;
  Future<void> writes = Future.value();
  bool active = true;
  @override
  Future<UsageRecord> build() async {
    clock = ref.read(usageClockProvider);
    ref.onDispose(() {
      timer?.cancel();
      clock.stop();
    });
    final record = await ref.read(usageRepositoryProvider).load(DateTime.now());
    if (!ref.mounted) return record;
    if (active) clock.start();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => tick());
    return record;
  }

  bool get expired =>
      state.value?.expired(ref.read(settingsProvider).value?.minutes ?? 20) ??
      false;
  Future<void> tick() async {
    if (!state.hasValue || !active) return;
    final now = DateTime.now(),
        elapsed = (clock.elapsedMilliseconds - consumedMilliseconds) ~/ 1000;
    consumedMilliseconds += elapsed * 1000;
    final next = state.requireValue.accrue(now, elapsed);
    state = AsyncData(next);
    final repo = ref.read(usageRepositoryProvider);
    writes = writes.catchError((Object _) {}).then((_) => repo.save(next));
    try {
      await writes;
    } catch (_) {}
  }

  Future<void> setActive(bool next) async {
    final checkpoint = active ? tick() : Future<void>.value();
    // Pause the clock immediately; storage latency must never count as play time.
    active = next;
    if (next) {
      clock.start();
    } else {
      clock.stop();
    }
    await checkpoint;
  }

  Future<bool> boundary() async {
    await tick();
    return expired;
  }
}
