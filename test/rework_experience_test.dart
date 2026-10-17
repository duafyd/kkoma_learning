import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/audio/sound_effects.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/core/widgets/success_feedback.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/learning/data/learning_repository.dart';
import 'package:flutter_application_1/features/learning/presentation/learning_vm.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/chapter_direction.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/domain/story_quest.dart';
import 'package:flutter_application_1/features/story/presentation/story_quest_stage.dart';
import 'package:flutter_application_1/features/story/presentation/story_illustration.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';

class _FailingStore extends MemoryStore {
  String? failKey;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key == failKey) throw const FileSystemException('full');
    await super.write(key, value);
  }
}

StorySnapshot _ready(int chapter, int level) {
  final pages = storyEpisodes[chapter - 1].forLevel(level);
  return StoryMachine().restore(
    StorySnapshot(
      episode: chapter - 1,
      scene: pages.length - 1,
      level: level,
      flags: const {'companion': '토토'},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('REWORK_CAPTURE');
  final sounds = <MethodCall>[];
  setUp(() {
    sounds.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SoundEffects.channel, (call) async {
          sounds.add(call);
          return call.method == 'play' ? true : null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SoundEffects.channel, null),
  );
  setUpAll(() async {
    if (capture) {
      await (FontLoader(
        'Jua',
      )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
      await (FontLoader('Roboto')..addFont(
            File('C:/Windows/Fonts/malgun.ttf')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
      await (FontLoader('MaterialIcons')..addFont(
            File(
              'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    }
  });
  test('twelve chapters define physical problems, ten causal pages and concrete destinations', () {
    expect(chapterDirections.length, 12);
    for (var i = 0; i < 12; i++) {
      final d = chapterDirections[i], e = storyEpisodes[i];
      expect(d.pages.length, 10);
      expect(d.pages.first, contains('조각'));
      expect(e.goal, d.goal);
      expect(e.scenes.last.text, contains('담아'));
      expect(e.scenes.map((s) => s.id).toSet().length, 10);
    }
  });
  for (var level = 2; level <= 5; level++) {
    test(
      'level $level earns each fragment only after the chapter tasks and restores all twelve slots',
      () async {
        final m = StoryMachine();
        expect(m.collectFragment(m.begin(level)).flags, isEmpty);
        final store = MemoryStore(), repo = StoryRepository(MemoryStore());
        for (var chapter = 1; chapter <= 12; chapter++) {
          var s = _ready(chapter, level);
          expect(m.quest(s).ready, isTrue);
          s = m.collectFragment(s);
          expect(m.quest(s).hasFragment, isTrue);
          expect(m.collectFragment(s).toJson(), s.toJson());
          expect(s.flags['companion'], '토토');
          await repo.save(s);
          expect(m.quest(m.restore((await repo.load())!)).hasFragment, isTrue);
          await store.write('story', s.toJson());
          final next = m.advance(s);
          expect(next.completed, contains(chapter));
        }
        final legacy = _ready(
          12,
          level,
        ).change({'completed': List.generate(12, (i) => i + 1)});
        expect(m.quest(legacy).collected.length, 12);
      },
    );
  }
  test('forgiving tracing accepts a finger offset, cropped finish and brief wobble while retaining deliberate motion', () {
    const path = StrokePath([TracePoint(.2, .5), TracePoint(.8, .5)]);
    final young = const TraceStrategy(AgeStrategy(3));
    expect(
      young
          .evaluate(
            path,
            path
                .samples(80)
                .take(66)
                .map((p) => TracePoint(p.x, p.y + .14))
                .toList(),
          )
          .accepted,
      isTrue,
    );
    final curve = tracePaths['C']!.single;
    final ink = curve
        .samples(80)
        .indexed
        .map(
          (v) =>
              TracePoint(v.$2.x + (v.$1 >= 20 && v.$1 <= 23 ? .10 : 0), v.$2.y),
        )
        .toList();
    expect(
      const TraceStrategy(AgeStrategy(5)).evaluate(curve, ink).accepted,
      isTrue,
    );
    expect(young.evaluate(path, [path.points.first]).accepted, isFalse);
    expect(
      young.evaluate(path, path.samples(80).take(10).toList()).accepted,
      isFalse,
    );
  });
  test('failed fragment write leaves saved and visible reward untouched; retry keeps identity', () async {
    final store = _FailingStore();
    await ProfileRepository(store)
        .save(const ParentSettings(level: 5, autoRead: false));
    await StoryRepository(store).save(_ready(1, 5));
    final c = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    await c.read(storyProvider.future);
    final before = await store.read('story');
    store.failKey = 'story';
    await expectLater(
      c.read(storyProvider.notifier).collectFragment(),
      throwsA(isA<FileSystemException>()),
    );
    expect(await store.read('story'), before);
    expect(
      c
          .read(storyProvider.notifier)
          .machine
          .quest(c.read(storyProvider).requireValue)
          .hasFragment,
      isFalse,
    );
    store.failKey = null;
    await c.read(storyProvider.notifier).collectFragment();
    expect(
      c.read(storyProvider).requireValue.flags[StoryQuest.flag(1)],
      'collected',
    );
  });
  for (final (label, size) in [
    ('phone', const Size(360, 780)),
    ('landscape', const Size(780, 360)),
    ('tablet', const Size(1280, 800)),
  ]) {
    testWidgets(
      'correct quiz has saved visual and one sound; restore is silent on $label',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = _FailingStore();
        await ProfileRepository(store)
            .save(const ParentSettings(autoRead: false, animations: true));
        await LearningRepository(store).save(
          'math',
          const LearningSession(level: 3, baseLevel: 3, quizId: 'count5'),
        );
        final c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(container: c, child: const KkomaApp()),
        );
        await tester.pumpAndSettle();
        c.read(routerProvider).go('/learn/math?mode=quiz');
        await tester.pumpAndSettle();
        final vm = c.read(learningProvider('math').notifier);
        store.failKey = 'session-math';
        await expectLater(
          vm.answer(vm.quiz.answer),
          throwsA(isA<FileSystemException>()),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SuccessFeedback), findsNothing);
        expect(sounds.where((c) => c.method == 'play'), isEmpty);
        store.failKey = null;
        await vm.answer(vm.quiz.answer);
        await tester.pumpAndSettle();
        expect(find.byType(SuccessFeedback), findsOneWidget);
        expect(sounds.where((c) => c.method == 'play').length, 1);
        await vm.answer(vm.quiz.answer);
        await tester.pumpAndSettle();
        expect(sounds.where((c) => c.method == 'play').length, 1);
        c.read(routerProvider).go('/');
        await tester.pumpAndSettle();
        c.read(routerProvider).go('/learn/math?mode=quiz');
        await tester.pumpAndSettle();
        expect(find.byType(SuccessFeedback), findsOneWidget);
        expect(sounds.where((c) => c.method == 'play').length, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      },
    );
    testWidgets(
      'visible Flame fragment moves into a persistent book without blocking story controls on $label',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = MemoryStore();
        await ProfileRepository(store).save(
          const ParentSettings(level: 5, autoRead: false, animations: true),
        );
        await StoryRepository(store).save(_ready(1, 5));
        final c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('rework-capture'),
            child: UncontrolledProviderScope(
              container: c,
              child: const KkomaApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        c.read(routerProvider).go('/story');
        await tester.pumpAndSettle();
        if (capture) {
          await tester.runAsync(
            () => precacheImage(
              AssetImage(StoryIllustration.assetFor('ep1-map')),
              tester.element(find.byType(StoryIllustration).first),
            ),
          );
          await tester.pumpAndSettle();
        }
        Future<void> save(String name) async {
          if (!capture) return;
          final illustration = tester.widget<StoryIllustration>(
            find.byType(StoryIllustration).first,
          );
          await tester.runAsync(
            () => precacheImage(
              AssetImage(StoryIllustration.assetFor(illustration.background)),
              tester.element(find.byType(StoryIllustration).first),
            ),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final image = await tester
                .renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('rework-capture')),
                )
                .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File('docs/screenshots/rework-$name-$label.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        expect(find.byType(StoryQuestStage), findsOneWidget);
        await save('ready');
        final target = find.byKey(const ValueKey('collect-story-fragment'));
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(
          c.read(storyProvider).requireValue.flags[StoryQuest.flag(1)],
          'collected',
        );
        expect(
          find.byKey(const ValueKey('collect-story-fragment')),
          findsNothing,
        );
        expect(
          sounds
              .where(
                (c) =>
                    c.method == 'play' &&
                    (c.arguments as Map)['sound'] == 'sparkle',
              )
              .length,
          1,
        );
        await save('collected');
        if (capture) {
          await tester.ensureVisible(
            find.byKey(const ValueKey('fragment-book')),
          );
          await tester.pumpAndSettle();
          await save('book');
          for (final (name, state) in [
            ('begin', StoryMachine().begin(5)),
            (
              'finale',
              _ready(12, 5).change({
                'phase': 'finished',
                'completed': List.generate(12, (i) => i + 1),
              }),
            ),
          ]) {
            await StoryRepository(store).save(state);
            c.invalidate(storyProvider);
            await c.read(storyProvider.future);
            await tester.pumpAndSettle();
            await save(name);
          }
          for (var chapter = 2; chapter <= 12; chapter++) {
            final state = StorySnapshot(
              episode: chapter - 1,
              level: 5,
              completed: List.generate(chapter - 1, (i) => i + 1),
            );
            await StoryRepository(store).save(state);
            c.invalidate(storyProvider);
            await c.read(storyProvider.future);
            await tester.pumpAndSettle();
            await save('chapter-$chapter');
          }
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      },
    );
  }
  testWidgets(
    'Flame motion is finite and pause/reduced motion preserve committed slots',
    (tester) async {
      const before = StoryQuest(
        chapter: 1,
        done: 1,
        total: 1,
        collected: {},
        ready: true,
      );
      const after = StoryQuest(
        chapter: 1,
        done: 1,
        total: 1,
        collected: {1},
        ready: true,
      );
      final game = StoryQuestGame(before);
      game.synchronize(after, animate: true, active: true);
      expect(game.remaining, greaterThan(0));
      game.update(2);
      expect(game.remaining, 0);
      game.synchronize(before, animate: false, active: true);
      expect(game.remaining, 0);
      game.synchronize(after, animate: true, active: false);
      expect(game.remaining, 0);
      expect(game.quest.collected, {1});
    },
  );
}
