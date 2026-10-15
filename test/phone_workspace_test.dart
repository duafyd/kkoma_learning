import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/drawing/presentation/drawing_page.dart';
import 'package:flutter_application_1/features/drawing/presentation/drawing_vm.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_canvas.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_vm.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';

void main() {
  for (final size in [const Size(360, 780), const Size(780, 360)]) {
    testWidgets('phone gestures, rotation and story activities at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = MemoryStore();
      await ProfileRepository(store).save(
        const ParentSettings(
          age: 5,
          level: 5,
          autoRead: false,
          voiceVolume: 0,
          animations: false,
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
      container.read(routerProvider).go('/trace/n-1');
      await tester.pumpAndSettle();
      final paint = find
          .descendant(
            of: find.byType(TraceCanvas),
            matching: find.byType(CustomPaint),
          )
          .first;
      final rect = tester.getRect(paint);
      expect(rect.shortestSide, greaterThanOrEqualTo(180));
      final points = tracePaths['1']!.single.samples(20);
      Offset position(int i) =>
          rect.topLeft +
          Offset(points[i].x * rect.width, points[i].y * rect.height);
      final gesture = await tester.startGesture(position(0));
      for (var i = 1; i < points.length; i++) {
        await gesture.moveTo(position(i));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(container.read(traceProvider('n-1')).requireValue.done, true);
      container.read(routerProvider).go('/drawing');
      await tester.pumpAndSettle();
      final canvas = find.byType(DrawingCanvas);
      expect(tester.getSize(canvas).shortestSide, greaterThanOrEqualTo(180));
      await tester.dragFrom(tester.getCenter(canvas), const Offset(40, 60));
      await tester.pumpAndSettle();
      expect(
        container.read(drawingProvider).requireValue.current.lines.length,
        1,
      );
      tester.view.physicalSize = Size(size.height, size.width);
      await tester.pumpAndSettle();
      expect(
        container.read(drawingProvider).requireValue.current.lines.length,
        1,
      );
      await tester.ensureVisible(find.text('정원'));
      await tester.tap(find.text('정원'));
      await tester.pumpAndSettle();
      expect(
        container.read(drawingProvider).requireValue.current.background,
        0xffe6f1d8,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'canvas rotation and tool access',
      );
      container.read(routerProvider).go('/parent');
      await tester.pumpAndSettle();
      final prompt = tester
          .widget<Text>(find.textContaining(RegExp(r'\d+ \+ \d+ = \?')))
          .data!;
      final numbers = RegExp(r'\d+')
          .allMatches(prompt)
          .map((m) => int.parse(m.group(0)!))
          .toList();
      await tester.enterText(
        find.byType(TextField),
        '${numbers[0] + numbers[1]}',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('설정 열기'));
      expect(
        tester.takeException(),
        isNull,
        reason: 'parent gate with keyboard',
      );
      await tester.tap(find.text('설정 열기'));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('앱 종료'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.takeException(), isNull, reason: 'unlocked settings');
      final machine = StoryMachine();
      for (final phase in [
        StoryPhase.choice,
        StoryPhase.quiz,
        StoryPhase.tracing,
        StoryPhase.drawing,
      ]) {
        final episode = machine.episodes.indexWhere(
          (e) => e.forLevel(5).any((s) => s.interaction == phase),
        );
        final scene = machine.episodes[episode]
            .forLevel(5)
            .indexWhere((s) => s.interaction == phase);
        await StoryRepository(store).save(
          StorySnapshot(
            episode: episode,
            scene: scene,
            level: 5,
            phase: phase,
            attempts: 3,
            hints: 3,
          ),
        );
        container.invalidate(storyProvider);
        container.read(routerProvider).go('/story');
        await tester.pumpAndSettle();
        if (phase == StoryPhase.tracing) {
          expect(
            tester.getSize(find.byType(TraceCanvas)).shortestSide,
            greaterThanOrEqualTo(180),
          );
          await tester.ensureVisible(find.text('친구와 함께 통과'));
          expect(find.text('친구와 함께 통과').hitTestable(), findsOneWidget);
        }
        if (phase == StoryPhase.drawing) {
          expect(
            tester.getSize(find.byType(DrawingCanvas)).shortestSide,
            greaterThanOrEqualTo(180),
          );
          await tester.ensureVisible(find.text('정원 그림 저장하고 계속'));
        }
        expect(tester.takeException(), isNull, reason: 'story $phase');
      }
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  }
}
