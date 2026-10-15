import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/drawing/data/drawing_repository.dart';
import 'package:flutter_application_1/features/drawing/domain/drawing.dart';
import 'package:flutter_application_1/features/drawing/presentation/drawing_page.dart';
import 'package:flutter_application_1/features/drawing/presentation/drawing_vm.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_placement_board.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';

import 'episode_finale_test.dart' show finaleScene;

class _DiskStore extends MemoryStore {
  bool rejectStory = false, rejectArt = false;
  @override
  Future<bool> writeIfUnchanged(
    String key,
    Map<String, dynamic> expected,
    Map<String, dynamic> next,
  ) async {
    if (rejectStory && key == 'story') {
      throw const FileSystemException('disk full');
    }
    return super.writeIfUnchanged(key, expected, next);
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if ((rejectStory && key == 'story') || (rejectArt && key == 'artworks')) {
      throw const FileSystemException('disk full');
    }
    await super.write(key, value);
  }
}

Future<ProviderContainer> _setup(
  _DiskStore store,
  int episode,
  String suffix, {
  Directory? directory,
}) async {
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
  await StoryRepository(store).save(finaleScene(episode, suffix));
  return ProviderContainer(
    overrides: [
      storeProvider.overrideWithValue(store),
      if (directory != null)
        artworkDirectoryProvider.overrideWith((ref) async => directory),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'placement VM commits before publishing and retry does not double count',
    () async {
      final store = _DiskStore();
      final container = await _setup(store, 6, 'quiz');
      addTearDown(container.dispose);
      await container.read(storyProvider.future);
      final vm = container.read(storyProvider.notifier);
      store.rejectStory = true;
      await expectLater(
        vm.placeObject(2, 0),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        container.read(storyProvider).requireValue.observedObjects,
        isEmpty,
      );
      store.rejectStory = false;
      await vm.placeObject(2, 0);
      await vm.placeObject(2, 1);
      expect(container.read(storyProvider).requireValue.observedObjects, [2]);
      container.invalidate(storyProvider);
      expect((await container.read(storyProvider.future)).observedObjects, [2]);
    },
  );
  test(
    'garden draft has independent undo, redo and persistence from free drawing',
    () async {
      final store = _DiskStore();
      final container = await _setup(store, 7, 'trace');
      addTearDown(container.dispose);
      await container.read(drawingProvider.future);
      await container.read(storyDrawingProvider.future);
      const free = DrawingLine([TracePoint(.1, .2)], color: 0xff112233);
      const flower = DrawingLine([
        TracePoint(.3, .4),
        TracePoint(.5, .6),
      ], color: 0xffe76f51);
      await container.read(drawingProvider.notifier).add(free);
      final garden = container.read(storyDrawingProvider.notifier);
      await garden.add(flower);
      await garden.undo();
      expect(
        container.read(storyDrawingProvider).requireValue.current.lines,
        isEmpty,
      );
      await garden.redo();
      container.invalidate(storyDrawingProvider);
      container.invalidate(drawingProvider);
      expect(
        (await container.read(storyDrawingProvider.future))
            .current
            .lines
            .single
            .color,
        flower.color,
      );
      expect(
        (await container.read(drawingProvider.future))
            .current
            .lines
            .single
            .color,
        free.color,
      );
    },
  );
  testWidgets(
    'garden save handles artwork and story failures, retries once and keeps free draft',
    (tester) async {
      await tester.runAsync(() async {
        final directory = await Directory.systemTemp.createTemp(
          'kkoma-garden-final-',
        );
        final store = _DiskStore();
        final container = await _setup(store, 7, 'trace', directory: directory);
        try {
          await container.read(storyProvider.future);
          await container.read(storyDrawingProvider.future);
          final vm = container.read(storyProvider.notifier);
          await vm.saveGardenDrawing();
          expect(
            container.read(storyProvider).requireValue.phase,
            StoryPhase.drawing,
          );
          await container
              .read(storyDrawingProvider.notifier)
              .add(const DrawingLine([TracePoint(.1, .2), TracePoint(.8, .6)]));
          store.rejectArt = true;
          await expectLater(
            vm.saveGardenDrawing(),
            throwsA(isA<FileSystemException>()),
          );
          expect(
            container.read(storyProvider).requireValue.phase,
            StoryPhase.drawing,
          );
          expect(await directory.list().length, 0);
          store.rejectArt = false;
          store.rejectStory = true;
          await expectLater(
            vm.saveGardenDrawing(),
            throwsA(isA<FileSystemException>()),
          );
          expect(
            (await container.read(drawingRepositoryProvider).list()).length,
            1,
          );
          expect(
            container.read(storyProvider).requireValue.phase,
            StoryPhase.drawing,
          );
          store.rejectStory = false;
          await vm.saveGardenDrawing();
          await vm.saveGardenDrawing();
          expect(
            (await container.read(drawingRepositoryProvider).list()).length,
            1,
          );
          expect(
            container.read(storyProvider).requireValue.phase,
            StoryPhase.success,
          );
          final artwork =
              (await container.read(drawingRepositoryProvider).list()).single;
          expect((await File(artwork.path).readAsBytes()).take(8), [
            137,
            80,
            78,
            71,
            13,
            10,
            26,
            10,
          ]);
          expect(
            (await container.read(drawingProvider.future)).current.lines,
            isEmpty,
          );
          container.invalidate(storyProvider);
          expect(
            (await container.read(storyProvider.future)).phase,
            StoryPhase.success,
          );
        } finally {
          container.dispose();
          await directory.delete(recursive: true);
        }
      });
    },
  );
  for (final episode in [6, 11]) {
    testWidgets(
      'chapter $episode drag then tap places unique pieces and unlocks answers',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final c = await _setup(_DiskStore(), episode, 'quiz');
        await tester.pumpWidget(
          UncontrolledProviderScope(container: c, child: const KkomaApp()),
        );
        await tester.pumpAndSettle();
        c.read(routerProvider).go('/story');
        await tester.pumpAndSettle();
        final board = find.byType(StoryPlacementBoard);
        await Scrollable.ensureVisible(tester.element(board), alignment: .3);
        await tester.pumpAndSettle();
        final answer = find.byKey(const ValueKey('picture-answer-1'));
        expect(tester.widget<FilledButton>(answer).onPressed, isNull);
        final piece = find.byKey(const ValueKey('quiz-object-0'));
        final target = find.byKey(const ValueKey('place-target-0'));
        await tester.drag(
          piece,
          tester.getCenter(target) - tester.getCenter(piece),
        );
        await tester.pumpAndSettle();
        expect(c.read(storyProvider).requireValue.observedObjects, [0]);
        await tester.tap(piece);
        await tester.pumpAndSettle();
        expect(c.read(storyProvider).requireValue.observedObjects, [0]);
        final count = episode == 6 ? 3 : 5;
        for (var i = 1; i < count; i++) {
          await tester.tap(find.byKey(ValueKey('quiz-object-$i')));
          await tester.pumpAndSettle();
        }
        expect(tester.widget<FilledButton>(answer).onPressed, isNotNull);
        await Scrollable.ensureVisible(tester.element(answer), alignment: .5);
        await tester.pumpAndSettle();
        await tester.tap(answer);
        await tester.pumpAndSettle();
        expect(c.read(storyProvider).requireValue.phase, StoryPhase.success);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        await tester.pumpAndSettle();
      },
    );
  }
  for (final size in [
    const Size(360, 780),
    const Size(780, 360),
    const Size(1280, 800),
  ]) {
    testWidgets('garden palette eraser and undo remain usable at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await _setup(_DiskStore(), 7, 'trace');
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const KkomaApp()),
      );
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/story');
      await tester.pumpAndSettle();
      final red = find.byKey(const ValueKey('garden-color-1'));
      await Scrollable.ensureVisible(tester.element(red), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(red);
      await tester.pumpAndSettle();
      expect(
        tester.widget<DrawingCanvas>(find.byType(DrawingCanvas)).color,
        0xffe76f51,
      );
      final canvas = find.byType(DrawingCanvas);
      final rect = tester.getRect(canvas);
      await tester.dragFrom(
        rect.center - const Offset(40, 0),
        const Offset(80, 15),
      );
      await tester.pumpAndSettle();
      expect(
        c.read(storyDrawingProvider).requireValue.current.lines.single.color,
        0xffe76f51,
      );
      final eraser = find.text('지우개');
      await Scrollable.ensureVisible(tester.element(eraser), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(eraser);
      await tester.pumpAndSettle();
      expect(tester.widget<DrawingCanvas>(canvas).eraser, true);
      final undo = find.byKey(const ValueKey('garden-undo'));
      await Scrollable.ensureVisible(tester.element(undo), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(undo);
      await tester.pumpAndSettle();
      expect(c.read(storyDrawingProvider).requireValue.current.lines, isEmpty);
      final redo = find.byKey(const ValueKey('garden-redo'));
      await Scrollable.ensureVisible(tester.element(redo), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(redo);
      await tester.pumpAndSettle();
      expect(c.read(storyDrawingProvider).requireValue.current.lines.length, 1);
      expect((await c.read(drawingProvider.future)).current.lines, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await tester.pumpAndSettle();
    });
  }
}
