import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_art.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_illustration.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';
import 'package:flutter_application_1/features/story/presentation/world_mission_layout.dart';
import 'package:flutter_application_1/features/story/presentation/world_mission_stage.dart';

import '../tool/voice_catalog.dart';

class _Store extends MemoryStore {
  bool reject = false;
  Completer<void>? gate;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key == 'story' && gate != null) await gate!.future;
    if (reject && key == 'story') throw StateError('disk full');
    await super.write(key, value);
  }
}

StorySnapshot _scene(int chapter, int level) {
  final m = StoryMachine();
  final scenes = m.episodes[chapter - 1].forLevel(level);
  return StorySnapshot(
    episode: chapter - 1,
    level: level,
    scene: scenes.indexWhere((s) => s.id == 'ep$chapter-quiz'),
    phase: StoryPhase.quiz,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('WORLD_CAPTURE');
  setUpAll(() async {
    if (!capture) return;
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
    for (final (name, path) in [
      ('Roboto', 'C:/Windows/Fonts/malgun.ttf'),
      (
        'MaterialIcons',
        'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    ]) {
      final file = File(path);
      if (file.existsSync()) {
        await (FontLoader(name)..addFont(
              Future.value(ByteData.sublistView(file.readAsBytesSync())),
            ))
            .load();
      }
    }
  });
  test('world direction preserves age-two exploration, support and required answers', () {
    final m = StoryMachine();
    final scripts = buildVoiceCatalog();
    for (final chapter in [6, 11]) {
      expect(m.worldMission(_scene(chapter, 2)), isNull);
      for (var level = 3; level <= 5; level++) {
        var s = _scene(chapter, level);
        final mission = m.worldMission(s)!;
        expect(scripts.any((l) => l.text == m.narration(s)), isTrue);
        expect(m.narration(s), contains(mission.instruction));
        expect(mission.count, chapter == 6 ? 3 : 5);
        expect(m.canAnswer(s), isFalse);
        expect(m.worldMission(m.easier(s)), isNull);
        expect(m.worldMission(m.originalMission(m.easier(s))), isNotNull);
        expect(m.placeObject(s, 0, 1).observedObjects, isEmpty);
        for (var i = 0; i < mission.count; i++) {
          s = m.placeObject(s, i, i);
          expect(s.observedObjects.length, i + 1);
        }
        expect(m.canAnswer(s), isTrue);
        expect(m.narration(s), m.quiz(s).prompt);
        final solved = m.answer(s, m.quiz(s).answer);
        expect(m.text(solved), solved.message);
        expect(m.worldMission(solved), isNotNull);
        expect(solved.phase, StoryPhase.success);
      }
    }
  });
  testWidgets(
    'pending save, two fingers, cancellation, background and rotation preserve committed pieces',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = _Store();
      await ProfileRepository(store).save(
        const ParentSettings(
          age: 5,
          level: 5,
          autoRead: false,
          animations: false,
          voiceVolume: 0,
          effectsVolume: 0,
        ),
      );
      await StoryRepository(store).save(_scene(6, 5));
      final c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const KkomaApp()),
      );
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/story');
      await tester.pumpAndSettle();
      WorldMissionGame engine() => tester
          .widget<GameWidget<WorldMissionGame>>(
            find.byType(GameWidget<WorldMissionGame>),
          )
          .game!;
      Finder source(int i) => find.byKey(ValueKey('world-piece-$i'));
      Finder slot(int i) => find.byKey(ValueKey('world-slot-$i'));
      store.gate = Completer<void>();
      await tester.tapAt(tester.getCenter(source(0)));
      await tester.pumpAndSettle();
      expect(engine().pending, 0);
      expect(engine().placed, isEmpty);
      await tester.tapAt(tester.getCenter(source(1)));
      await tester.pumpAndSettle();
      expect(engine().pending, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      store.gate!.complete();
      await tester.pumpAndSettle();
      store.gate = null;
      expect(c.read(storyProvider).requireValue.observedObjects, [0]);
      expect(engine().paused, isTrue);
      expect(engine().pulse, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(engine().paused, isTrue);
      final first = await tester.startGesture(
        tester.getCenter(source(1)),
        pointer: 10,
      );
      await first.moveTo(
        Offset.lerp(
          tester.getCenter(source(1)),
          tester.getCenter(slot(1)),
          .5,
        )!,
      );
      await tester.pump();
      expect(engine().dragging, 1);
      final second = await tester.startGesture(
        tester.getCenter(source(2)),
        pointer: 11,
      );
      await second.moveTo(
        Offset.lerp(
          tester.getCenter(source(2)),
          tester.getCenter(slot(2)),
          .5,
        )!,
      );
      await second.up();
      await tester.pump();
      expect(engine().dragging, 1);
      await first.cancel();
      await tester.pumpAndSettle();
      expect(engine().dragging, isNull);
      expect(c.read(storyProvider).requireValue.observedObjects, [0]);
      final rotating = await tester.startGesture(
        tester.getCenter(source(1)),
        pointer: 12,
      );
      await rotating.moveTo(
        Offset.lerp(
          tester.getCenter(source(1)),
          tester.getCenter(slot(1)),
          .5,
        )!,
      );
      await tester.pump();
      expect(engine().dragging, 1);
      tester.view.physicalSize = const Size(800, 1280);
      await tester.pumpAndSettle();
      await rotating.up();
      await tester.pumpAndSettle();
      expect(engine().dragging, isNull);
      expect(c.read(storyProvider).requireValue.observedObjects, [0]);
      expect(engine().paused, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
  );

  for (final systemMotion in [false, true]) {
    testWidgets(
      'motion preference cancels a live journey; system reduced motion=$systemMotion',
      (tester) async {
        var solved = false, animate = true;
        StateSetter? refresh;
        final m = StoryMachine().worldMission(_scene(6, 5))!;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  refresh = setState;
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(disableAnimations: systemMotion),
                    child: SizedBox(
                      width: 640,
                      height: 400,
                      child: WorldMissionStage(
                        mission: m,
                        placed: const [0, 1, 2],
                        solved: solved,
                        animate: animate,
                        active: true,
                        onPlace: (_, _) async {},
                        onJourney: (_) {},
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
            .widget<GameWidget<WorldMissionGame>>(
              find.byType(GameWidget<WorldMissionGame>),
            )
            .game!;
        refresh!(() => solved = true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(game.journey, systemMotion ? 1 : lessThan(1));
        refresh!(() => animate = false);
        await tester.pumpAndSettle();
        expect(game.journey, 1);
        expect(game.pulse, 0);
        expect(game.paused, isTrue);
        refresh!(() => animate = true);
        await tester.pumpAndSettle();
        expect(game.journey, 1);
        expect(game.paused, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  test('large sources and slots remain inside all three mission viewports', () {
    for (final size in [
      const Size(328, 300),
      const Size(744, 300),
      const Size(752, 658),
    ]) {
      for (final count in [3, 5]) {
        final l = WorldMissionLayout(size, count, count == 3);
        for (var i = 0; i < count; i++) {
          expect(l.source(i).width, greaterThanOrEqualTo(48));
          expect(l.slot(i).width, greaterThanOrEqualTo(48));
          for (final rect in [l.source(i), l.slot(i)]) {
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.top, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
          }
          expect(l.slotAt(l.slot(i).center), i);
          expect(l.source(i).overlaps(l.slot(i)), isFalse);
          if (i > 0) expect(l.source(i - 1).overlaps(l.source(i)), isFalse);
        }
        expect(l.slotAt(const Offset(-1, -1)), isNull);
      }
    }
  });
  for (final chapter in [6, 11]) {
    for (final (label, size) in [
      ('tablet', const Size(1280, 800)),
      ('phone', const Size(360, 780)),
      ('landscape', const Size(780, 360)),
    ]) {
      testWidgets(
        'chapter $chapter world drag, retry, tap, resolution and restore on $label',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final store = _Store();
          await ProfileRepository(store).save(
            const ParentSettings(
              age: 5,
              level: 5,
              autoRead: false,
              voiceVolume: 0,
              effectsVolume: 0,
            ),
          );
          await StoryRepository(store).save(_scene(chapter, 5));
          final c = ProviderContainer(
            overrides: [storeProvider.overrideWithValue(store)],
          );
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: c,
              child: RepaintBoundary(
                key: const ValueKey('world-screen'),
                child: const KkomaApp(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (capture) {
            await tester.runAsync(() async {
              final context = tester.element(find.byType(MaterialApp));
              for (final bg in [
                'ep6-bridge',
                'ep6-built',
                'ep11-empty',
                'ep11-lit',
              ]) {
                await precacheImage(
                  ResizeImage(
                    AssetImage(StoryIllustration.assetFor(bg)),
                    width: 1536,
                  ),
                  context,
                );
              }
              for (final atlas in [storyCastAsset, storySearchCastAsset]) {
                await precacheImage(
                  ResizeImage(AssetImage(atlas), width: 1024),
                  context,
                );
              }
            });
            await tester.pumpAndSettle();
          }
          Future<void> photo(String step) async {
            if (!capture) return;
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('world-screen')),
              );
              final image = await boundary.toImage();
              try {
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File('docs/screenshots/world-$chapter-$step-$label.png')
                    .writeAsBytes(bytes!.buffer.asUint8List());
              } finally {
                image.dispose();
              }
            });
          }

          Future<void> bring(Finder target, [double align = .8]) async {
            await tester.ensureVisible(target);
            await Scrollable.ensureVisible(
              tester.element(target),
              alignment: align,
            );
            await tester.pumpAndSettle();
          }

          c.read(routerProvider).go('/story');
          await tester.pumpAndSettle();
          final engine = tester
              .widget<GameWidget<WorldMissionGame>>(
                find.byType(GameWidget<WorldMissionGame>),
              )
              .game!;
          expect(engine.isMounted, isTrue);
          expect(engine.paused, isTrue);
          final source = find.byKey(const ValueKey('world-piece-0'));
          final target = find.byKey(const ValueKey('world-slot-0'));
          await bring(source);
          await photo('before');
          final answer = find.byKey(const ValueKey('picture-answer-1'));
          expect(tester.widget<FilledButton>(answer).onPressed, isNull);
          Future<void> dragTo(Finder destination) async {
            await bring(source);
            await tester.timedDragFrom(
              tester.getCenter(source),
              tester.getCenter(destination) - tester.getCenter(source),
              const Duration(milliseconds: 500),
            );
            await tester.pumpAndSettle();
          }

          await dragTo(
            find.byKey(ValueKey('world-slot-${chapter == 6 ? 2 : 4}')),
          );
          expect(c.read(storyProvider).requireValue.observedObjects, isEmpty);
          store.reject = true;
          await dragTo(target);
          expect(c.read(storyProvider).requireValue.observedObjects, isEmpty);
          expect(engine.placed, isEmpty);
          expect(engine.pending, isNull);
          store.reject = false;
          await tester.pump(const Duration(seconds: 5));
          await tester.pumpAndSettle();
          await dragTo(target);
          expect(c.read(storyProvider).requireValue.observedObjects, [0]);
          await tester.tapAt(tester.getCenter(source));
          await tester.pumpAndSettle();
          expect(c.read(storyProvider).requireValue.observedObjects, [0]);
          final count = chapter == 6 ? 3 : 5;
          for (var i = 1; i < count; i++) {
            final piece = find.byKey(ValueKey('world-piece-$i'));
            await bring(piece);
            await tester.tapAt(tester.getCenter(piece));
            await tester.pumpAndSettle();
          }
          expect(engine.placed.length, count);
          expect(engine.journey, 0);
          expect(tester.widget<FilledButton>(answer).onPressed, isNotNull);
          await bring(answer, .5);
          await tester.tap(answer);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(engine.solved, isTrue);
          expect(engine.journey, lessThan(1));
          await Scrollable.ensureVisible(
            tester.element(find.byType(WorldMissionStage)),
            alignment: 0,
          );
          await tester.pump(const Duration(milliseconds: 600));
          await photo('journey');
          await tester.pumpAndSettle();
          expect(engine.journey, 1);
          expect(engine.paused, isTrue);
          await photo('after');
          c.invalidate(storyProvider);
          await tester.pumpAndSettle();
          final restored = tester
              .widget<GameWidget<WorldMissionGame>>(
                find.byType(GameWidget<WorldMissionGame>),
              )
              .game!;
          expect(restored.journey, 1);
          expect(restored.remaining, 0);
          expect(restored.paused, isTrue);
          expect(c.read(storyProvider).requireValue.phase, StoryPhase.success);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          c.dispose();
        },
      );
    }
  }
}
