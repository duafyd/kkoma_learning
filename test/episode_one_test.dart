import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/episode_one.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';
import 'package:flutter_application_1/features/learning/domain/learning_models.dart';

class _FailingStoryStore extends MemoryStore {
  bool fail = false;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (fail && key == 'story') throw StateError('disk full');
    await super.write(key, value);
  }
}

StorySnapshot reviewSnapshot([int level = 5]) => StorySnapshot(
  level: level,
  scene: episodeOne.forLevel(level).indexWhere((s) => s.id == 'ep1-review'),
  phase: StoryPhase.quiz,
);

void main() {
  test('chapter one preserves legacy scene IDs and age ordering', () {
    expect(
      episodeOne.scenes.map((s) => s.id),
      [
        'start',
        'discover',
        'choice',
        'quiz',
        'clue',
        'trace',
        'review',
        'talk',
        'together',
        'end',
      ].map((id) => 'ep1-$id'),
    );
    for (final age in [2, 3, 4, 5]) {
      expect(episodeOne.forLevel(age).length, AgeStrategy(age).sceneCount);
      final machine = StoryMachine();
      final legacy = StorySnapshot.fromJson({
        'episode': 0,
        'scene': 1,
        'level': age,
        'phase': episodeOne.forLevel(age)[1].interaction.name,
      });
      expect(machine.restore(legacy).scene, 1);
      expect(legacy.observedObjects, isEmpty);
    }
    expect(episodeOne.scenes.first.background, 'ep1-quiet');
    expect(episodeOne.scenes.last.background, 'ep1-map');
    expect(episodeOne.scenes.map((s) => s.background).toSet().length, 3);
  });
  test(
    'picture answers match the story props and count has one exact answer',
    () {
      for (final q
          in episodeOne.scenes.map((s) => s.quiz).whereType<QuizDefinition>()) {
        final art = q.artwork!;
        expect(art.choices.length, q.options.length);
        bool same(List<QuizGlyph> a, List<QuizGlyph> b) =>
            a.length == b.length && a.indexed.every((v) => v.$2 == b[v.$1]);
        expect(
          art.choices.where((v) => same(v, art.objects)).length,
          1,
          reason: q.id,
        );
        expect(same(art.choices[q.answer], art.objects), true, reason: q.id);
        if (art.countOnTap) {
          expect(q.kind, QuizKind.count);
          expect(q.options[q.answer], '${art.objects.length}개');
        }
      }
      final machine = StoryMachine();
      final explore = StorySnapshot(level: 2, scene: 2, phase: StoryPhase.quiz);
      expect(machine.quiz(explore).id, episodeOneExplore.id);
      for (var i = 0; i < machine.quiz(explore).options.length; i++) {
        expect(machine.answer(explore, i).phase, StoryPhase.success);
      }
    },
  );
  test('count taps are unique, persisted, optional for answer, and reset at boundaries', () async {
    final machine = StoryMachine(), repository = StoryRepository(MemoryStore());
    var s = reviewSnapshot();
    s = machine.observeObject(s, 2);
    s = machine.observeObject(s, 2);
    s = machine.observeObject(s, -1);
    s = machine.observeObject(s, 3);
    expect(s.observedObjects, [2]);
    expect(s.phase, StoryPhase.quiz);
    expect(s.attempts, 0);
    s = machine.observeObject(s, 0);
    await repository.save(s);
    s = machine.restore((await repository.load())!);
    expect(s.observedObjects, [2, 0]);
    expect(machine.observeObject(s, 1).message, contains('모두 3개'));
    final success = machine.answer(s, machine.quiz(s).answer);
    expect(success.phase, StoryPhase.success);
    expect(machine.advance(success).observedObjects, isEmpty);
    expect(machine.easier(s).observedObjects, isEmpty);
    expect(machine.quiz(machine.easier(s)).artwork, isNull);
    expect(machine.relevel(s, 2).observedObjects, isEmpty);
    expect(machine.answer(reviewSnapshot(), 2).phase, StoryPhase.success);
    expect(
      machine
          .restore(
            s.change({
              'observedObjects': [0, 77],
            }),
          )
          .observedObjects,
      [0],
    );
  });
  test(
    'failed count save does not advance UI, retry and reload preserve count',
    () async {
      final store = _FailingStoryStore();
      await ProfileRepository(store)
          .save(const ParentSettings(age: 5, level: 5));
      await StoryRepository(store).save(reviewSnapshot());
      final c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      final sub = c.listen(storyProvider, (_, _) {});
      addTearDown(() {
        sub.close();
        c.dispose();
      });
      await c.read(storyProvider.future);
      store.fail = true;
      await expectLater(
        c.read(storyProvider.notifier).observeObject(1),
        throwsStateError,
      );
      expect(c.read(storyProvider).requireValue.observedObjects, isEmpty);
      store.fail = false;
      await c.read(storyProvider.notifier).observeObject(1);
      await c.read(storyProvider.notifier).observeObject(1);
      expect(c.read(storyProvider).requireValue.observedObjects, [1]);
      expect((await StoryRepository(store).load())!.observedObjects, [1]);
    },
  );
}
