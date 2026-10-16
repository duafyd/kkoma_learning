import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/progress/data/progress_repository.dart';
import 'package:flutter_application_1/features/tracing/data/prewriting_content.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_canvas.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_vm.dart';

void main() {
  test('tap strategy is restricted to readiness dot; lines/circles retain path rules', () {
    final strategy = PrewritingStrategy(const AgeStrategy(2));
    final dot = prewritingItems.first.strokes.single;
    expect(strategy.evaluate(dot, [const TracePoint(.5, .5)]).accepted, isTrue);
    expect(
      strategy.evaluate(dot, [const TracePoint(.1, .1)]).accepted,
      isFalse,
    );
    expect(
      strategy.evaluate(dot, [
        const TracePoint(.5, .5),
        const TracePoint(.9, .9),
      ]).accepted,
      isFalse,
    );
    expect(
      const TraceStrategy(AgeStrategy(2))
          .evaluate(dot, [const TracePoint(.5, .5)])
          .accepted,
      isFalse,
    );
    for (final item in prewritingItems.skip(1)) {
      final path = item.strokes.single;
      expect(
        strategy.evaluate(path, path.samples(100)).accepted,
        isTrue,
        reason: item.id,
      );
      expect(
        strategy.evaluate(path, path.samples(100).take(30).toList()).accepted,
        isFalse,
        reason: item.id,
      );
      expect(
        strategy.evaluate(path, [
          path.points.first,
          path.points.first,
        ]).accepted,
        isFalse,
        reason: item.id,
      );
    }
  });
  for (final size in [
    const Size(360, 780),
    const Size(780, 360),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'readiness touch, cancel, next, restore and parent reset at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = MemoryStore();
        await ProfileRepository(store).save(
          const ParentSettings(
            age: 2,
            level: 2,
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
        c.read(routerProvider).go('/prewriting');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('prewriting-p-dot')));
        await tester.pumpAndSettle();
        final canvas = find
            .descendant(
              of: find.byType(TraceCanvas),
              matching: find.byType(CustomPaint),
            )
            .first;
        var finger = await tester.startGesture(tester.getCenter(canvas));
        await finger.cancel();
        await tester.pumpAndSettle();
        expect(c.read(traceProvider('p-dot')).requireValue.done, isFalse);
        await tester.tapAt(tester.getCenter(canvas));
        await tester.pumpAndSettle();
        expect(c.read(traceProvider('p-dot')).requireValue.done, isTrue);
        c.invalidate(traceProvider('p-dot'));
        await tester.pumpAndSettle();
        expect(c.read(traceProvider('p-dot')).requireValue.done, isTrue);
        final next = find.text('다음 모양');
        await tester.ensureVisible(next);
        await tester.pumpAndSettle();
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(
          c.read(routerProvider).routeInformationProvider.value.uri.path,
          '/trace/p-line',
        );
        final rect = tester.getRect(canvas);
        final points = prewritingItems[1].strokes.single.samples(50);
        Offset at(TracePoint p) =>
            rect.topLeft + Offset(p.x * rect.width, p.y * rect.height);
        finger = await tester.startGesture(at(points.first));
        for (final p in points.skip(1)) {
          await finger.moveTo(at(p));
        }
        await finger.up();
        await tester.pumpAndSettle();
        expect(c.read(traceProvider('p-line')).requireValue.done, isTrue);
        await c.read(progressRepositoryProvider).reset();
        expect(await store.read('trace-p-dot'), isNull);
        expect(await store.read('trace-p-line'), isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      },
    );
  }
}
