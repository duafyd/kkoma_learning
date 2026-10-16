import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_page.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_canvas.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_vm.dart';
import 'package:flutter_application_1/features/tracing/data/trace_repository.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/learning/data/learning_repository.dart';
import 'package:flutter_application_1/features/learning/presentation/learning_vm.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android story IDs override stale positions and survive DB reopen',
    (tester) async {
      final fileName =
          'kkoma-story-id-${DateTime.now().microsecondsSinceEpoch}.db';
      final store = await SqliteStore.open(fileName: fileName);
      await ProfileRepository(store).save(
        const ParentSettings(
          level: 5,
          autoRead: false,
          animations: false,
          voiceVolume: 0,
          effectsVolume: 0,
        ),
      );
      final legacy =
          StorySnapshot(
              episode: 1,
              scene: storyEpisodes[1]
                  .forLevel(5)
                  .indexWhere((s) => s.id == 'ep2-trace'),
              level: 5,
              phase: StoryPhase.tracing,
              hints: 2,
              flags: const {'companion': '토토'},
              strokes: [tracePaths['ㅏ']!.first.samples(80)],
            ).toJson()
            ..remove('episodeId')
            ..remove('sceneId');
      await store.write('story', legacy);
      var c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      final original = await c.read(storyProvider.future);
      expect(original.sceneId, 'ep2-trace');
      expect(await store.read('story'), legacy);
      await c.read(storyProvider.notifier).easier();
      final saved = (await store.read('story'))!;
      expect(saved['sceneId'], 'ep2-trace');
      expect(saved['episodeId'], 2);
      c.dispose();
      final stale = {...saved, 'episode': 999, 'scene': -1};
      await store.write('story', stale);
      await store.db.close();
      final reopened = await SqliteStore.open(fileName: fileName);
      c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(reopened)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const KkomaApp()),
      );
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/story');
      await tester.pumpAndSettle();
      expect(find.byType(StoryPage), findsOneWidget);
      var restored = c.read(storyProvider).requireValue;
      expect(restored.episode, 1);
      expect(restored.sceneId, 'ep2-trace');
      expect(restored.supportSceneId, 'ep2-trace');
      expect(restored.flags['companion'], '토토');
      expect(await reopened.read('story'), stale);
      final vm = c.read(storyProvider.notifier);
      await vm.hint();
      await vm.answer(
        vm.machine.quiz(c.read(storyProvider).requireValue).answer,
      );
      restored = c.read(storyProvider).requireValue;
      expect(restored.phase, StoryPhase.success);
      expect(restored.hints, 1);
      final committed = (await reopened.read('story'))!;
      expect(committed['episode'], 1);
      expect(committed['sceneId'], 'ep2-trace');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await reopened.db.close();
      final last = await SqliteStore.open(fileName: fileName);
      expect((await StoryRepository(last).load())!.toJson(), restored.toJson());
      await last.db.close();
    },
  );
  testWidgets(
    'Android batch reads and home learning resume survive DB reopen',
    (tester) async {
      final fileName =
          'kkoma-resume-${DateTime.now().microsecondsSinceEpoch}.db';
      final store = await SqliteStore.open(fileName: fileName);
      await ProfileRepository(store).save(
        const ParentSettings(
          autoRead: false,
          animations: false,
          autoAdvanceLearning: false,
          voiceVolume: 0,
          effectsVolume: 0,
        ),
      );
      await TraceRepository(store).save(
        'h-ㅏ',
        TraceState(
          strokeIndex: 1,
          completed: [tracePaths['ㅏ']!.first.samples(80)],
        ),
      );
      await LearningRepository(store).save(
        'math',
        const LearningSession(
          level: 3,
          baseLevel: 3,
          quizId: 'count5',
          hint: 2,
        ),
      );
      expect(await store.readMany([]), isEmpty);
      final batch = await store.readMany([
        'session-math',
        for (var i = 0; i < 401; i++) 'missing-$i',
        'trace-h-ㅏ',
      ]);
      expect(batch.keys.toSet(), {'session-math', 'trace-h-ㅏ'});
      await store.db.close();
      final reopened = await SqliteStore.open(fileName: fileName);
      final c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(reopened)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const KkomaApp()),
      );
      await tester.pumpAndSettle();
      Future<void> open(String kind) async {
        final card = find.byKey(ValueKey('resume-$kind'));
        await tester.scrollUntilVisible(
          card,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();
      }

      await open('quiz');
      expect(find.text('별이 몇 개일까요?'), findsOneWidget);
      expect(c.read(learningProvider('math').notifier).quiz.id, 'count5');
      expect(c.read(learningProvider('math')).requireValue.hint, 2);
      c.read(routerProvider).go('/');
      await tester.pumpAndSettle();
      await open('tracing');
      expect(find.byType(TraceCanvas), findsOneWidget);
      expect(c.read(traceProvider('h-ㅏ')).requireValue.strokeIndex, 1);
      expect(await reopened.read('trace-h-ㅏ'), batch['trace-h-ㅏ']);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await reopened.db.close();
    },
  );
  testWidgets(
    'Android exploration accepts the second picture and persists success',
    (tester) async {
      final fileName =
          'kkoma-exploration-${DateTime.now().microsecondsSinceEpoch}.db';
      final store = await SqliteStore.open(fileName: fileName);
      await ProfileRepository(store).save(
        const ParentSettings(
          age: 2,
          level: 2,
          autoRead: false,
          animations: false,
          voiceVolume: 0,
          effectsVolume: 0,
        ),
      );
      final scenes = storyEpisodes.first.forLevel(2);
      await StoryRepository(store).save(
        StorySnapshot(
          level: 2,
          scene: scenes.indexWhere((s) => s.id == 'ep1-quiz'),
          phase: StoryPhase.quiz,
        ),
      );
      final container = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const KkomaApp(),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/story');
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        final hint = find.text('힌트');
        await tester.ensureVisible(hint);
        await tester.tap(hint);
        await tester.pumpAndSettle();
      }
      final second = find.byKey(const ValueKey('picture-answer-1'));
      await tester.ensureVisible(second);
      await tester.tap(second);
      await tester.pumpAndSettle();
      final saved = (await StoryRepository(store).load())!;
      expect(saved.phase, StoryPhase.success);
      expect(saved.hints, 2);
      expect(saved.attempts, 1);
      expect(saved.message, contains('예쁜 빛'));
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await store.db.close();
      final reopened = await SqliteStore.open(fileName: fileName);
      expect(
        (await StoryRepository(reopened).load())!.toJson(),
        saved.toJson(),
      );
      await reopened.db.close();
    },
  );
  testWidgets('Android SQLite, navigation and story resume', (tester) async {
    // An isolated database prevents this test from altering a child's real progress.
    final fileName =
        'kkoma-integration-${DateTime.now().microsecondsSinceEpoch}.db';
    final store = await SqliteStore.open(fileName: fileName);
    await ProfileRepository(store).save(
      const ParentSettings(
        age: 4,
        level: 3,
        autoRead: false,
        animations: false,
        voiceVolume: 0,
        effectsVolume: 0,
      ),
    );
    final c = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const KkomaApp()),
    );
    await tester.pumpAndSettle();
    final openStory = find.text('별빛 이야기 펼치기');
    await tester.ensureVisible(openStory);
    await tester.tap(openStory);
    await tester.pumpAndSettle();
    expect(find.byType(StoryPage), findsOneWidget);
    await tester.tap(find.text('다음 장면'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음 장면'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('토토'));
    await tester.pumpAndSettle();
    final snapshot = await StoryRepository(store).load();
    expect(snapshot!.flags['companion'], '토토');
    c.read(routerProvider).go('/trace/p-dot');
    await tester.pumpAndSettle();
    final canvas = find
        .descendant(
          of: find.byType(TraceCanvas),
          matching: find.byType(CustomPaint),
        )
        .first;
    await tester.tapAt(tester.getCenter(canvas));
    await tester.pumpAndSettle();
    expect(c.read(traceProvider('p-dot')).requireValue.done, isTrue);
    c.read(routerProvider).go('/parent');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('learning-overview')), findsNothing);
    final prompt = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? '')
        .singleWhere((s) => RegExp(r'^\d+ \+ \d+ = \?$').hasMatch(s));
    final numbers = RegExp(r'\d+')
        .allMatches(prompt)
        .map((m) => int.parse(m[0]!))
        .toList();
    await tester.enterText(
      find.byType(TextField),
      '${numbers[0] + numbers[1]}',
    );
    await tester.ensureVisible(find.text('설정 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정 열기'));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('auto-advance-learning'));
    await tester.scrollUntilVisible(
      toggle,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final control = find.descendant(of: toggle, matching: find.byType(Switch));
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
    expect(
      (await ProfileRepository(store).load()).autoAdvanceLearning,
      isFalse,
    );
    final overview = find.text('학습 내용 미리보기');
    await tester.scrollUntilVisible(
      overview,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(overview);
    await tester.pumpAndSettle();
    final group = find.byKey(const ValueKey('overview-한글'));
    await tester.scrollUntilVisible(
      group,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: group, matching: find.byType(ListTile)).first,
    );
    await tester.pumpAndSettle();
    final preview = find.byKey(const ValueKey('preview-h-ㅏ'));
    await tester.scrollUntilVisible(
      preview,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(find.byType(TraceCanvas), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(await store.read('trace-h-ㅏ'), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await store.db.close();
    final reopened = await SqliteStore.open(fileName: fileName);
    expect((await ProfileRepository(reopened).load()).age, 4);
    expect(
      (await ProfileRepository(reopened).load()).autoAdvanceLearning,
      isFalse,
    );
    expect((await reopened.read('trace-p-dot'))!['done'], isTrue);
    expect(
      (await StoryRepository(reopened).load())!.toJson(),
      snapshot.toJson(),
    );
    await reopened.db.close();
  });
}
