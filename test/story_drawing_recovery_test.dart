import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/drawing/data/drawing_repository.dart';
import 'package:flutter_application_1/features/drawing/domain/drawing.dart';
import 'package:flutter_application_1/features/drawing/presentation/drawing_vm.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/progress/data/progress_repository.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';

const _garden = StorySnapshot(
  episode: 6,
  scene: 5,
  level: 5,
  phase: StoryPhase.drawing,
  flags: {'companion': '토토'},
);
const _flower = DrawingDocument(
  lines: [
    DrawingLine([TracePoint(.2, .3), TracePoint(.7, .6)], color: 0xffe76f51),
  ],
);

class _InterruptedStore extends MemoryStore {
  bool rejectStage = false, rejectFinish = false, rejectArt = false;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key == 'artworks' && rejectArt) throw const FileSystemException('full');
    await super.write(key, value);
  }

  @override
  Future<bool> writeIfUnchanged(
    String key,
    Map<String, dynamic> expected,
    Map<String, dynamic> next,
  ) async {
    if (key == 'story' &&
        ((rejectStage && expected['pendingDrawing'] == null) ||
            (rejectFinish && expected['pendingDrawing'] != null))) {
      throw const FileSystemException('interrupted story commit');
    }
    return super.writeIfUnchanged(key, expected, next);
  }
}

Future<ProviderContainer> _container(MemoryStore store, Directory dir) async {
  if (await store.read('settings') == null) {
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
  }
  return ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      storeProvider.overrideWithValue(store),
      artworkDirectoryProvider.overrideWith((ref) async => dir),
    ],
  );
}

class _PausedDrawing extends DrawingRepository {
  final started = Completer<void>(), resume = Completer<void>();
  _PausedDrawing(super.store, super.directory);
  @override
  Future<Artwork> savePrepared(Artwork artwork) async {
    started.complete();
    await resume.future;
    return super.savePrepared(artwork);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final point in ['intent', 'partial-png', 'png', 'metadata']) {
    testWidgets(
      'restart after $point recovers one valid PNG and one completed garden mission',
      (tester) async {
        await tester.runAsync(() async {
          final dir = await Directory.systemTemp.createTemp('garden-restart-');
          final store = MemoryStore();
          final repo = DrawingRepository(store, () async => dir);
          final artwork = await repo.prepare(_flower);
          final pending = _garden.change({'pendingDrawing': artwork.toJson()});
          await StoryRepository(store).save(pending);
          await repo.saveDraft(const DrawingDocument(background: 0xffabcabc));
          if (point == 'partial-png') {
            await File('${artwork.path}.saving').writeAsBytes([137, 80]);
          }
          if (point == 'png') await File(artwork.path).writeAsBytes([0, 1, 2]);
          if (point == 'metadata') await repo.savePrepared(artwork);
          var c = await _container(store, dir);
          try {
            var restored = await c.read(storyProvider.future);
            expect(restored.phase, StoryPhase.success);
            expect(restored.pendingDrawing, isNull);
            expect(restored.flags['gardenArtwork'], artwork.id);
            expect(restored.flags['companion'], '토토');
            expect(
              (await c.read(drawingRepositoryProvider).list()).single.id,
              artwork.id,
            );
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
            expect(await File('${artwork.path}.saving').exists(), false);
            c.dispose();
            c = await _container(store, dir);
            restored = await c.read(storyProvider.future);
            expect(restored.phase, StoryPhase.success);
            expect((await c.read(drawingRepositoryProvider).list()).length, 1);
            expect(
              (await c.read(drawingProvider.future)).current.background,
              0xffabcabc,
            );
          } finally {
            c.dispose();
            await dir.delete(recursive: true);
          }
        });
      },
    );
  }
  testWidgets(
    'failed final commit survives a new VM and retries the same artwork ID',
    (tester) async {
      await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp(
          'garden-final-commit-',
        );
        final store = _InterruptedStore();
        await StoryRepository(store).save(_garden);
        var c = await _container(store, dir);
        try {
          await c.read(storyProvider.future);
          await c.read(storyDrawingProvider.future);
          await c.read(storyDrawingProvider.notifier).load(_flower);
          store.rejectFinish = true;
          await expectLater(
            c.read(storyProvider.notifier).saveGardenDrawing(),
            throwsA(isA<FileSystemException>()),
          );
          final id = (await StoryRepository(store).load())!.pendingDrawing!.id;
          expect(
            (await c.read(drawingRepositoryProvider).list()).single.id,
            id,
          );
          c.dispose();
          c = await _container(store, dir);
          await expectLater(
            c.read(storyProvider.future),
            throwsA(isA<FileSystemException>()),
          );
          expect((await StoryRepository(store).load())!.pendingDrawing!.id, id);
          store.rejectFinish = false;
          c.invalidate(storyProvider);
          expect(
            (await c.read(storyProvider.future)).phase,
            StoryPhase.success,
          );
          expect(
            (await c.read(drawingRepositoryProvider).list()).single.id,
            id,
          );
        } finally {
          c.dispose();
          await dir.delete(recursive: true);
        }
      });
    },
  );
  testWidgets('failed intent writes no artwork and keeps the editable draft', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('garden-intent-fail-');
      final store = _InterruptedStore();
      await StoryRepository(store).save(_garden);
      final c = await _container(store, dir);
      try {
        await c.read(storyProvider.future);
        await c.read(storyDrawingProvider.future);
        await c.read(storyDrawingProvider.notifier).load(_flower);
        store.rejectStage = true;
        await expectLater(
          c.read(storyProvider.notifier).saveGardenDrawing(),
          throwsA(isA<FileSystemException>()),
        );
        expect(c.read(storyProvider).requireValue.pendingDrawing, isNull);
        expect(await dir.list().length, 0);
        expect(
          (await c.read(storyDrawingProvider.future)).current.lines,
          isNotEmpty,
        );
        store.rejectStage = false;
        await c.read(storyProvider.notifier).saveGardenDrawing();
        expect(c.read(storyProvider).requireValue.phase, StoryPhase.success);
      } finally {
        c.dispose();
        await dir.delete(recursive: true);
      }
    });
  });
  testWidgets(
    'missing PNG for registered pending art is reconstructed without a duplicate',
    (tester) async {
      await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp(
          'garden-missing-png-',
        );
        final store = MemoryStore(),
            repo = DrawingRepository(MemoryStore(), () async => dir);
        final artwork = await repo.prepare(_flower);
        await store.write('artworks', {
          'items': [artwork.toJson()],
        });
        await StoryRepository(store)
            .save(_garden.change({'pendingDrawing': artwork.toJson()}));
        final c = await _container(store, dir);
        try {
          expect(
            (await c.read(storyProvider.future)).phase,
            StoryPhase.success,
          );
          expect(await File(artwork.path).exists(), true);
          expect((await c.read(drawingRepositoryProvider).list()).length, 1);
        } finally {
          c.dispose();
          await dir.delete(recursive: true);
        }
      });
    },
  );
  for (final reset in [false, true]) {
    testWidgets(
      'late submission cannot overwrite ${reset ? 'parent reset' : 'a newer story'}',
      (tester) async {
        await tester.runAsync(() async {
          final dir = await Directory.systemTemp.createTemp('garden-stale-');
          final store = MemoryStore();
          await ProfileRepository(store)
              .save(const ParentSettings(age: 5, level: 5));
          await StoryRepository(store).save(_garden);
          final repo = _PausedDrawing(store, () async => dir);
          final c = ProviderContainer(
            overrides: [
              storeProvider.overrideWithValue(store),
              drawingRepositoryProvider.overrideWithValue(repo),
            ],
          );
          try {
            await c.read(storyProvider.future);
            await c.read(storyDrawingProvider.future);
            await c.read(storyDrawingProvider.notifier).load(_flower);
            final saving = c.read(storyProvider.notifier).saveGardenDrawing();
            await repo.started.future;
            if (reset) {
              await ProgressRepository(store).reset();
            } else {
              await StoryRepository(store)
                  .save(const StorySnapshot(episode: 9, level: 5));
            }
            repo.resume.complete();
            await saving;
            final actual = await StoryRepository(store).load();
            expect(actual?.episode, reset ? null : 9);
            expect(c.read(storyProvider).requireValue.episode, reset ? 0 : 9);
          } finally {
            c.dispose();
            await dir.delete(recursive: true);
          }
        });
      },
    );
  }
  testWidgets(
    'prepared artwork rejects ID reuse and paths outside the artwork directory',
    (tester) async {
      await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp('garden-owned-');
        final repo = DrawingRepository(MemoryStore(), () async => dir);
        try {
          final a = await repo.prepare(_flower);
          await repo.savePrepared(a);
          final changed = Artwork(
            id: a.id,
            path: a.path,
            created: a.created,
            document: const DrawingDocument(),
          );
          await expectLater(repo.savePrepared(changed), throwsStateError);
          final outside = Artwork(
            id: a.id,
            path: '${dir.parent.path}/${a.id}.png',
            created: a.created,
            document: _flower,
          );
          await expectLater(
            repo.savePrepared(outside),
            throwsA(isA<FileSystemException>()),
          );
          expect(
            (await repo.list()).single.document.lines.single.color,
            0xffe76f51,
          );
        } finally {
          await dir.delete(recursive: true);
        }
      });
    },
  );
  testWidgets(
    'pending submission finishes before an age change skips the drawing scene',
    (tester) async {
      await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp('garden-age-change-');
        final store = MemoryStore(),
            repo = DrawingRepository(MemoryStore(), () async => dir);
        final artwork = await repo.prepare(_flower);
        await StoryRepository(store)
            .save(_garden.change({'pendingDrawing': artwork.toJson()}));
        await ProfileRepository(store)
            .save(const ParentSettings(age: 2, level: 2));
        final c = await _container(store, dir);
        try {
          final s = await c.read(storyProvider.future);
          expect(s.level, 2);
          expect(s.phase, StoryPhase.dialogue);
          expect(c.read(storyProvider.notifier).machine.scene(s).id, 'ep7-end');
          expect(
            (await c.read(drawingRepositoryProvider).list()).single.id,
            artwork.id,
          );
        } finally {
          c.dispose();
          await dir.delete(recursive: true);
        }
      });
    },
  );
  test('conditional story save accepts legacy JSON and rejects stale/reset records', () async {
    final store = MemoryStore();
    final repository = StoryRepository(store);
    final legacy = _garden.toJson()..remove('pendingDrawing');
    await store.write('story', legacy);
    final next = _garden.change({'message': '저장할 그림을 골랐어요.'});
    expect(await repository.replaceIfCurrent(_garden, next), true);
    expect(await repository.replaceIfCurrent(_garden, next), false);
    await store.remove('story');
    expect(await repository.replaceIfCurrent(next, _garden), false);
    expect(await repository.load(), isNull);
  });
  for (final size in [
    const Size(360, 780),
    const Size(780, 360),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'failed artwork save presents a retry and freezes submitted drawing at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final dir = await tester.runAsync(
          () => Directory.systemTemp.createTemp('garden-retry-ui-'),
        );
        final store = _InterruptedStore();
        await StoryRepository(store).save(_garden);
        final c = await _container(store, dir!);
        try {
          await c.read(storyProvider.future);
          await c.read(storyDrawingProvider.future);
          await c.read(storyDrawingProvider.notifier).load(_flower);
          store.rejectArt = true;
          await tester.pumpWidget(
            UncontrolledProviderScope(container: c, child: const KkomaApp()),
          );
          await tester.pumpAndSettle();
          c.read(routerProvider).go('/story');
          await tester.pumpAndSettle();
          await tester.runAsync(
            () => expectLater(
              c.read(storyProvider.notifier).saveGardenDrawing(),
              throwsA(isA<FileSystemException>()),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('garden-retry-save')),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('garden-save')), findsNothing);
          store.rejectArt = false;
          await tester.runAsync(() async {
            await Scrollable.ensureVisible(
              tester.element(find.byKey(const ValueKey('garden-retry-save'))),
              alignment: .5,
            );
            await tester.tap(find.byKey(const ValueKey('garden-retry-save')));
            // The UI owns this asynchronous callback; let real PNG I/O finish.
            await Future.doWhile(() async {
              await Future<void>.delayed(const Duration(milliseconds: 5));
              return c.read(storyProvider.notifier).busy;
            }).timeout(const Duration(seconds: 5));
          });
          await tester.pumpAndSettle();
          expect(c.read(storyProvider).requireValue.phase, StoryPhase.success);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        } finally {
          c.dispose();
          await tester.runAsync(() => dir.delete(recursive: true));
        }
      },
    );
  }
}
