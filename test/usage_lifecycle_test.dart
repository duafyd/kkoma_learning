import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/parent/presentation/usage_vm.dart';
import 'package:flutter_application_1/features/parent/data/usage_repository.dart';

class ManualStopwatch implements Stopwatch {
  int milliseconds = 0;
  bool running = false;
  void advance(Duration time) {
    if (running) milliseconds += time.inMilliseconds;
  }

  @override
  int get frequency => 1000000;
  @override
  int get elapsedTicks => elapsedMicroseconds;
  @override
  int get elapsedMicroseconds => milliseconds * 1000;
  @override
  int get elapsedMilliseconds => milliseconds;
  @override
  Duration get elapsed => Duration(milliseconds: milliseconds);
  @override
  bool get isRunning => running;
  @override
  void start() {
    running = true;
  }

  @override
  void stop() {
    running = false;
  }

  @override
  void reset() {
    milliseconds = 0;
  }
}

class UsageGateStore extends MemoryStore {
  bool blockLoad = false, blockWrite = false, reject = false;
  final loaded = Completer<void>(),
      releaseLoad = Completer<void>(),
      writing = Completer<void>(),
      releaseWrite = Completer<void>();
  @override
  Future<Map<String, dynamic>?> read(String key) async {
    if (key == 'daily-usage' && blockLoad) {
      loaded.complete();
      await releaseLoad.future;
    }
    return super.read(key);
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key == 'daily-usage') {
      if (blockWrite) {
        if (!writing.isCompleted) writing.complete();
        await releaseWrite.future;
      }
      if (reject) throw StateError('full');
    }
    await super.write(key, value);
  }
}

void main() {
  test(
    'background time is excluded even when pause checkpoint is slow',
    () async {
      final store = UsageGateStore(), clock = ManualStopwatch();
      final c = ProviderContainer(
        overrides: [
          storeProvider.overrideWithValue(store),
          usageClockProvider.overrideWithValue(clock),
        ],
      );
      addTearDown(c.dispose);
      await c.read(usageProvider.future);
      final vm = c.read(usageProvider.notifier);
      clock.advance(const Duration(seconds: 3));
      store.blockWrite = true;
      final paused = vm.setActive(false);
      await store.writing.future;
      expect(clock.isRunning, false);
      clock.advance(const Duration(minutes: 2));
      final resumed = vm.setActive(true);
      expect(clock.isRunning, true);
      clock.advance(const Duration(seconds: 2));
      store.releaseWrite.complete();
      await Future.wait([paused, resumed]);
      await vm.tick();
      expect(c.read(usageProvider).requireValue.seconds, 5);
      expect((await UsageRepository(store).load(DateTime.now())).seconds, 5);
    },
  );
  test('app paused during initial loading does not start the clock', () async {
    final store = UsageGateStore()..blockLoad = true, clock = ManualStopwatch();
    final c = ProviderContainer(
      overrides: [
        storeProvider.overrideWithValue(store),
        usageClockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(c.dispose);
    final loading = c.read(usageProvider.future);
    await store.loaded.future;
    final vm = c.read(usageProvider.notifier);
    await vm.setActive(false);
    store.releaseLoad.complete();
    await loading;
    expect(clock.isRunning, false);
    clock.advance(const Duration(minutes: 2));
    await vm.setActive(true);
    clock.advance(const Duration(seconds: 1));
    await vm.tick();
    expect(c.read(usageProvider).requireValue.seconds, 1);
  });
  test(
    'failed usage checkpoint keeps elapsed time for the next successful save',
    () async {
      final store = UsageGateStore(), clock = ManualStopwatch();
      final c = ProviderContainer(
        overrides: [
          storeProvider.overrideWithValue(store),
          usageClockProvider.overrideWithValue(clock),
        ],
      );
      addTearDown(c.dispose);
      await c.read(usageProvider.future);
      final vm = c.read(usageProvider.notifier);
      store.reject = true;
      clock.advance(const Duration(seconds: 3));
      await vm.tick();
      store.reject = false;
      clock.advance(const Duration(seconds: 2));
      await vm.tick();
      expect((await UsageRepository(store).load(DateTime.now())).seconds, 5);
    },
  );
}
