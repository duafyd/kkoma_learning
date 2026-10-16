import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/scene_play.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';

StoryEpisode _pages(StoryEpisode e, List<StoryScene> scenes) => StoryEpisode(
  id: e.id,
  title: e.title,
  goal: e.goal,
  reward: e.reward,
  scenes: scenes,
);

StorySnapshot _at(String id, {int level = 5}) {
  final episode = storyEpisodes.indexWhere(
    (e) => e.scenes.any((s) => s.id == id),
  );
  final pages = storyEpisodes[episode].forLevel(level);
  final index = pages.indexWhere((s) => s.id == id);
  return StoryMachine().restore(
    StorySnapshot(
      episode: episode,
      scene: index,
      level: level,
      phase: pages[index].interaction,
      flags: const {
        'route': '영어 길',
        'companion': '토토',
        'gardenArtwork': 'kept',
      },
      completed: const [1],
    ),
  );
}

class _WriteFailure extends MemoryStore {
  bool fail = false;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key == 'story' && fail) throw const FileSystemException('full');
    await super.write(key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'legacy numeric saves bind IDs in memory without rewriting the document',
    () async {
      final store = MemoryStore();
      final legacy = _at('ep2-trace').toJson()
        ..remove('episodeId')
        ..remove('sceneId');
      await store.write('story', legacy);
      final machine = StoryMachine();
      final saved = machine.restore((await StoryRepository(store).load())!);
      expect(saved.episodeId, 2);
      expect(saved.sceneId, 'ep2-trace');
      expect(await store.read('story'), legacy);
      await StoryRepository(store).save(machine.hint(saved));
      expect((await store.read('story'))!['sceneId'], 'ep2-trace');
      expect((await store.read('story'))!['hints'], 1);
    },
  );

  test('episode and page identities win over stale positions after insertion and reorder', () {
    final old = StoryMachine().hint(_at('ep2-quiz'));
    final e = storyEpisodes[1];
    final modified = _pages(e, [
      const StoryScene(id: 'inserted', text: '새 장면'),
      ...e.scenes.reversed,
    ]);
    final machine = StoryMachine([modified, storyEpisodes.first]);
    final restored = machine.restore(old);
    expect(restored.episode, 0);
    expect(machine.scene(restored).id, 'ep2-quiz');
    expect(restored.scene, isNot(old.scene));
    expect(restored.hints, 1);
    expect(restored.flags, old.flags);
    expect(restored.completed, old.completed);
    expect(machine.restore(restored).toJson(), restored.toJson());
  });

  test(
    'missing page restarts its own chapter without transplanting mission state',
    () {
      final old = StoryMachine().easier(_at('ep2-trace')).change({
        'attempts': 3,
        'hints': 2,
        'assisted': true,
        'message': '옛 미션',
        'observedObjects': [0],
        'sceneFinds': [0],
      });
      final e = storyEpisodes[1];
      final machine = StoryMachine([
        storyEpisodes.first,
        _pages(e, e.scenes.where((p) => p.id != old.sceneId).toList()),
      ]);
      final restored = machine.restore(old);
      expect(restored.episodeId, 2);
      expect(restored.sceneId, 'ep2-start');
      expect(restored.phase, StoryPhase.dialogue);
      expect(restored.hints, 0);
      expect(restored.attempts, 0);
      expect(restored.supportSceneId, isNull);
      expect(restored.assisted, isFalse);
      expect(restored.message, isEmpty);
      expect(restored.observedObjects, isEmpty);
      expect(restored.sceneFinds, isEmpty);
      expect(restored.flags, old.flags);
      expect(restored.completed, [1]);
    },
  );

  test('unknown episode and invalid legacy position retain season choices and rewards', () {
    final machine = StoryMachine();
    for (final old in [
      _at('ep2-quiz').change({'episodeId': 99}),
      const StorySnapshot(
        episode: -1,
        flags: {'room': '별 방'},
        completed: [1, 2],
      ),
      const StorySnapshot(episode: 1, scene: 999, completed: [1]),
    ]) {
      final next = machine.restore(old);
      expect(next.flags, old.flags);
      expect(next.completed, old.completed);
      expect(next.phase, StoryPhase.dialogue);
      expect(next.scene, 0);
      expect(next.sceneId, isNotNull);
    }
  });

  test(
    'age filtering skips an ineligible page and clears the previous activity',
    () {
      final machine = StoryMachine();
      final old = machine.hint(_at('ep2-trace')).change({'attempts': 4});
      final next = machine.relevel(old, 2);
      expect(next.sceneId, 'ep2-end');
      expect(next.phase, StoryPhase.dialogue);
      expect(next.hints, 0);
      expect(next.attempts, 0);
      expect(next.message, isEmpty);
      expect(next.flags, old.flags);
      // Also handles a saved ID which became ineligible within the same level.
      expect(machine.restore(old.change({'level': 2})).sceneId, 'ep2-end');
    },
  );

  test(
    'same eligible page preserves help, branch and committed ink on age change',
    () {
      final machine = StoryMachine();
      var s = _at('ep2-trace', level: 3);
      final item = learningItems.firstWhere((i) => i.id == 'h-ㅏ');
      s = machine.trace(s, item.strokes.first.samples(80));
      s = machine.hint(s);
      final higher = machine.relevel(s, 5);
      expect(higher.sceneId, s.sceneId);
      expect(higher.strokes.length, 1);
      expect(higher.hints, s.hints);
      expect(higher.flags, s.flags);
      final help = machine.easier(higher);
      final restored = machine.restore(StorySnapshot.fromJson(help.toJson()));
      expect(restored.toJson(), help.toJson());
      expect(machine.quiz(restored).id, 'story-support-h-ㅏ');
    },
  );

  test('partial, complete and malformed trace checkpoints never strand an activity', () {
    final machine = StoryMachine();
    final item = learningItems.firstWhere((i) => i.id == 'h-ㅏ');
    final base = _at('ep2-trace');
    final full = base.change({
      'strokes': [
        for (final path in item.strokes)
          path.samples(80).map((p) => p.toJson()).toList(),
      ],
    });
    expect(machine.restore(full).phase, StoryPhase.success);
    final partial = machine.trace(base, item.strokes.first.samples(80));
    expect(machine.restore(partial).strokes.length, 1);
    expect(
      machine.restore(partial.change({'phase': 'success'})).strokes,
      isEmpty,
    );
    final invalid = base.change({
      'strokes': [
        [
          [2.0, 2.0],
        ],
      ],
    });
    expect(machine.restore(invalid).strokes, isEmpty);
    final assisted = partial.change({'phase': 'success', 'assisted': true});
    expect(machine.restore(assisted).phase, StoryPhase.success);
  });

  test(
    'wrong support and impossible phase reset only the current activity',
    () {
      final machine = StoryMachine();
      for (final old in [
        _at('ep2-quiz').change({'supportSceneId': 'ep1-quiz', 'hints': 2}),
        _at('ep2-quiz').change({'phase': 'drawing', 'hints': 2}),
        _at('ep2-quiz').change({'phase': 'finished', 'hints': 2}),
      ]) {
        final restored = machine.restore(old);
        expect(restored.phase, StoryPhase.quiz);
        expect(restored.supportSceneId, isNull);
        expect(restored.hints, 0);
        expect(restored.flags, old.flags);
      }
    },
  );

  test('chapter and season endings survive restoration and retain stable reward IDs', () {
    final machine = StoryMachine();
    var s = _at('ep12-end');
    s = machine.advance(s);
    expect(s.phase, StoryPhase.episodeComplete);
    expect(machine.restore(s).toJson(), s.toJson());
    s = machine.advance(s);
    expect(s.phase, StoryPhase.finished);
    expect(machine.restore(s).toJson(), s.toJson());
    expect(s.completed, contains(12));
    final reversed = StoryMachine(storyEpisodes.reversed.toList());
    final chapter = reversed.restore(_at('ep2-end'));
    expect(reversed.advance(chapter).completed, contains(2));
  });

  test(
    'opening props follow authored page and episode IDs after page insertion',
    () {
      final e = storyEpisodes[1];
      final machine = StoryMachine([
        _pages(e, [const StoryScene(id: 'preface', text: '앞장'), ...e.scenes]),
      ]);
      final restored = machine.restore(_at('ep2-start'));
      expect(restored.scene, 1);
      expect(ScenePlay.forSnapshot(restored)!.kind, ScenePropKind.flower);
      expect(machine.narrationId(restored), 'voice-scene-play-2-level-5');
      expect(ScenePlay.forSnapshot(machine.begin(5)), isNull);
    },
  );

  test('conditional replacement handles legacy and moved IDs while rejecting stale hints', () async {
    final store = MemoryStore();
    final s = _at('ep2-quiz');
    final legacy = s.toJson()
      ..remove('sceneId')
      ..remove('episodeId');
    await store.write('story', legacy);
    final repo = StoryRepository(store);
    final next = StoryMachine().hint(s);
    expect(await repo.replaceIfCurrent(s, next), isTrue);
    expect(await repo.replaceIfCurrent(s, next), isFalse);
    final e = storyEpisodes[1];
    final machine = StoryMachine([
      _pages(e, [const StoryScene(id: 'prefix', text: '앞장'), ...e.scenes]),
    ]);
    final movedRepo = StoryRepository(store, machine: machine);
    final moved = machine.restore(next);
    expect(
      await movedRepo.replaceIfCurrent(moved, machine.hint(moved)),
      isTrue,
    );
    await store.remove('story');
    expect(await movedRepo.replaceIfCurrent(moved, next), isFalse);
  });

  test('VM reads stale positions without writing and a failed transition preserves checkpoint', () async {
    final store = _WriteFailure();
    await ProfileRepository(store).save(const ParentSettings(level: 5));
    final s = _at('ep2-quiz');
    final raw = s.change({'episode': 999, 'scene': -1}).toJson();
    await store.write('story', raw);
    var c = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    try {
      final saved = await c.read(storyProvider.future);
      expect(saved.sceneId, s.sceneId);
      expect(saved.episode, 1);
      expect(await store.read('story'), raw);
      store.fail = true;
      await expectLater(
        c.read(storyProvider.notifier).hint(),
        throwsA(isA<FileSystemException>()),
      );
      expect(c.read(storyProvider).requireValue.hints, 0);
      expect(await store.read('story'), raw);
      store.fail = false;
      await c.read(storyProvider.notifier).hint();
      c.dispose();
      c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      expect((await c.read(storyProvider.future)).hints, 1);
      expect((await c.read(storyProvider.future)).sceneId, s.sceneId);
    } finally {
      c.dispose();
    }
  });

  for (var level = 2; level <= 5; level++) {
    test(
      'every checkpoint across twelve chapters round-trips by ID at level $level',
      () async {
        final machine = StoryMachine();
        final repo = StoryRepository(MemoryStore());
        var s = machine.begin(level);
        var steps = 0;
        while (s.phase != StoryPhase.finished && steps++ < 500) {
          await repo.save(s);
          final restored = machine.restore((await repo.load())!);
          expect(restored.toJson(), s.toJson());
          expect(restored.sceneId, machine.scene(restored).id);
          expect(restored.episodeId, machine.episodes[restored.episode].id);
          s = switch (s.phase) {
            StoryPhase.choice => machine.choose(s, 0),
            StoryPhase.quiz || StoryPhase.tracing => machine.easier(s),
            StoryPhase.drawing => machine.drawingComplete(s),
            _ => machine.advance(s),
          };
          if (s.supportSceneId != null && s.phase == StoryPhase.quiz) {
            s = machine.hint(s);
            await repo.save(s);
            s = machine.restore((await repo.load())!);
            s = machine.answer(s, machine.quiz(s).answer);
          }
        }
        expect(s.phase, StoryPhase.finished);
        expect(s.completed, List.generate(12, (i) => i + 1));
      },
    );
  }
}
