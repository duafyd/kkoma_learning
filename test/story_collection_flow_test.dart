import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/audio/audio_service.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/progress/presentation/fragment_collection.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/scene_play.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/domain/story_quest.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';

class _Voice extends AudioService {
  final spoken = <String>[];
  @override
  Future<PlaybackResult> speak(
    String text,
    ParentSettings settings, {
    String language = 'ko-KR',
    String? recordingId,
  }) async {
    spoken.add(text);
    return PlaybackResult.played;
  }

  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('COLLECTION_CAPTURE');
  setUpAll(() async {
    if (!capture) return;
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
    await (FontLoader('Roboto')..addFont(
          File('C:/Windows/Fonts/malgun.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
    await (FontLoader('MaterialIcons')..addFont(
          File(
            '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });
  for (var level = 2; level <= 5; level++) {
    for (var route = 0; route < 3; route++) {
      for (var room = 0; room < 2; room++) {
        for (final mode in ['normal', 'easier', 'help']) {
          test(
            'whole season level $level route $route room $room $mode survives every save',
            () async {
              final machine = StoryMachine();
              final repository = StoryRepository(MemoryStore());
              var s = machine.begin(level), steps = 0;
              final chosen = <String, String>{};
              while (s.phase != StoryPhase.finished && steps++ < 500) {
                final q = machine.quest(s);
                if (!q.ready) {
                  expect(machine.collectFragment(s).toJson(), s.toJson());
                } else if (room == 0) {
                  s = machine.collectFragment(s);
                  expect(machine.quest(s).hasFragment, isTrue);
                  expect(machine.collectFragment(s).toJson(), s.toJson());
                }
                switch (s.phase) {
                  case StoryPhase.choice:
                    final scene = machine.scene(s);
                    final index = scene.flag == 'route'
                        ? route
                        : scene.flag == 'room'
                        ? room
                        : 0;
                    if (scene.flag != null) {
                      chosen[scene.flag!] = scene.choices[index];
                    }
                    s = machine.choose(s, index);
                  case StoryPhase.quiz:
                  case StoryPhase.tracing:
                    if (mode == 'easier') {
                      s = machine.easier(s);
                      s = machine.answer(s, machine.quiz(s).answer);
                    } else if (mode == 'help' && level > 2) {
                      if (s.phase == StoryPhase.quiz) {
                        final art = machine.quiz(s).artwork;
                        if (!machine.canAnswer(s) && art != null) {
                          for (var i = 0; i < art.objects.length; i++) {
                            s = machine.placeObject(s, i, i);
                          }
                        }
                        final quiz = machine.quiz(s);
                        final wrong = List.generate(
                          quiz.options.length,
                          (i) => i,
                        ).firstWhere((i) => !quiz.accepts(i));
                        s = machine.answer(s, wrong);
                      } else {
                        s = machine.trace(s, []);
                      }
                      expect(
                        machine
                            .assist(
                              s,
                              const ParentSettings(help: false, helpAfter: 1),
                            )
                            .phase,
                        s.phase,
                      );
                      s = machine.assist(s, const ParentSettings(helpAfter: 1));
                      expect(s.assisted, isTrue);
                    } else if (s.phase == StoryPhase.quiz) {
                      final art = machine.quiz(s).artwork;
                      if (!machine.canAnswer(s) && art != null) {
                        for (var i = 0; i < art.objects.length; i++) {
                          s = machine.placeObject(s, i, i);
                        }
                      }
                      s = machine.answer(s, machine.quiz(s).answer);
                    } else {
                      final item = learningItems.firstWhere(
                        (i) => i.id == machine.scene(s).traceId,
                      );
                      s = machine.trace(
                        s,
                        item.strokes[s.strokes.length].samples(80),
                      );
                    }
                  case StoryPhase.drawing:
                    s = machine.drawingComplete(s);
                  default:
                    s = machine.advance(s);
                }
                await repository.save(s);
                final restored = machine.restore((await repository.load())!);
                expect(
                  restored.toJson(),
                  s.toJson(),
                  reason: 'transition $steps',
                );
                s = restored;
                for (final e in chosen.entries) {
                  expect(s.flags[e.key], e.value);
                }
              }
              expect(s.phase, StoryPhase.finished);
              expect(s.completed, List.generate(12, (i) => i + 1));
              expect(StoryQuest.collectedFrom(s), Set.of(s.completed));
              for (var chapter = 1; chapter <= 12; chapter++) {
                expect(s.flags[StoryQuest.flag(chapter)], 'collected');
              }
              expect(machine.text(s), contains('열두 조각'));
            },
          );
        }
      }
    }
  }
  test(
    'legacy completion and current flags share a deduplicated twelve-slot book',
    () {
      final s = StorySnapshot(
        completed: [1, 1, 3, 0, 13],
        flags: {
          StoryQuest.flag(1): 'collected',
          StoryQuest.flag(2): 'collected',
          StoryQuest.flag(4): 'pending',
          StoryQuest.flag(13): 'collected',
        },
      );
      expect(StoryQuest.collectedFrom(s), {1, 2, 3});
    },
  );
  test('optional opening props never award the locked chapter fragment', () {
    final m = StoryMachine();
    for (var i = 0; i < 12; i++) {
      var s = m.restore(StorySnapshot(episode: i, level: 5));
      final play = ScenePlay.forSnapshot(s)!;
      for (var prop = 0; prop < play.count(s.level); prop++) {
        s = m.discoverSceneProp(s, prop);
      }
      expect(m.text(s), play.response);
      expect(play.response, contains('별조각'));
      expect(m.quest(s).ready, isFalse);
      expect(StoryQuest.collectedFrom(m.collectFragment(s)), isEmpty);
    }
  });
  for (final size in [
    const Size(360, 780),
    const Size(780, 360),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'collected but unfinished chapter matches read-only map at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = MemoryStore();
        await ProfileRepository(store).save(
          const ParentSettings(
            level: 5,
            autoRead: false,
            animations: false,
            voiceVolume: 0,
            effectsVolume: 0,
          ),
        );
        await StoryRepository(store).save(
          StoryMachine().restore(
            StorySnapshot(
              scene: 9,
              level: 5,
              flags: {StoryQuest.flag(1): 'collected'},
            ),
          ),
        );
        final c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const RepaintBoundary(
              key: ValueKey('collection-screen'),
              child: KkomaApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final before = await store.read('story');
        c.read(routerProvider).go('/gallery');
        await tester.pumpAndSettle();
        expect(find.text('별조각 1 / 12'), findsOneWidget);
        expect(
          tester
              .widget<FragmentCollection>(find.byType(FragmentCollection))
              .collected,
          {1},
        );
        if (capture) {
          await tester.runAsync(() async {
            final image = await tester
                .renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('collection-screen')),
                )
                .toImage();
            try {
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                'docs/screenshots/collection-${size.width.toInt()}x${size.height.toInt()}.png',
              ).writeAsBytes(data!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
        final slot = tester.widget<Semantics>(
          find.byKey(const ValueKey('fragment-slot-1')),
        );
        expect(slot.properties.label, '1번째 별조각 담았어요');
        expect(slot.properties.button, isNot(true));
        final chapter = find.byKey(const ValueKey('map-chapter-1'));
        await tester.ensureVisible(chapter);
        await tester.pumpAndSettle();
        await tester.tap(chapter);
        await tester.pumpAndSettle();
        expect(find.text('함께 모은 책등 조각 1'), findsOneWidget);
        await tester.tap(find.text('지도 보기'));
        await tester.pumpAndSettle();
        expect(await store.read('story'), before);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        await tester.pumpAndSettle();
      },
    );
  }
  testWidgets('collecting on the same page updates automatic narration once', (
    tester,
  ) async {
    final store = MemoryStore(), voice = _Voice();
    await ProfileRepository(store).save(
      const ParentSettings(
        level: 5,
        autoRead: true,
        animations: false,
        effectsVolume: 0,
      ),
    );
    await StoryRepository(store)
        .save(StoryMachine().restore(const StorySnapshot(scene: 9, level: 5)));
    final c = ProviderContainer(
      overrides: [
        storeProvider.overrideWithValue(store),
        audioProvider.overrideWithValue(voice),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const KkomaApp()),
    );
    await tester.pumpAndSettle();
    c.read(routerProvider).go('/story');
    await tester.pumpAndSettle();
    expect(voice.spoken, hasLength(1));
    final vm = c.read(storyProvider.notifier);
    await vm.collectFragment();
    await tester.pumpAndSettle();
    expect(voice.spoken, hasLength(2));
    expect(voice.spoken.last, contains('1/12'));
    await vm.collectFragment();
    await tester.pumpAndSettle();
    expect(voice.spoken, hasLength(2));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pumpAndSettle();
  });
}
