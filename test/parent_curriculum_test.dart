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
import 'package:flutter_application_1/features/learning/presentation/learning_vm.dart';
import 'package:flutter_application_1/features/parent/presentation/learning_overview_vm.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/profile/presentation/profile_vm.dart';
import 'package:flutter_application_1/features/progress/data/progress_repository.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_canvas.dart';

class _FailSettingsStore extends MemoryStore {
  bool reject = false;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (reject && key == 'settings') throw StateError('fixture');
    await super.write(key, value);
  }
}

Future<void> unlock(WidgetTester tester) async {
  final prompt = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .singleWhere((s) => RegExp(r'^\d+ \+ \d+ = \?$').hasMatch(s));
  final values = RegExp(r'\d+')
      .allMatches(prompt)
      .map((m) => int.parse(m[0]!))
      .toList();
  await tester.enterText(find.byType(TextField), '${values[0] + values[1]}');
  await tester.ensureVisible(find.text('설정 열기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('설정 열기'));
  await tester.pumpAndSettle();
}

void main() {
  const capture = bool.fromEnvironment('PARENT_CAPTURE');
  setUpAll(() async {
    if (!capture) return;
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
    for (final (family, path) in [
      ('Roboto', 'C:/Windows/Fonts/malgun.ttf'),
      (
        'MaterialIcons',
        'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    ]) {
      final font = File(path);
      if (font.existsSync()) {
        await (FontLoader(family)..addFont(
              Future.value(ByteData.sublistView(font.readAsBytesSync())),
            ))
            .load();
      }
    }
  });
  test(
    'old settings keep automatic progression and new choice survives reload',
    () async {
      expect(ParentSettings.fromJson({'age': 4}).autoAdvanceLearning, isTrue);
      final store = MemoryStore();
      await ProfileRepository(store)
          .save(const ParentSettings(autoAdvanceLearning: false));
      expect(
        (await ProfileRepository(store).load()).autoAdvanceLearning,
        isFalse,
      );
    },
  );

  test(
    'selected path caps the next quiz while default adaptation still rises',
    () async {
      for (final enabled in [false, true]) {
        final store = MemoryStore();
        await ProfileRepository(store)
            .save(ParentSettings(level: 3, autoAdvanceLearning: enabled));
        await LearningRepository(store).save(
          'math',
          const LearningSession(
            level: 3,
            baseLevel: 3,
            answered: true,
            successes: 3,
          ),
        );
        final c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
        final sub = c.listen(learningProvider('math'), (_, _) {});
        await c.read(learningProvider('math').future);
        await c.read(learningProvider('math').notifier).next();
        final next = c.read(learningProvider('math')).requireValue;
        expect(next.level, enabled ? 4 : 3);
        expect(next.index, 1);
        expect(
          (await LearningRepository(store).load('math', 3)).level,
          next.level,
        );
        sub.close();
        c.dispose();
      }
    },
  );

  test('restored higher session clears obsolete answer without erasing achievements', () async {
    final store = MemoryStore();
    await ProfileRepository(store)
        .save(const ParentSettings(level: 3, autoAdvanceLearning: false));
    await LearningRepository(store).save(
      'math',
      const LearningSession(
        level: 5,
        baseLevel: 3,
        index: 8,
        answered: true,
        hint: 2,
        successes: 4,
        quizOverrideId: 'add-5-3',
      ),
    );
    await ProgressRepository(store).record('add-5-3', true);
    final before = jsonEncode(await ProgressRepository(store).load());
    final c = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    final sub = c.listen(learningProvider('math'), (_, _) {});
    final state = await c.read(learningProvider('math').future);
    expect(state.level, 3);
    expect(state.index, 8);
    expect(state.answered, isFalse);
    expect(state.hint, 0);
    expect(state.quizOverrideId, isNull);
    expect(
      c
          .read(learningProvider('math').notifier)
          .quizzes
          .every((q) => q.minimumLevel <= 3),
      isTrue,
    );
    expect(jsonEncode(await ProgressRepository(store).load()), before);
    await c.read(learningProvider('math').notifier).easier();
    expect(c.read(learningProvider('math')).requireValue.level, 2);
    sub.close();
    c.dispose();
  });

  test('settings write failure keeps old control and queued retry preserves other settings', () async {
    final store = _FailSettingsStore();
    final c = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    await c.read(settingsProvider.future);
    final vm = c.read(settingsProvider.notifier);
    store.reject = true;
    await expectLater(
      vm.change('autoAdvanceLearning', false),
      throwsStateError,
    );
    expect(c.read(settingsProvider).requireValue.autoAdvanceLearning, isTrue);
    store.reject = false;
    await Future.wait([
      vm.change('autoAdvanceLearning', false),
      vm.change('voiceVolume', .2),
    ]);
    final saved = await ProfileRepository(store).load();
    expect(saved.autoAdvanceLearning, isFalse);
    expect(saved.voiceVolume, .2);
    c.dispose();
  });

  test(
    'overview exactly filters configured content and twelve episode lengths',
    () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      for (var level = 2; level <= 5; level++) {
        final plan = c.read(learningOverviewProvider(level));
        expect(plan.chapters.length, 12);
        expect(plan.chapters.map((c) => c.sceneCount).toSet(), {
          level == 2
              ? 4
              : level == 3
              ? 6
              : level == 4
              ? 8
              : 10,
        });
        expect(plan.prewriting.length, 6);
        for (final subject in plan.subjects.keys) {
          expect(
            plan.subjects[subject]!.map((i) => i.id).toSet(),
            learningItems
                .where((i) => i.subject == subject && i.minimumLevel <= level)
                .map((i) => i.id)
                .toSet(),
          );
        }
      }
    },
  );

  for (final size in [
    const Size(360, 780),
    const Size(780, 360),
    const Size(1280, 800),
  ]) {
    testWidgets('guarded preview and ceiling persist at $size with large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = MemoryStore();
      await ProfileRepository(store).save(
        const ParentSettings(level: 3, autoRead: false, animations: false),
      );
      await store.write('trace-h-ㅏ', {'strokeIndex': 1, 'done': false});
      final progressBefore = jsonEncode(await store.read('trace-h-ㅏ'));
      final c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      final boundary = GlobalKey();
      Future<void> picture(String name) async {
        if (!capture) return;
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage();
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('docs/screenshots')
            ..createSync(recursive: true);
          await File(
            '${directory.path}/parent-$name-${size.width.toInt()}x${size.height.toInt()}.png',
          ).writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: RepaintBoundary(key: boundary, child: const KkomaApp()),
        ),
      );
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/parent');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('learning-overview')), findsNothing);
      await unlock(tester);
      final toggle = find.byKey(const ValueKey('auto-advance-learning'));
      await tester.scrollUntilVisible(
        toggle,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final control = find.descendant(
        of: toggle,
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(control);
      await tester.pumpAndSettle();
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(
        (await ProfileRepository(store).load()).autoAdvanceLearning,
        isFalse,
      );
      final overview = find.byKey(const ValueKey('learning-overview'));
      await tester.scrollUntilVisible(
        overview,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: overview, matching: find.text('학습 내용 미리보기')),
      );
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
      final chip = find.byKey(const ValueKey('preview-h-ㅏ'));
      await tester.scrollUntilVisible(
        chip,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.byType(TraceCanvas), findsOneWidget);
      final next = find.text('다음 획');
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('2 / 2획'), findsOneWidget);
      await picture('guide');
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      final questions = find.text('한글 함께 찾기 살펴보기');
      await tester.scrollUntilVisible(
        questions,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(questions);
      await tester.pumpAndSettle();
      final question = find.text('가방의 첫 자음을 찾아요');
      await tester.ensureVisible(question);
      await tester.pumpAndSettle();
      await tester.tap(question);
      await tester.pumpAndSettle();
      expect(find.text('참고 답: ㄱ'), findsOneWidget);
      await picture('quiz');
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      expect(jsonEncode(await store.read('trace-h-ㅏ')), progressBefore);
      expect(await store.read('story'), isNull);
      expect(await store.read('session-hangul'), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
