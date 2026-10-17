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
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/progress/data/progress_repository.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_canvas.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_vm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('CHIEUT_CAPTURE');
  setUpAll(() async {
    if (capture) {
      await (FontLoader(
        'Jua',
      )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
    }
  });
  final first = tracePaths['ㅊ']!.first;
  test('short mark allowance stays bounded and does not widen long or curved guides', () {
    for (final age in [2, 3, 4, 5]) {
      final strategy = TraceStrategy(AgeStrategy(age));
      expect(strategy.toleranceFor(first), closeTo(.05, .000001));
      expect(
        strategy.toleranceFor(first),
        lessThanOrEqualTo(first.length * .4),
      );
      expect(
        strategy.toleranceFor(tracePaths['ㅊ']![1]),
        closeTo([.192, .16, .10, .075][age - 2], .000001),
      );
      expect(
        strategy.toleranceFor(tracePaths['C']!.single),
        AgeStrategy(age).traceTolerance,
      );
    }
  });
  for (final age in [2, 3, 4, 5]) {
    final strategy = TraceStrategy(AgeStrategy(age));
    test(
      'age $age accepts a small finger offset on the short chieut stroke',
      () {
        final offset = first
            .samples(20)
            .map((p) => TracePoint(p.x + .03, p.y))
            .toList();
        expect(strategy.evaluate(first, offset).accepted, true);
        final overshoot = [
          first.points.first,
          TracePoint(first.points.last.x, first.points.last.y + .025),
        ];
        expect(strategy.evaluate(first, overshoot).accepted, true);
      },
    );
    test(
      'age $age still rejects taps, fragments, cross strokes and repeated scribbles',
      () {
        final guide = first.samples(80);
        for (final input in [
          [first.points.first],
          guide.take(10).toList(),
          [const TracePoint(.43, .215), const TracePoint(.57, .215)],
          [...guide, ...guide.reversed, ...guide],
          guide.map((p) => TracePoint(p.x + .07, p.y)).toList(),
        ]) {
          expect(strategy.evaluate(first, input).accepted, false);
        }
        if (age >= 4) {
          expect(
            strategy.evaluate(first, guide.reversed.toList()).accepted,
            false,
          );
        }
      },
    );
  }
  for (final (label, size) in [
    ('phone', const Size(360, 780)),
    ('landscape', const Size(780, 360)),
    ('tablet', const Size(1280, 800)),
  ]) {
    testWidgets(
      'short chieut touch, partial rejection and saved resume on $label',
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
          UncontrolledProviderScope(
            container: c,
            child: RepaintBoundary(
              key: const ValueKey('chieut-screen'),
              child: const KkomaApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        c.read(routerProvider).go('/trace/h-ㅊ');
        await tester.pumpAndSettle();
        final paint = find
            .descendant(
              of: find.byType(TraceCanvas),
              matching: find.byType(CustomPaint),
            )
            .first;
        final rect = tester.getRect(paint);
        expect(rect.shortestSide, greaterThanOrEqualTo(180));
        if (capture) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('chieut-screen')),
            );
            final image = await boundary.toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File('docs/screenshots/chieut-first-$label.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
        Future<void> draw(List<TracePoint> points) async {
          Offset at(TracePoint p) =>
              rect.topLeft + Offset(p.x * rect.width, p.y * rect.height);
          final gesture = await tester.startGesture(at(points.first));
          for (final point in points.skip(1)) {
            await gesture.moveTo(at(point));
          }
          await gesture.up();
          await tester.pumpAndSettle();
        }

        await draw([first.points.first]);
        expect(c.read(traceProvider('h-ㅊ')).requireValue.strokeIndex, 0);
        await draw(first.samples(80).take(10).toList());
        expect(c.read(traceProvider('h-ㅊ')).requireValue.strokeIndex, 0);
        await draw(
          first.samples(20).map((p) => TracePoint(p.x + .03, p.y)).toList(),
        );
        expect(c.read(traceProvider('h-ㅊ')).requireValue.strokeIndex, 1);
        expect(c.read(traceProvider('h-ㅊ')).requireValue.done, false);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        final restored = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
        final sub = restored.listen(traceProvider('h-ㅊ'), (_, _) {});
        try {
          final state = await restored.read(traceProvider('h-ㅊ').future);
          expect(state.strokeIndex, 1);
          expect(state.completed.length, 1);
          for (final stroke in tracePaths['ㅊ']!.skip(1)) {
            await restored
                .read(traceProvider('h-ㅊ').notifier)
                .submit(stroke.samples(20), 5);
          }
          expect(restored.read(traceProvider('h-ㅊ')).requireValue.done, true);
          expect(
            (await ProgressRepository(store).load())['trace-h-ㅊ']['successes'],
            1,
          );
        } finally {
          sub.close();
          restored.dispose();
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
