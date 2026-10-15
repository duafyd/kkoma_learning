import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/math/domain/sorting.dart';
import 'package:flutter_application_1/features/math/data/sorting_content.dart';
import 'package:flutter_application_1/features/math/data/sorting_repository.dart';
import 'package:flutter_application_1/features/math/presentation/sorting_vm.dart';
import 'package:flutter_application_1/features/progress/data/progress_repository.dart';

class SortingGateStore extends MemoryStore {
  bool block = false, reject = false;
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (block && key == 'math-sorting-3') {
      if (!entered.isCompleted) entered.complete();
      await release.future;
    }
    if (reject && key == 'math-sorting-3') throw StateError('storage full');
    await super.write(key, value);
  }
}

void main() {
  for (var age = 2; age <= 5; age++) {
    test('all quantity and classification rounds complete at age $age', () {
      final rounds = sortingRounds(age),
          rules = SortingRules(sortingRounds(age));
      expect(rounds.map((r) => r.id).toSet().length, 12);
      var s = const SortingState();
      for (final round in rounds) {
        expect(round.targets.toSet().length, round.targets.length);
        if (round.kind == SortingKind.quantity) {
          expect(
            round.pieces.every(
              (n) =>
                  n >= 1 &&
                  n <=
                      (age == 2
                          ? 3
                          : age == 3
                          ? 5
                          : 10),
            ),
            true,
          );
        }
        expect(identical(rules.next(s), s), true);
        for (var p = 0; p < round.pieces.length; p++) {
          final correct = round.targets.indexOf(round.pieces[p]);
          final wrong = (correct + 1) % round.targets.length;
          s = rules.place(s, p, wrong);
          expect(s.placed.containsKey(p), false);
          s = rules.hint(s);
          expect(rules.hintTarget(s), correct);
          s = rules.place(s, p, correct);
          final count = s.placed.length;
          s = rules.place(s, p, correct);
          expect(s.placed.length, count);
        }
        expect(rules.done(s), true);
        s = rules.next(s);
      }
      expect(s.round, 0);
    });
  }
  test(
    'invalid placement, corrupted saved progress and help rules are safe',
    () {
      final rules = SortingRules(sortingRounds(3));
      var s = const SortingState();
      expect(identical(rules.place(s, -1, 0), s), true);
      s = rules.place(s, 0, 0);
      expect(rules.done(rules.assist(s, allowed: false, after: 1)), false);
      expect(rules.done(rules.assist(s, allowed: true, after: 3)), false);
      s = rules.assist(s, allowed: true, after: 1);
      expect(rules.done(s), true);
      expect(s.assisted, true);
      expect(rules.restore(const SortingState(round: 99)).round, 0);
      expect(
        rules.restore(const SortingState(placed: {99: 0})).placed,
        isEmpty,
      );
    },
  );
  test('placements and selected piece survive a new container', () async {
    final store = MemoryStore();
    var c = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    var sub = c.listen(sortingProvider(3), (_, _) {});
    await c.read(sortingProvider(3).future);
    await c.read(sortingProvider(3).notifier).place(0, 1);
    await c.read(sortingProvider(3).notifier).select(1);
    sub.close();
    c.dispose();
    c = ProviderContainer(overrides: [storeProvider.overrideWithValue(store)]);
    sub = c.listen(sortingProvider(3), (_, _) {});
    addTearDown(() {
      sub.close();
      c.dispose();
    });
    final restored = await c.read(sortingProvider(3).future);
    expect(restored.placed, {0: 1});
    expect(restored.selected, 1);
  });
  test(
    'save delay blocks reset and failure allows retry without losing state',
    () async {
      final store = SortingGateStore();
      final container = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      final sub = container.listen(sortingProvider(3), (_, _) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });
      await container.read(sortingProvider(3).future);
      final vm = container.read(sortingProvider(3).notifier);
      store.block = true;
      final pending = vm.place(0, 1);
      await store.entered.future;
      await vm.reset();
      await vm.place(0, 1);
      store.release.complete();
      await pending;
      expect(container.read(sortingProvider(3)).requireValue.placed.length, 1);
      store.reject = true;
      await expectLater(vm.place(1, 0), throwsStateError);
      expect(container.read(sortingProvider(3)).requireValue.placed.length, 1);
      store.reject = false;
      await vm.place(1, 0);
      expect(
        vm.rules.done(container.read(sortingProvider(3)).requireValue),
        true,
      );
      store.reject = true;
      await expectLater(vm.next(), throwsStateError);
      store.reject = false;
      await Future.wait([vm.next(), vm.next()]);
      final progress = await ProgressRepository(store).load();
      expect(progress.values.single['successes'], 1);
      expect(progress.values.single['attempts'], 2);
      expect(container.read(sortingProvider(3)).requireValue.round, 1);
      await ProgressRepository(store).reset();
      expect((await SortingRepository(store).load(3)).placed, isEmpty);
    },
  );
}
