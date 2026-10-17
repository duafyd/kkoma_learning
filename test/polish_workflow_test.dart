import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/drawing/domain/drawing.dart';
import 'package:flutter_application_1/features/drawing/presentation/drawing_page.dart';
import 'package:flutter_application_1/features/drawing/presentation/drawing_vm.dart';
import 'package:flutter_application_1/features/math/presentation/counting_vm.dart';
import 'package:flutter_application_1/features/math/presentation/sorting_vm.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';

class _Store extends MemoryStore {
  bool reject = false;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (reject && key.startsWith('math-sorting')) throw StateError('full');
    await super.write(key, value);
  }
}

class _Gallery extends GalleryVM {
  @override
  Future<List<Artwork>> build() async => [
    Artwork(
      id: 'test',
      path: 'missing.png',
      created: DateTime(2026, 10, 16),
      document: const DrawingDocument(
        lines: [DrawingLine([], stamp: 'flower')],
      ),
    ),
  ];
}

void main() {
  test('concrete arithmetic reports last real change and bounds without stale equations', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final sub = c.listen(countingProvider(4), (_, _) {});
    addTearDown(sub.close);
    final vm = c.read(countingProvider(4).notifier);
    vm.add();
    vm.add();
    expect(c.read(countingProvider(4)).change!.equation, '1 + 1 = 2');
    vm.collect(1);
    expect(c.read(countingProvider(4)).change!.equation, '1 + 1 = 2');
    vm.remove();
    expect(c.read(countingProvider(4)).change!.equation, '2 − 1 = 1');
    vm.reset();
    expect(c.read(countingProvider(4)).change, isNull);
  });
  for (final size in [
    const Size(360, 780),
    const Size(780, 360),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'home continuation, map, artwork fallback and named stamps at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = MemoryStore();
        await ProfileRepository(store).save(
          const ParentSettings(
            age: 5,
            level: 5,
            autoRead: false,
            animations: false,
            voiceVolume: 0,
          ),
        );
        await StoryRepository(
          store,
        ).save(const StorySnapshot(episode: 7, level: 5, completed: [1, 2, 3]));
        final c = ProviderContainer(
          overrides: [
            storeProvider.overrideWithValue(store),
            galleryProvider.overrideWith(_Gallery.new),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(container: c, child: const KkomaApp()),
        );
        await tester.pumpAndSettle();
        expect(find.text('8화 · 바람 친구 휙휙의 실수'), findsOneWidget);
        final before = c.read(storyProvider).requireValue.toJson();
        c.read(routerProvider).go('/gallery');
        await tester.pumpAndSettle();
        final chapter = find.byKey(const ValueKey('map-chapter-1'));
        await tester.ensureVisible(chapter);
        await tester.pumpAndSettle();
        await tester.tap(chapter);
        await tester.pumpAndSettle();
        expect(find.text('함께 모은 책등 조각 1'), findsOneWidget);
        await tester.tap(find.text('지도 보기'));
        await tester.pumpAndSettle();
        expect(c.read(storyProvider).requireValue.toJson(), before);
        final art = find.byKey(const ValueKey('artwork-preview-test'));
        await tester.scrollUntilVisible(
          art,
          400,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 30,
        );
        await tester.pumpAndSettle();
        await tester.tap(art);
        await tester.pumpAndSettle();
        expect(find.text('전시회로 돌아가기'), findsOneWidget);
        await tester.tap(find.text('전시회로 돌아가기'));
        await tester.pumpAndSettle();
        c.read(routerProvider).go('/drawing');
        await tester.pumpAndSettle();
        final stamp = find.byTooltip('꽃 도장');
        await tester.ensureVisible(stamp);
        await tester.pumpAndSettle();
        await tester.tap(stamp);
        await tester.pumpAndSettle();
        final canvas = find.byType(DrawingCanvas);
        await tester.ensureVisible(canvas);
        await tester.pumpAndSettle();
        await tester.tapAt(tester.getCenter(canvas));
        await tester.pumpAndSettle();
        expect(
          c.read(drawingProvider).requireValue.current.lines.last.stamp,
          'flower',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      },
    );
    testWidgets(
      'connection drag, cancel, failed save and tap alternative preserve pairing at $size',
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
            animations: false,
            voiceVolume: 0,
          ),
        );
        final c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(container: c, child: const KkomaApp()),
        );
        await tester.pumpAndSettle();
        c.read(routerProvider).go('/math/match');
        await tester.pumpAndSettle();
        final toggle = find.text('선으로 잇기');
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        var s = c.read(sortingProvider(5)).requireValue;
        final vm = c.read(sortingProvider(5).notifier),
            round = vm.rules.activity(s);
        final index = round.targets.indexOf(round.pieces[0]);
        final source = find.byKey(const ValueKey('connection-piece-0'));
        final target = find.byKey(ValueKey('connection-target-$index'));
        await tester.ensureVisible(source);
        await tester.pumpAndSettle();
        final finger = await tester.startGesture(tester.getCenter(source));
        await finger.moveBy(const Offset(30, 0));
        await finger.cancel();
        await tester.pumpAndSettle();
        expect(c.read(sortingProvider(5)).requireValue.placed, isEmpty);
        // Tap selection survives scrolling on short or enlarged displays.
        await tester.tap(source);
        await tester.pumpAndSettle();
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        store.reject = true;
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(c.read(sortingProvider(5)).requireValue.placed, isEmpty);
        store.reject = false;
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(c.read(sortingProvider(5)).requireValue.placed[0], index);
        c.invalidate(sortingProvider(5));
        await tester.pumpAndSettle();
        s = c.read(sortingProvider(5)).requireValue;
        expect(s.placed[0], index);
        if (size.width == 1280) {
          final second = find.byKey(const ValueKey('connection-piece-1'));
          final secondTarget = find.byKey(
            ValueKey(
              'connection-target-${round.targets.indexOf(round.pieces[1])}',
            ),
          );
          await tester.ensureVisible(second);
          await tester.pumpAndSettle();
          await tester.drag(
            second,
            tester.getCenter(secondTarget) - tester.getCenter(second),
          );
          await tester.pumpAndSettle();
          expect(c.read(sortingProvider(5)).requireValue.placed.length, 2);
        }
        // Same VM/rules back both presentations.
        await c.read(sortingProvider(5).notifier).select(0);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      },
    );
  }
}
