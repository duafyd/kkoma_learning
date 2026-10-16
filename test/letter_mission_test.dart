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
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_art.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/letter_mission_stage.dart';
import 'package:flutter_application_1/features/story/presentation/story_illustration.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_canvas.dart';

class _Store extends MemoryStore {
  bool reject = false;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (reject && key == 'story') throw StateError('disk full');
    await super.write(key, value);
  }
}

StorySnapshot _scene(int chapter, int level, {bool trace = false}) {
  final m = StoryMachine();
  final scenes = m.episodes[chapter - 1].forLevel(level);
  return StorySnapshot(
    episode: chapter - 1,
    level: level,
    scene: scenes.indexWhere(
      (s) => s.id == 'ep$chapter-${trace ? 'trace' : 'quiz'}',
    ),
    phase: trace ? StoryPhase.tracing : StoryPhase.quiz,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('LETTER_CAPTURE');
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

  test(
    'letter direction matches real guides, age paths and easier missions',
    () {
      final m = StoryMachine();
      for (final chapter in [2, 3, 4, 5]) {
        expect(m.letterMission(_scene(chapter, 2)), isNull);
        for (final level in [3, 4, 5]) {
          final quiz = _scene(chapter, level);
          expect(m.letterMission(quiz)!.choices, switch (chapter) {
            2 => ['ㅓ', 'ㅏ'],
            3 => ['ㄴ', 'ㄱ'],
            4 => ['나', '가'],
            _ => ['B', 'A'],
          });
          expect(m.letterMission(m.easier(quiz)), isNull);
          expect(m.letterMission(m.originalMission(m.easier(quiz))), isNotNull);
          expect(m.letterMission(m.answer(quiz, 0))!.energy, 0);
          expect(m.letterMission(m.answer(quiz, 1))!.energy, 1);
          var s = _scene(chapter, level, trace: true);
          final item = learningItems.firstWhere(
            (i) => i.id == m.scene(s).traceId,
          );
          expect(m.letterMission(s)!.total, item.strokes.length);
          for (var i = 0; i < item.strokes.length; i++) {
            s = m.trace(s, item.strokes[i].samples(80));
            expect(
              m.letterMission(s)!.energy,
              closeTo((i + 1) / item.strokes.length, .0001),
            );
          }
          expect(s.phase, StoryPhase.success);
          expect(
            m
                .letterMission(m.restore(StorySnapshot.fromJson(s.toJson())))!
                .energy,
            1,
          );
        }
      }
    },
  );

  test(
    'letter targets stay separate, large and inside cropped tablet/phone art',
    () {
      final m = StoryMachine();
      for (final size in [
        const Size(328, 300),
        const Size(650, 600),
        const Size(450, 220),
      ]) {
        for (final chapter in [2, 3, 4, 5]) {
          final plan = m.letterMission(_scene(chapter, 5))!;
          final a = LetterMissionGame.choiceRect(size, plan, 0);
          final b = LetterMissionGame.choiceRect(size, plan, 1);
          expect(a.shortestSide, greaterThanOrEqualTo(56 - 1e-8));
          expect(b.shortestSide, greaterThanOrEqualTo(56 - 1e-8));
          expect(a.overlaps(b), isFalse);
          expect((Offset.zero & size).contains(a.topLeft), isTrue);
          expect((Offset.zero & size).contains(b.bottomRight), isTrue);
        }
      }
    },
  );

  testWidgets(
    'pending answer, two taps and late background save cannot replay light',
    (tester) async {
      final m = StoryMachine();
      var plan = m.letterMission(_scene(5, 5))!;
      final gate = Completer<void>();
      var requests = 0;
      Future<void> choose(int _) async {
        requests++;
        await gate.future;
      }

      Widget stage({bool animate = true, bool reduced = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: SizedBox(
            width: 600,
            height: 400,
            child: LetterMissionStage(
              mission: plan,
              animate: animate,
              active: true,
              onChoose: choose,
            ),
          ),
        ),
      );
      await tester.pumpWidget(stage());
      await tester.pumpAndSettle();
      LetterMissionGame engine() => tester
          .widget<GameWidget<LetterMissionGame>>(
            find.byType(GameWidget<LetterMissionGame>),
          )
          .game!;
      final target = find.byKey(const ValueKey('letter-world-choice-1'));
      await tester.tapAt(tester.getCenter(target));
      await tester.pump();
      await tester.tapAt(tester.getCenter(target));
      await tester.pump();
      expect(requests, 1);
      expect(engine().energy, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      plan = m.letterMission(m.answer(_scene(5, 5), 1))!;
      await tester.pumpWidget(stage());
      gate.complete();
      await tester.pumpAndSettle();
      // Flutter can defer the committed widget update while frames are paused.
      expect(engine().paused, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(engine().energy, 1);
      expect(engine().elapsed, 1.6);
      expect(engine().paused, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final reduced in [false, true]) {
    testWidgets(
      'finite stroke reaction stops for reduced=$reduced and restoration',
      (tester) async {
        final m = StoryMachine();
        final before = _scene(2, 5, trace: true);
        final item = learningItems.firstWhere(
          (i) => i.id == m.scene(before).traceId,
        );
        var plan = m.letterMission(before)!;
        var animate = true;
        Widget stage() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: LetterMissionStage(
              mission: plan,
              animate: animate,
              active: true,
            ),
          ),
        );
        await tester.pumpWidget(stage());
        await tester.pumpAndSettle();
        plan = m.letterMission(
          m.trace(before, item.strokes.first.samples(80)),
        )!;
        await tester.pumpWidget(stage());
        await tester.pump(const Duration(milliseconds: 300));
        LetterMissionGame engine() => tester
            .widget<GameWidget<LetterMissionGame>>(
              find.byType(GameWidget<LetterMissionGame>),
            )
            .game!;
        if (reduced) {
          expect(engine().energy, .5);
        } else {
          expect(engine().energy, greaterThan(0));
          expect(engine().energy, lessThan(.5));
          animate = false;
          await tester.pumpWidget(stage());
          await tester.pumpAndSettle();
          expect(engine().energy, .5);
          animate = true;
          await tester.pumpWidget(stage());
        }
        await tester.pumpAndSettle();
        expect(engine().energy, .5);
        expect(engine().paused, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(stage());
        await tester.pumpAndSettle();
        expect(engine().energy, .5);
        expect(engine().elapsed, 1.6);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final chapter in [2, 3, 4, 5]) {
    for (final (label, size) in [
      ('tablet', const Size(1280, 800)),
      ('phone', const Size(360, 780)),
      ('landscape', const Size(780, 360)),
    ]) {
      testWidgets(
        'chapter $chapter scene choices and saved ink illuminate the world at $label',
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
                key: const ValueKey('letter-screen'),
                child: const KkomaApp(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (capture) {
            await tester.runAsync(() async {
              final context = tester.element(find.byType(MaterialApp));
              for (final bg in [
                'library',
                'ep2-gate',
                'ep2-open',
                'ep3-tree',
                'ep3-seeds',
                'ep4-station',
                'ep4-ready',
                'ep5-dark',
                'ep5-lit',
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
          }
          Future<void> photo(String state) async {
            if (!capture) return;
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('letter-screen')),
              );
              final image = await boundary.toImage();
              try {
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File('docs/screenshots/letter-$chapter-$state-$label.png')
                    .writeAsBytes(bytes!.buffer.asUint8List());
              } finally {
                image.dispose();
              }
            });
          }

          StorySnapshot snapshot() => c.read(storyProvider).requireValue;
          LetterMissionGame engine() => tester
              .widget<GameWidget<LetterMissionGame>>(
                find.byType(GameWidget<LetterMissionGame>),
              )
              .game!;
          c.read(routerProvider).go('/story');
          await tester.pumpAndSettle();
          await photo('choices');
          final wrong = find.byKey(const ValueKey('letter-world-choice-0'));
          await tester.ensureVisible(wrong);
          await tester.pumpAndSettle();
          await tester.tapAt(tester.getCenter(wrong));
          await tester.pumpAndSettle();
          expect(snapshot().phase, StoryPhase.quiz);
          expect(engine().energy, 0);
          final right = find.byKey(const ValueKey('letter-world-choice-1'));
          if (label == 'tablet') {
            store.reject = true;
            await tester.tapAt(tester.getCenter(right));
            await tester.pumpAndSettle();
            expect(snapshot().phase, StoryPhase.quiz);
            expect(engine().energy, 0);
            store.reject = false;
            ScaffoldMessenger.of(
              tester.element(find.byType(StoryIllustration).first),
            ).clearSnackBars();
            await tester.pumpAndSettle();
          }
          await tester.tapAt(tester.getCenter(right));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          await photo('opening');
          await tester.pumpAndSettle();
          expect(snapshot().phase, StoryPhase.success);
          expect(engine().energy, 1);
          expect(engine().paused, isTrue);
          // Enter the chapter's real tracing scene with the same repository.
          await StoryRepository(store).save(_scene(chapter, 5, trace: true));
          c.invalidate(storyProvider);
          await tester.pumpAndSettle();
          expect(find.byType(TraceCanvas), findsOneWidget);
          final m = c.read(storyProvider.notifier).machine;
          final item = learningItems.firstWhere(
            (i) => i.id == m.scene(snapshot()).traceId,
          );
          Future<void> draw(int i, {bool cancel = false}) async {
            final paint = find
                .descendant(
                  of: find.byType(TraceCanvas),
                  matching: find.byType(CustomPaint),
                )
                .first;
            final rect = tester.getRect(paint);
            expect(rect.shortestSide, greaterThanOrEqualTo(180));
            Offset at(TracePoint p) =>
                rect.topLeft + Offset(p.x * rect.width, p.y * rect.height);
            final samples = item.strokes[i].samples(80);
            final pointer = await tester.startGesture(at(samples.first));
            for (final p in samples.skip(1)) {
              await pointer.moveTo(at(p));
            }
            if (cancel) {
              await pointer.cancel();
            } else {
              await pointer.up();
            }
            await tester.pumpAndSettle();
          }

          await photo('trace');
          final paint = find
              .descendant(
                of: find.byType(TraceCanvas),
                matching: find.byType(CustomPaint),
              )
              .first;
          final rect = tester.getRect(paint);
          final scribble = await tester.startGesture(
            rect.topLeft + Offset(rect.width * .9, rect.height * .1),
          );
          await scribble.moveTo(
            rect.topLeft + Offset(rect.width * .1, rect.height * .9),
          );
          await scribble.moveTo(
            rect.topLeft + Offset(rect.width * .9, rect.height * .9),
          );
          await scribble.up();
          await tester.pumpAndSettle();
          expect(snapshot().strokes, isEmpty);
          expect(engine().energy, 0);
          await draw(0, cancel: true);
          expect(snapshot().strokes, isEmpty);
          expect(engine().energy, 0);
          if (label == 'tablet') {
            store.reject = true;
            await draw(0);
            expect(snapshot().strokes, isEmpty);
            expect(engine().energy, 0);
            store.reject = false;
            ScaffoldMessenger.of(
              tester.element(find.byType(StoryIllustration).first),
            ).clearSnackBars();
            await tester.pumpAndSettle();
          }
          await draw(0);
          expect(snapshot().strokes.length, 1);
          expect(engine().energy, closeTo(1 / item.strokes.length, .0001));
          await photo('partial');
          c.invalidate(storyProvider);
          await tester.pumpAndSettle();
          expect(snapshot().strokes.length, 1);
          expect(engine().elapsed, 1.6);
          if (label == 'tablet') {
            tester.view.physicalSize = const Size(800, 1280);
            await tester.pumpAndSettle();
            expect(snapshot().strokes.length, 1);
            expect(engine().energy, closeTo(1 / item.strokes.length, .0001));
            expect(engine().elapsed, 1.6);
            tester.view.physicalSize = size;
            await tester.pumpAndSettle();
          }
          for (var i = 1; i < item.strokes.length; i++) {
            await draw(i);
          }
          expect(snapshot().phase, StoryPhase.success);
          expect(
            find.byType(TraceCanvas),
            findsOneWidget,
            reason: 'The drawing and story stay together after success',
          );
          expect(engine().energy, 1);
          expect(engine().paused, isTrue);
          await photo('complete');
          c.invalidate(storyProvider);
          await tester.pumpAndSettle();
          expect(snapshot().phase, StoryPhase.success);
          expect(engine().elapsed, 1.6);
          final next = find.text('다음 이야기');
          await tester.ensureVisible(next);
          await tester.pumpAndSettle();
          final previousScene = snapshot().scene;
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(snapshot().scene, previousScene + 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          c.dispose();
        },
      );
    }
  }
}
