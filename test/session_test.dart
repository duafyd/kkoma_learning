import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/learning/presentation/learning_vm.dart';
import 'package:flutter_application_1/features/learning/data/learning_repository.dart';
import 'package:flutter_application_1/features/profile/presentation/profile_vm.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_vm.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/progress/data/progress_repository.dart';

void main() {
  test(
    'learning session resumes and parent level changes replace adaptive path',
    () async {
      final store = MemoryStore(), repo = LearningRepository(store);
      await repo.save(
        'math',
        const LearningSession(level: 5, baseLevel: 4, index: 7, answered: true),
      );
      final saved = await LearningRepository(store).load('math', 4);
      expect(saved.index, 7);
      expect(saved.level, 5);
      expect(saved.answered, true);
      final overridden = await repo.load('math', 2);
      expect(overridden.level, 2);
      expect(overridden.index, 0);
    },
  );
  test('rapid taps cannot record the same quiz twice', () async {
    final store = MemoryStore();
    final container = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(learningProvider('math'), (_, _) {});
    addTearDown(sub.close);
    await container.read(learningProvider('math').future);
    final vm = container.read(learningProvider('math').notifier);
    final id = vm.quiz.id;
    await Future.wait([vm.answer(vm.quiz.answer), vm.answer(vm.quiz.answer)]);
    expect((await ProgressRepository(store).load())[id]['attempts'], 1);
    expect(
      container.read(learningProvider('math')).requireValue.answered,
      true,
    );
  });
  test('trace stroke survives a new provider container', () async {
    final store = MemoryStore();
    final a = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    final sub = a.listen(traceProvider('h-ㅏ'), (_, _) {});
    await a.read(traceProvider('h-ㅏ').future);
    await a
        .read(traceProvider('h-ㅏ').notifier)
        .submit(tracePaths['ㅏ']!.first.samples(80), 5);
    sub.close();
    a.dispose();
    final b = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    addTearDown(b.dispose);
    final sub2 = b.listen(traceProvider('h-ㅏ'), (_, _) {});
    addTearDown(sub2.close);
    final restored = await b.read(traceProvider('h-ㅏ').future);
    expect(restored.strokeIndex, 1);
    expect(restored.done, false);
  });
  test(
    'parallel parent settings changes do not overwrite other values',
    () async {
      final store = MemoryStore(),
          c = ProviderContainer(
            overrides: [storeProvider.overrideWithValue(store)],
          );
      addTearDown(c.dispose);
      await c.read(settingsProvider.future);
      final vm = c.read(settingsProvider.notifier);
      await Future.wait([vm.change('age', 5), vm.change('voiceVolume', 0.0)]);
      final saved = await ProfileRepository(store).load();
      expect(saved.age, 5);
      expect(saved.voiceVolume, 0);
    },
  );
  test('progress reset preserves settings and artwork data', () async {
    final store = MemoryStore();
    await ProfileRepository(store).save(const ParentSettings(age: 4));
    await store.write('artworks', {'items': []});
    await store.write('story', {'episode': 3});
    await store.write('session-math', {'index': 4});
    await ProgressRepository(store).reset();
    expect(await store.read('story'), isNull);
    expect(await store.read('session-math'), isNull);
    expect(await store.read('artworks'), isNotNull);
    expect((await ProfileRepository(store).load()).age, 4);
  });
}
