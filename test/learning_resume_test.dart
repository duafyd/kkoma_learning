import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/learning/data/learning_repository.dart';
import 'package:flutter_application_1/features/learning/domain/learning_models.dart';
import 'package:flutter_application_1/features/learning/presentation/learning_vm.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/progress/data/learning_resume_repository.dart';
import 'package:flutter_application_1/features/progress/data/progress_repository.dart';
import 'package:flutter_application_1/features/progress/domain/learning_resume.dart';
import 'package:flutter_application_1/features/tracing/data/trace_repository.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_canvas.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_vm.dart';

class _FailureStore extends MemoryStore {
  String? rejectKey;
  bool rejectReads = false;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key == rejectKey) throw StateError('fixture disk full');
    await super.write(key, value);
  }

  @override
  Future<Map<String, Map<String, dynamic>>> readMany(Iterable<String> keys) {
    if (rejectReads) throw StateError('fixture read error');
    return super.readMany(keys);
  }
}

TraceState partial(String symbol) => TraceState(
  strokeIndex: 1,
  completed: [tracePaths[symbol]!.first.samples(80)],
);
QuizDefinition quiz(String id) => QuizDefinition(
  id: id,
  prompt: id,
  visual: id,
  options: const ['a', 'b'],
  answer: 0,
  hint: 'hint',
);

Future<void> seed(MemoryStore store) async {
  await TraceRepository(store).save('h-ㅏ', partial('ㅏ'));
  await LearningRepository(store).save(
    'math',
    const LearningSession(level: 3, baseLevel: 3, quizId: 'count5', hint: 2),
  );
}

void main() {
  const capture = bool.fromEnvironment('RESUME_CAPTURE');
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
    'batch reads deduplicate keys, omit absent rows and detach returned values',
    () async {
      final store = MemoryStore();
      await store.write('a', {
        'nested': [1],
      });
      expect(await store.readMany([]), isEmpty);
      final result = await store.readMany(['a', 'a', 'missing']);
      expect(result.keys, ['a']);
      (result['a']!['nested'] as List).add(2);
      expect((await store.read('a'))!['nested'], [1]);
    },
  );

  test('restored committed ink determines done and prevents end-index submit crash', () async {
    final store = MemoryStore();
    final completed = TraceState(
      strokeIndex: 2,
      completed: [for (final path in tracePaths['ㅏ']!) path.samples(80)],
    );
    await store.write('trace-h-ㅏ', completed.toJson());
    final before = jsonEncode(await store.read('trace-h-ㅏ'));
    final c = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(traceProvider('h-ㅏ'), (_, _) {});
    addTearDown(sub.close);
    final restored = await c.read(traceProvider('h-ㅏ').future);
    expect(restored.done, isTrue);
    expect(restored.completed, hasLength(2));
    await c
        .read(traceProvider('h-ㅏ').notifier)
        .submit(tracePaths['ㅏ']!.last.samples(80), 3);
    expect(jsonEncode(await store.read('trace-h-ㅏ')), before);
    expect(await store.read('learning-progress'), isNull);
    final contradictory = partial('ㅏ').toJson()..['done'] = true;
    final stillPartial = TraceState.restore(contradictory, 2);
    expect(stillPartial.done, isFalse);
    expect(stillPartial.strokeIndex, 1);
  });

  test('malformed ink recovers safely and harmless out-of-canvas tails are filtered', () {
    for (final raw in [
      {'strokeIndex': -1},
      {'strokeIndex': 1},
      {'strokeIndex': 99, 'completed': []},
      {'strokeIndex': 'bad'},
      {
        'strokeIndex': 1,
        'completed': [
          [
            [.2],
          ],
        ],
      },
    ]) {
      expect(TraceState.restore(raw, 2).strokeIndex, 0);
    }
    final raw = partial('ㅏ').toJson();
    (raw['completed'][0] as List).add([1.1, .5]);
    final state = TraceState.restore(raw, 2);
    expect(state.strokeIndex, 1);
    expect(state.completed.first.every((p) => p.x <= 1), isTrue);
  });

  test('quiz identity survives catalog insertion and next index follows the same question', () {
    final list = [quiz('new'), quiz('a'), quiz('b')];
    const saved = LearningSession(
      level: 3,
      quizId: 'a',
      answered: true,
      hint: 2,
    );
    final restored = saved.restoredFor(list);
    expect(restored.index, 1);
    expect(restored.question(list).id, 'a');
    expect(restored.answered, isTrue);
    expect(restored.hint, 2);
    expect(
      LearningSession(level: 3, index: restored.index + 1).question(list).id,
      'b',
    );
    final removed = saved.restoredFor([quiz('new'), quiz('b')]);
    expect(removed.answered, isFalse);
    expect(removed.hint, 0);
    expect(removed.quizId, 'new');
    final legacy = const LearningSession(
      level: 3,
      index: 1,
      answered: true,
    ).restoredFor(list);
    expect(legacy.quizId, 'a');
    expect(legacy.answered, isTrue);
    final malformed = LearningSession.fromJson({
      'index': -2,
      'answered': true,
      'hint': 3,
    });
    expect(malformed.index, 0);
    expect(malformed.answered, isFalse);
    expect(malformed.hint, 0);
  });

  test(
    'saved hints bind quiz identity, timestamp and resume across containers',
    () async {
      final store = MemoryStore();
      final first = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      final sub = first.listen(learningProvider('math'), (_, _) {});
      await first.read(learningProvider('math').future);
      final vm = first.read(learningProvider('math').notifier);
      final id = vm.quiz.id;
      await vm.showHint();
      final raw = (await store.read('session-math'))!;
      expect(raw['quizId'], id);
      expect(DateTime.parse(raw['_updatedAt'] as String).isUtc, isTrue);
      sub.close();
      first.dispose();
      final second = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      addTearDown(second.dispose);
      final sub2 = second.listen(learningProvider('math'), (_, _) {});
      addTearDown(sub2.close);
      expect((await second.read(learningProvider('math').future)).hint, 1);
      expect(second.read(learningProvider('math').notifier).quiz.id, id);
    },
  );

  test(
    'failed primary write cannot advance the saved checkpoint or its timestamp',
    () async {
      final store = _FailureStore();
      await seed(store);
      final before = jsonEncode(store.documents);
      store.rejectKey = 'trace-h-ㅏ';
      await expectLater(
        TraceRepository(store).save('h-ㅏ', const TraceState()),
        throwsStateError,
      );
      expect(jsonEncode(store.documents), before);
      store.rejectKey = 'session-math';
      await expectLater(
        LearningRepository(store).save('math', const LearningSession(level: 5)),
        throwsStateError,
      );
      expect(jsonEncode(store.documents), before);
    },
  );

  test('resume uses existing eligible documents, is read-only and vanishes after reset', () async {
    final store = MemoryStore();
    await seed(store);
    await store.write('trace-h-ㅓ', {
      ...partial('ㅓ').toJson(),
      '_updatedAt': '2090-01-01T00:00:00Z',
    });
    final before = jsonEncode(store.documents);
    final repo = LearningResumeRepository(store);
    final targets = await repo.load(const ParentSettings(level: 3));
    expect(targets, hasLength(2));
    expect(targets.first.kind, LearningResumeKind.tracing);
    expect(targets.last.kind, LearningResumeKind.quiz);
    expect(Uri.parse(targets.first.location).pathSegments, ['trace', 'h-ㅓ']);
    expect(targets.last.location, '/learn/math?mode=quiz');
    expect(jsonEncode(store.documents), before);
    await ProgressRepository(store).reset();
    expect(await repo.load(const ParentSettings(level: 3)), isEmpty);
  });

  test(
    'completed, malformed and outside-path ink do not become resume shortcuts',
    () async {
      final store = MemoryStore();
      await store.write(
        'trace-h-ㅏ',
        TraceState(
          strokeIndex: 2,
          completed: [for (final p in tracePaths['ㅏ']!) p.samples(80)],
        ).toJson(),
      );
      await store.write('trace-h-ㅓ', {'strokeIndex': 2, 'completed': []});
      final advanced = learningItems.firstWhere(
        (i) => i.minimumLevel == 5 && i.strokes.length > 1,
      );
      await store.write(
        'trace-${advanced.id}',
        TraceState(
          strokeIndex: 1,
          completed: [advanced.strokes.first.samples(80)],
        ).toJson(),
      );
      await store.write('session-math', {'baseLevel': 3, 'level': 'bad'});
      expect(
        await LearningResumeRepository(store)
            .load(const ParentSettings(level: 3)),
        isEmpty,
      );
    },
  );

  test('parent ceiling and legacy sessions remain usable without rewriting source documents', () async {
    final store = MemoryStore();
    await LearningRepository(store).save(
      'math',
      const LearningSession(
        level: 5,
        baseLevel: 3,
        quizId: 'add-5-3',
        answered: true,
      ),
    );
    final before = jsonEncode(store.documents);
    final result = await LearningResumeRepository(store)
        .load(const ParentSettings(level: 3, autoAdvanceLearning: false));
    expect(result.single.location, '/learn/math?mode=quiz');
    expect(result.single.detail, isNot(contains('다음 놀이')));
    expect(jsonEncode(store.documents), before);
    expect(
      await LearningResumeRepository(store)
          .load(const ParentSettings(level: 2)),
      isEmpty,
    );
  });

  for (final size in [
    const Size(360, 780),
    const Size(780, 360),
    const Size(1280, 800),
  ]) {
    testWidgets('home resumes quiz mode and partial ink at $size text 1.5', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = MemoryStore();
      await ProfileRepository(store)
          .save(const ParentSettings(autoRead: false, animations: false));
      await seed(store);
      final c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      final boundary = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: RepaintBoundary(key: boundary, child: const KkomaApp()),
        ),
      );
      await tester.pumpAndSettle();
      if (capture) {
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('docs/screenshots').createSync(recursive: true);
          await File(
            'docs/screenshots/resume-home-${size.width.toInt()}x${size.height.toInt()}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      Future<void> open(String key) async {
        final card = find.byKey(ValueKey(key));
        await tester.scrollUntilVisible(
          card,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();
      }

      await open('resume-quiz');
      expect(find.text('별이 몇 개일까요?'), findsOneWidget);
      expect(c.read(learningProvider('math')).requireValue.hint, 2);
      await tester.tap(find.byTooltip('집으로'));
      await tester.pumpAndSettle();
      await open('resume-tracing');
      expect(find.byType(TraceCanvas), findsOneWidget);
      expect(c.read(traceProvider('h-ㅏ')).requireValue.strokeIndex, 1);
      await c
          .read(traceProvider('h-ㅏ').notifier)
          .submit(tracePaths['ㅏ']!.last.samples(80), 3);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('집으로'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('resume-tracing')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }

  testWidgets(
    'resume read error offers retry and does not block the rest of home',
    (tester) async {
      final store = _FailureStore();
      await seed(store);
      store.rejectReads = true;
      await ProfileRepository(store)
          .save(const ParentSettings(autoRead: false, animations: false));
      final c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const KkomaApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text('학습 이어하기를 불러오지 못했어요'), findsOneWidget);
      expect(find.text('손가락 준비 운동'), findsOneWidget);
      store.rejectReads = false;
      await tester.tap(find.byTooltip('이어하기 다시 불러오기'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('resume-quiz')), findsOneWidget);
      expect(find.text('학습 이어하기를 불러오지 못했어요'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
