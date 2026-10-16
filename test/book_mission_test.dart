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
import 'package:flutter_application_1/features/drawing/domain/drawing.dart';
import 'package:flutter_application_1/features/drawing/presentation/drawing_vm.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_art.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/book_mission_stage.dart';
import 'package:flutter_application_1/features/story/presentation/story_illustration.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_canvas.dart';

class _Store extends MemoryStore {
  bool reject = false;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (reject && key == 'story') throw StateError('full');
    await super.write(key, value);
  }
}

StorySnapshot at(
  int chapter, {
  String name = 'quiz',
  int level = 5,
  Map<String, String> flags = const {},
}) {
  final scenes = StoryMachine().episodes[chapter - 1].forLevel(level);
  final i = scenes.indexWhere((s) => s.id == 'ep$chapter-$name');
  return StorySnapshot(
    episode: chapter - 1,
    scene: i,
    level: level,
    phase: scenes[i].interaction,
    flags: flags,
  );
}

class _Gallery extends GalleryVM {
  final List<Artwork> artworks;
  _Gallery(this.artworks);
  @override
  Future<List<Artwork>> build() async => artworks;
  void replace(List<Artwork> next) => state = AsyncData(next);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('BOOK_CAPTURE');
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

  test('all later chapter quizzes, route/room variants, hints and real guides project saved state', () {
    final m = StoryMachine();
    final scenes = <String>{};
    for (var chapter = 7; chapter <= 12; chapter++) {
      expect(m.bookMission(at(chapter, level: 2)), isNull);
      for (final level in [3, 4, 5]) {
        final path = m.episodes[chapter - 1].forLevel(level);
        for (var i = 0; i < path.length; i++) {
          for (final variation in ['한글 길', '영어 길', '숫자 길', '꽃 방', '별 방']) {
            var s = StorySnapshot(
              episode: chapter - 1,
              scene: i,
              level: level,
              phase: path[i].interaction,
              flags: {'route': variation, 'room': variation},
            );
            final plan = m.bookMission(s);
            if (plan == null) continue;
            scenes.add(path[i].id);
            expect(m.bookMission(m.easier(s)), isNull);
            if (plan.tracing) {
              final item = learningItems.firstWhere(
                (v) => v.id == path[i].traceId,
              );
              expect(plan.total, item.strokes.length);
              for (var j = 0; j < item.strokes.length; j++) {
                s = m.trace(s, item.strokes[j].samples(80));
                expect(
                  m.bookMission(s)!.energy,
                  closeTo((j + 1) / item.strokes.length, .0001),
                );
              }
            } else {
              expect(plan.quiz!.id, m.quiz(s).id);
              s = m.hint(m.hint(s));
              expect(m.bookMission(s)!.hints, 2);
              final wrong = (m.quiz(s).answer + 1) % m.quiz(s).options.length;
              expect(m.bookMission(m.answer(s, wrong))!.energy, 0);
              s = m.answer(s, m.quiz(s).answer);
            }
            expect(s.phase, StoryPhase.success);
            expect(
              m
                  .bookMission(m.restore(StorySnapshot.fromJson(s.toJson())))!
                  .energy,
              1,
            );
          }
        }
      }
    }
    expect(scenes.length, 22); // 17 quiz scenes and five tracing scenes.
  });

  test('scene answer/count targets are separate, reachable and at least 56 logical pixels', () {
    for (final size in [
      const Size(312, 300),
      const Size(650, 600),
      const Size(440, 250),
    ]) {
      for (final count in [2, 3]) {
        final targets = List.generate(
          count,
          (i) => BookMissionGame.choiceRect(size, count, i),
        );
        for (var i = 0; i < count; i++) {
          expect(targets[i].shortestSide, greaterThanOrEqualTo(56));
          expect((Offset.zero & size).contains(targets[i].topLeft), isTrue);
          expect((Offset.zero & size).contains(targets[i].bottomRight), isTrue);
          for (var j = i + 1; j < count; j++) {
            expect(targets[i].overlaps(targets[j]), isFalse);
          }
          final object = BookMissionGame.objectRect(size, count, i);
          // Actual count stages have a minimum height of 300.
          if (size.height >= 300) {
            expect(object.shortestSide, greaterThanOrEqualTo(56));
          }
          expect(targets.any((r) => r.overlaps(object)), isFalse);
        }
      }
    }
  });

  for (final reduced in [false, true]) {
    testWidgets(
      'pending double taps, background completion and idle stop reduced=$reduced',
      (tester) async {
        final m = StoryMachine();
        final s = at(8);
        var plan = m.bookMission(s)!;
        final gate = Completer<void>();
        var requests = 0;
        var animate = true, active = true;
        Widget stage() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: BookMissionStage(
              mission: plan,
              animate: animate,
              active: active,
              onAnswer: (_) async {
                requests++;
                await gate.future;
              },
            ),
          ),
        );
        BookMissionGame game() => tester
            .widget<GameWidget<BookMissionGame>>(
              find.byType(GameWidget<BookMissionGame>),
            )
            .game!;
        await tester.pumpWidget(stage());
        await tester.pumpAndSettle();
        final token = find.byKey(const ValueKey('book-choice-1'));
        await tester.tapAt(tester.getCenter(token));
        await tester.pump();
        await tester.tapAt(tester.getCenter(token));
        await tester.pump();
        expect(requests, 1);
        expect(game().energy, 0);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        plan = m.bookMission(m.answer(s, 1))!;
        await tester.pumpWidget(stage());
        gate.complete();
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(game().energy, 1);
        expect(game().elapsed, BookMissionGame.duration);
        expect(game().paused, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
        // Partial saved ink has a finite animation; stopping motion settles it.
        final trace = at(12, name: 'trace');
        plan = m.bookMission(trace)!;
        await tester.pumpWidget(stage());
        await tester.pumpAndSettle();
        final item = learningItems.firstWhere(
          (v) => v.id == m.scene(trace).traceId,
        );
        plan = m.bookMission(m.trace(trace, item.strokes.first.samples(80)))!;
        await tester.pumpWidget(stage());
        await tester.pump(const Duration(milliseconds: 300));
        if (reduced) {
          expect(game().energy, .5);
        } else {
          expect(game().energy, inExclusiveRange(0, .5));
        }
        animate = false;
        await tester.pumpWidget(stage());
        await tester.pumpAndSettle();
        expect(game().energy, .5);
        expect(game().paused, isTrue);
        active = false;
        await tester.pumpWidget(stage());
        expect(game().paused, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
        active = true;
        animate = true;
        await tester.pumpWidget(stage());
        await tester.pumpAndSettle();
        expect(game().elapsed, BookMissionGame.duration);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (var chapter = 7; chapter <= 12; chapter++) {
    for (final (label, size) in [
      ('tablet', const Size(1280, 800)),
      ('phone', const Size(360, 780)),
      ('landscape', const Size(780, 360)),
    ]) {
      testWidgets(
        'chapter $chapter scene touch, count, saved ink and restore at $label',
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
          final flags = {
            'route': label == 'tablet'
                ? '숫자 길'
                : label == 'phone'
                ? '영어 길'
                : '한글 길',
            'room': label == 'phone' ? '꽃 방' : '별 방',
          };
          // Chapter eleven's main five-star placement remains on its own engine.
          var s = at(
            chapter,
            name: chapter == 11 ? 'review' : 'quiz',
            flags: flags,
          );
          await StoryRepository(store).save(s);
          final c = ProviderContainer(
            overrides: [storeProvider.overrideWithValue(store)],
          );
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: c,
              child: RepaintBoundary(
                key: const ValueKey('book-screen'),
                child: const KkomaApp(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          c.read(routerProvider).go('/story');
          await tester.pumpAndSettle();
          if (capture) {
            await tester.runAsync(() async {
              final context = tester.element(find.byType(MaterialApp));
              for (final asset in {
                ...storyArtAssets.values.where(
                  (path) => path.contains('ep$chapter-'),
                ),
                storyCastAsset,
                storySearchCastAsset,
              }) {
                await precacheImage(
                  ResizeImage(
                    AssetImage(asset),
                    width: asset.contains('cast-') ? 1024 : 1536,
                  ),
                  context,
                );
              }
            });
            await tester.pumpAndSettle();
          }
          Future<void> photo(String state) async {
            if (!capture) return;
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('book-screen')),
              );
              final image = await boundary.toImage();
              try {
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File('docs/screenshots/book-$chapter-$state-$label.png')
                    .writeAsBytes(bytes!.buffer.asUint8List());
              } finally {
                image.dispose();
              }
            });
          }

          BookMissionGame game() => tester
              .widget<GameWidget<BookMissionGame>>(
                find.byType(GameWidget<BookMissionGame>),
              )
              .game!;
          StorySnapshot saved() => c.read(storyProvider).requireValue;
          final m = c.read(storyProvider.notifier).machine;
          final quiz = m.quiz(s);
          await photo('choices');
          final wrong = find.byKey(
            ValueKey('book-choice-${(quiz.answer + 1) % quiz.options.length}'),
          );
          await tester.ensureVisible(wrong);
          await tester.pumpAndSettle();
          await tester.tapAt(tester.getCenter(wrong));
          await tester.pumpAndSettle();
          expect(saved().phase, StoryPhase.quiz);
          expect(game().energy, 0);
          if (quiz.artwork!.countOnTap) {
            for (var i = 0; i < quiz.artwork!.objects.length; i++) {
              final object = find.byKey(ValueKey('book-object-$i'));
              await tester.tapAt(tester.getCenter(object));
              await tester.pumpAndSettle();
              await tester.tapAt(tester.getCenter(object));
              await tester.pumpAndSettle();
              expect(saved().observedObjects.length, i + 1);
            }
            c.invalidate(storyProvider);
            await tester.pumpAndSettle();
            expect(
              saved().observedObjects.length,
              quiz.artwork!.objects.length,
            );
          }
          final correct = find.byKey(ValueKey('book-choice-${quiz.answer}'));
          if (label == 'tablet') {
            store.reject = true;
            await tester.tapAt(tester.getCenter(correct));
            await tester.pumpAndSettle();
            expect(saved().phase, StoryPhase.quiz);
            expect(game().energy, 0);
            store.reject = false;
            ScaffoldMessenger.of(
              tester.element(find.byType(StoryIllustration).first),
            ).clearSnackBars();
            await tester.pumpAndSettle();
          }
          await tester.tapAt(tester.getCenter(correct));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 550));
          await photo('reaction');
          await tester.pumpAndSettle();
          expect(saved().phase, StoryPhase.success);
          expect(game().energy, 1);
          expect(game().paused, isTrue);
          await photo('result');
          c.invalidate(storyProvider);
          await tester.pumpAndSettle();
          expect(game().elapsed, BookMissionGame.duration);
          if (chapter != 7) {
            await StoryRepository(store)
                .save(at(chapter, name: 'trace', flags: flags));
            c.invalidate(storyProvider);
            await tester.pumpAndSettle();
            final item = learningItems.firstWhere(
              (v) => v.id == m.scene(saved()).traceId,
            );
            Future<void> draw(int i, {bool cancel = false}) async {
              final paint = find
                  .descendant(
                    of: find.byType(TraceCanvas),
                    matching: find.byType(CustomPaint),
                  )
                  .first;
              final rect = tester.getRect(paint);
              final samples = item.strokes[i].samples(80);
              Offset point(TracePoint p) =>
                  rect.topLeft + Offset(p.x * rect.width, p.y * rect.height);
              final finger = await tester.startGesture(point(samples.first));
              for (final p in samples.skip(1)) {
                await finger.moveTo(point(p));
              }
              if (cancel) {
                await finger.cancel();
              } else {
                await finger.up();
              }
              await tester.pumpAndSettle();
            }

            await photo('trace');
            await draw(0, cancel: true);
            expect(saved().strokes, isEmpty);
            expect(game().energy, 0);
            await draw(0);
            expect(saved().strokes.length, 1);
            c.invalidate(storyProvider);
            await tester.pumpAndSettle();
            expect(saved().strokes.length, 1);
            expect(game().elapsed, BookMissionGame.duration);
            if (label == 'tablet') {
              tester.view.physicalSize = const Size(800, 1280);
              await tester.pumpAndSettle();
              expect(saved().strokes.length, 1);
              expect(game().elapsed, BookMissionGame.duration);
              tester.view.physicalSize = size;
              await tester.pumpAndSettle();
            }
            for (var i = 1; i < item.strokes.length; i++) {
              await draw(i);
            }
            expect(saved().phase, StoryPhase.success);
            expect(find.byType(TraceCanvas), findsOneWidget);
            expect(game().energy, 1);
            await photo('written');
            final next = find.text('다음 이야기');
            await tester.ensureVisible(next);
            await tester.pumpAndSettle();
            final previous = saved().scene;
            await tester.tap(next);
            await tester.pumpAndSettle();
            expect(saved().scene, previous + 1);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          c.dispose();
        },
      );
    }
  }

  testWidgets(
    'the garden shows the submitted map by ID, not a newer drawing; deletion removes it',
    (tester) async {
      final store = MemoryStore();
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
      final s = at(
        7,
        name: 'trace',
        flags: {'gardenArtwork': 'mine'},
      ).change({'phase': 'success'});
      await StoryRepository(store).save(s);
      final mine = Artwork(
        id: 'mine',
        path: 'unused',
        created: DateTime(2026),
        document: const DrawingDocument(
          lines: [
            DrawingLine([
              TracePoint(.2, .2),
              TracePoint(.8, .7),
            ], color: 0xffdc796d),
          ],
        ),
      );
      var artworks = [
        Artwork(
          id: 'newer',
          path: 'unused',
          created: DateTime(2027),
          document: const DrawingDocument(),
        ),
        mine,
      ];
      final c = ProviderContainer(
        overrides: [
          storeProvider.overrideWithValue(store),
          galleryProvider.overrideWith(() => _Gallery(artworks)),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const KkomaApp()),
      );
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/story');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('saved-garden-map')), findsOneWidget);
      expect(c.read(storyGardenMapProvider).requireValue!.id, 'mine');
      c.invalidate(storyProvider);
      await tester.pumpAndSettle();
      expect(
        c
            .read(storyGardenMapProvider)
            .requireValue!
            .document
            .lines
            .single
            .color,
        0xffdc796d,
      );
      artworks = [artworks.first];
      (c.read(galleryProvider.notifier) as _Gallery).replace(artworks);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('saved-garden-map')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
  );
}
