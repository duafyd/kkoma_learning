import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/learning/presentation/learning_vm.dart';
import 'package:flutter_application_1/features/learning/data/learning_repository.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_vm.dart';

class BlockedStore extends MemoryStore {
  String? blockedKey;
  bool reject = false;
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key == blockedKey) {
      if (!entered.isCompleted) entered.complete();
      await release.future;
      if (reject) throw StateError('disk full');
    }
    await super.write(key, value);
  }
}

void main() {
  test('hint and easier cannot overwrite a quiz answer being saved', () async {
    final store = BlockedStore(),
        c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
    addTearDown(c.dispose);
    final sub = c.listen(learningProvider('math'), (_, _) {});
    addTearDown(sub.close);
    await c.read(learningProvider('math').future);
    final vm = c.read(learningProvider('math').notifier);
    store.blockedKey = 'session-math';
    final answer = vm.answer(vm.quiz.answer);
    await store.entered.future;
    try {
      await Future.wait([vm.showHint(), vm.easier()])
          .timeout(const Duration(seconds: 2));
    } finally {
      store.release.complete();
      await answer;
    }
    final saved = await LearningRepository(store).load('math', 3);
    expect(saved.answered, true);
    expect(saved.level, 3);
    expect(saved.hint, 0);
    expect(
      c.read(learningProvider('math')).requireValue.toJson(),
      saved.toJson(),
    );
  });
  test(
    'double next advances once and cannot restore an older hint state',
    () async {
      final store = BlockedStore(),
          c = ProviderContainer(
            overrides: [storeProvider.overrideWithValue(store)],
          );
      addTearDown(c.dispose);
      final sub = c.listen(learningProvider('math'), (_, _) {});
      addTearDown(sub.close);
      await c.read(learningProvider('math').future);
      final vm = c.read(learningProvider('math').notifier);
      await vm.answer(vm.quiz.answer);
      store.blockedKey = 'session-math';
      final next = vm.next();
      await store.entered.future;
      try {
        await Future.wait([vm.next(), vm.showHint()])
            .timeout(const Duration(seconds: 2));
      } finally {
        store.release.complete();
        await next;
      }
      final saved = await LearningRepository(store).load('math', 3);
      expect(saved.index, 1);
      expect(saved.answered, false);
      expect(saved.hint, 0);
    },
  );
  test('failed session save releases the input guard for a retry', () async {
    final store = BlockedStore(),
        c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
    addTearDown(c.dispose);
    final sub = c.listen(learningProvider('math'), (_, _) {});
    addTearDown(sub.close);
    await c.read(learningProvider('math').future);
    final vm = c.read(learningProvider('math').notifier);
    store.blockedKey = 'session-math';
    store.reject = true;
    store.release.complete();
    await expectLater(vm.answer(vm.quiz.answer), throwsStateError);
    expect(vm.busy, false);
    expect(c.read(learningProvider('math')).requireValue.answered, false);
    store.reject = false;
    await vm.answer(vm.quiz.answer);
    expect(c.read(learningProvider('math')).requireValue.answered, true);
  });
  test('trace reset cannot race with a stroke being saved', () async {
    final store = BlockedStore(),
        c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
    addTearDown(c.dispose);
    final sub = c.listen(traceProvider('h-ㅏ'), (_, _) {});
    addTearDown(sub.close);
    await c.read(traceProvider('h-ㅏ').future);
    final vm = c.read(traceProvider('h-ㅏ').notifier);
    store.blockedKey = 'trace-h-ㅏ';
    final submitted = vm.submit(tracePaths['ㅏ']!.first.samples(80), 5);
    await store.entered.future;
    try {
      await vm.reset().timeout(const Duration(seconds: 2));
    } finally {
      store.release.complete();
      await submitted;
    }
    expect(c.read(traceProvider('h-ㅏ')).requireValue.strokeIndex, 1);
    expect((await store.read('trace-h-ㅏ'))!['strokeIndex'], 1);
  });
}
