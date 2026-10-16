import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/scene_play.dart';
import 'package:flutter_application_1/features/story/domain/story_cues.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/scene_play_stage.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';

import '../tool/voice_catalog.dart';

class _FailingStore extends MemoryStore {
  bool reject = false;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (reject && key == 'story') throw StateError('disk full');
    await super.write(key, value);
  }
}

void main() {
  testWidgets(
    'turning off motion or hiding a live reaction cancels every particle',
    (tester) async {
      var animate = true, active = true;
      final found = <int>[];
      StateSetter? refresh;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                refresh = setState;
                return SizedBox(
                  width: 640,
                  height: 320,
                  child: TickerMode(
                    enabled: active,
                    child: ScenePlayStage(
                      play: ScenePlay.moments.first,
                      count: 3,
                      found: List.of(found),
                      animate: animate,
                      active: active,
                      onDiscover: (i) => setState(() => found.add(i)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final game = tester
          .widget<GameWidget<ScenePlayGame>>(
            find.byType(GameWidget<ScenePlayGame>),
          )
          .game!;
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('scene-prop-0'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.props.first.burst, greaterThan(0));
      refresh!(() => animate = false);
      await tester.pumpAndSettle();
      expect(game.props.every((p) => p.burst == 0), isTrue);
      expect(game.paused, isTrue);
      refresh!(() {
        animate = true;
        found.add(1);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.props[1].burst, greaterThan(0));
      refresh!(() => active = false);
      await tester.pumpAndSettle();
      expect(game.paused, isTrue);
      expect(game.props.every((p) => p.burst == 0), isTrue);
      refresh!(() => active = true);
      await tester.pumpAndSettle();
      expect(game.paused, isTrue);
      expect(game.props.every((p) => p.burst == 0), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test(
    'scene play instructions and restore variants have exact voice scripts',
    () {
      final lines = buildVoiceCatalog();
      final m = StoryMachine();
      for (var chapter = 0; chapter < 12; chapter++) {
        for (var level = 2; level <= 5; level++) {
          var s = StorySnapshot(episode: chapter, level: level);
          expect(
            lines.any((l) => l.language == 'ko-KR' && l.text == m.narration(s)),
            isTrue,
          );
          final play = ScenePlay.forSnapshot(s)!;
          for (var i = 0; i < play.count(level); i++) {
            s = m.discoverSceneProp(s, i);
          }
          expect(
            lines.any((l) => l.language == 'ko-KR' && l.text == m.narration(s)),
            isTrue,
          );
          expect(lines.any((l) => l.text == play.response), isTrue);
        }
      }
    },
  );

  testWidgets(
    'all twelve Flame prop types render, collect and resize while idle',
    (tester) async {
      for (final play in ScenePlay.moments) {
        final found = <int>[];
        StateSetter? refresh;
        var size = const Size(640, 320);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                key: ValueKey(play.kind),
                builder: (context, setState) {
                  refresh = setState;
                  return SizedBox(
                    width: size.width,
                    height: size.height,
                    child: ScenePlayStage(
                      play: play,
                      count: 3,
                      found: List.of(found),
                      animate: false,
                      active: true,
                      onDiscover: (i) => setState(() => found.add(i)),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final game = tester
            .widget<GameWidget<ScenePlayGame>>(
              find.byType(GameWidget<ScenePlayGame>),
            )
            .game!;
        expect(game.paused, isTrue);
        await tester.tapAt(
          tester.getCenter(find.byKey(const ValueKey('scene-prop-0'))),
        );
        await tester.pumpAndSettle();
        expect(found, [0], reason: play.kind.name);
        refresh!(() => size = const Size(328, 180));
        await tester.pumpAndSettle();
        await tester.tapAt(
          tester.getCenter(find.byKey(const ValueKey('scene-prop-1'))),
        );
        await tester.pumpAndSettle();
        expect(found, [0, 1], reason: '${play.kind.name} after resize');
        expect(game.paused, isTrue);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (var level = 2; level <= 5; level++) {
    test(
      'all 12 scene moments persist, deduplicate and leave freely at level $level',
      () async {
        final machine = StoryMachine();
        final repository = StoryRepository(MemoryStore());
        for (var chapter = 0; chapter < 12; chapter++) {
          var s = StorySnapshot(episode: chapter, level: level);
          expect(machine.scene(s).interaction, StoryPhase.dialogue);
          final play = ScenePlay.forSnapshot(s)!;
          final count = play.count(level);
          expect(
            count,
            level == 2
                ? 1
                : level == 3
                ? 2
                : 3,
          );
          expect(machine.discoverSceneProp(s, -1), same(s));
          expect(machine.discoverSceneProp(s, count), same(s));
          final free = machine.advance(s);
          expect(
            free.scene,
            1,
            reason: 'Optional play must not block the story',
          );
          for (var i = 0; i < count; i++) {
            final before = s;
            s = machine.discoverSceneProp(s, i);
            expect(StoryCues.between(before, s), isNotNull);
            expect(machine.discoverSceneProp(s, i), same(s));
            await repository.save(s);
            s = machine.restore((await repository.load())!);
            expect(s.sceneFinds, List.generate(i + 1, (n) => n));
            expect(s.observedObjects, isEmpty);
            expect(StoryCues.between(null, s), isNull);
          }
          expect(machine.advance(s).sceneFinds, isEmpty);
          expect(machine.text(s), play.response);
          expect(
            machine.narration(s),
            play.response,
            reason: 'Do not keep saying the light is missing after it returns',
          );
        }
      },
    );
  }

  test(
    'legacy, malformed indices, relevel and required quiz never inherit props',
    () {
      final m = StoryMachine();
      expect(StorySnapshot.fromJson({'phase': 'dialogue'}).sceneFinds, isEmpty);
      final dirty = StorySnapshot.fromJson({
        'sceneFinds': [0, 0, -1, 9, 'bad'],
        'level': 5,
      });
      expect(m.restore(dirty).sceneFinds, [0]);
      expect(m.relevel(dirty, 2).sceneFinds, [0]);
      final quiz = dirty.change({'phase': 'quiz'});
      expect(m.discoverSceneProp(quiz, 1), same(quiz));
      expect(m.restore(quiz).sceneFinds, isEmpty);
      expect(m.restore(dirty.change({'scene': 1})).sceneFinds, isEmpty);
      for (final size in [const Size(328, 52), const Size(780, 140)]) {
        final areas = ScenePlayGame.targets(size, 3);
        for (var i = 0; i < areas.length; i++) {
          expect(areas[i].width, greaterThanOrEqualTo(48));
          expect((Offset.zero & size).contains(areas[i].topLeft), isTrue);
          if (i > 0) expect(areas[i - 1].overlaps(areas[i]), isFalse);
        }
      }
    },
  );

  for (final motion in [true, false]) {
    testWidgets(
      'Flame taps, failed saves, accessibility, idle and resume; motion=$motion',
      (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = _FailingStore();
        await ProfileRepository(store).save(
          ParentSettings(
            age: 5,
            level: 5,
            autoRead: false,
            voiceVolume: 0,
            effectsVolume: 0,
            animations: motion,
          ),
        );
        final c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(container: c, child: const KkomaApp()),
        );
        await tester.pumpAndSettle();
        c.read(routerProvider).go('/story');
        await tester.pumpAndSettle();
        final game = tester.state<State<ScenePlayStage>>(
          find.byType(ScenePlayStage),
        );
        // The actual engine is mounted and paused, not an unrendered loading stub.
        final stage = tester.widget<ScenePlayStage>(
          find.byType(ScenePlayStage),
        );
        expect(stage.count, 3);
        final engine = tester
            .widget<GameWidget<ScenePlayGame>>(
              find.byType(GameWidget<ScenePlayGame>),
            )
            .game!;
        expect(engine.isMounted, isTrue);
        expect(engine.paused, isTrue);
        expect(game.mounted, isTrue);
        final prop = find.byKey(const ValueKey('scene-prop-0'));
        store.reject = true;
        await tester.tapAt(tester.getCenter(prop));
        await tester.pumpAndSettle();
        expect(c.read(storyProvider).requireValue.sceneFinds, isEmpty);
        expect(
          find.text('진도를 저장하지 못했어요. 다시 눌러 주세요.'),
          findsOneWidget,
          reason: 'A real Flame tap must reach the save operation',
        );
        store.reject = false;
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tapAt(tester.getCenter(prop));
        await tester.pumpAndSettle();
        expect(c.read(storyProvider).requireValue.sceneFinds, [0]);
        // Use the semantics action for the second target, rather than a pointer.
        final second = tester.getSemantics(
          find.byKey(const ValueKey('scene-prop-1')),
        );
        tester.binding.performSemanticsAction(
          ui.SemanticsActionEvent(
            type: SemanticsAction.tap,
            nodeId: second.id,
            viewId: tester.view.viewId,
          ),
        );
        await tester.pumpAndSettle();
        expect(c.read(storyProvider).requireValue.sceneFinds, [0, 1]);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        await tester.tapAt(
          tester.getCenter(find.byKey(const ValueKey('scene-prop-2'))),
        );
        await tester.pumpAndSettle();
        expect(c.read(storyProvider).requireValue.sceneFinds, [0, 1, 2]);
        expect(engine.paused, isTrue);
        expect(find.text(ScenePlay.moments.first.response), findsOneWidget);
        c.read(routerProvider).go('/');
        await tester.pumpAndSettle();
        c.read(routerProvider).go('/story');
        await tester.pumpAndSettle();
        expect(c.read(storyProvider).requireValue.sceneFinds, [0, 1, 2]);
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
        semantics.dispose();
      },
    );
  }
}
