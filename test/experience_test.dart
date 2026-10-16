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
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/story/data/story_art.dart';
import 'package:flutter_application_1/features/story/presentation/story_illustration.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_canvas.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_vm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('EXPERIENCE_CAPTURE');
  setUpAll(() async {
    if (!capture) return;
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
    for (final (name, path) in [
      ('Roboto', 'C:/Windows/Fonts/malgun.ttf'),
      ('Segoe UI Emoji', 'C:/Windows/Fonts/seguiemj.ttf'),
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
  for (final (label, size) in [
    ('tablet', const Size(1280, 800)),
    ('phone', const Size(360, 780)),
    ('landscape', const Size(780, 360)),
  ]) {
    testWidgets(
      'scene play and live Hangul/English ink, cancellation and demo at $label',
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
            voiceVolume: 0,
            effectsVolume: 0,
          ),
        );
        final c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: RepaintBoundary(
              key: const ValueKey('experience-screen'),
              child: const KkomaApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (capture) {
          await tester.runAsync(() async {
            final context = tester.element(find.byType(MaterialApp));
            for (final background in ['library', 'ep1-quiet']) {
              await precacheImage(
                ResizeImage(
                  AssetImage(StoryIllustration.assetFor(background)),
                  width: 1536,
                ),
                context,
              );
            }
            for (final atlas in [storyCastAsset, storySearchCastAsset]) {
              await precacheImage(
                ResizeImage(AssetImage(atlas), width: 1024),
                context,
              );
            }
          });
          await tester.pumpAndSettle();
        }
        Future<void> photo(String page) async {
          if (!capture) return;
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('experience-screen')),
            );
            final image = await boundary.toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File('docs/screenshots/experience-$page-$label.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }

        c.read(routerProvider).go('/story');
        await tester.pumpAndSettle();
        await photo('story');
        for (var i = 0; i < 3; i++) {
          final target = find.byKey(ValueKey('scene-prop-$i'));
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await tester.tapAt(tester.getCenter(target));
          await tester.pumpAndSettle();
        }
        expect(c.read(storyProvider).requireValue.sceneFinds, [0, 1, 2]);
        await photo('restored');
        for (final (id, name) in [('h-가', 'hangul'), ('e-O', 'english')]) {
          c.read(routerProvider).go('/trace/$id');
          await tester.pumpAndSettle();
          final item = learningItems.firstWhere((i) => i.id == id);
          final paint = find
              .descendant(
                of: find.byType(TraceCanvas),
                matching: find.byType(CustomPaint),
              )
              .first;
          final rect = tester.getRect(paint);
          expect(rect.shortestSide, greaterThanOrEqualTo(180));
          Offset at(TracePoint p) =>
              rect.topLeft + Offset(p.x * rect.width, p.y * rect.height);
          final samples = item.strokes.first.samples(100);
          final pointer = await tester.startGesture(at(samples.first));
          for (final p in samples.skip(1).take(50)) {
            await pointer.moveTo(at(p));
          }
          await tester.pump();
          expect(find.text('좋아요, 길을 따라 이어 가요'), findsOneWidget);
          expect(c.read(traceProvider(id)).requireValue.strokeIndex, 0);
          await photo(name);
          await pointer.cancel();
          await tester.pumpAndSettle();
          expect(c.read(traceProvider(id)).requireValue.strokeIndex, 0);
          // A bad start must give a live cue without recording an attempt yet.
          final wrong = await tester.startGesture(
            at(const TracePoint(.95, .95)),
          );
          await tester.pump();
          expect(find.text('빛나는 시작점에서 출발해요'), findsOneWidget);
          await wrong.cancel();
          await tester.pumpAndSettle();
          final good = await tester.startGesture(at(samples.first));
          for (final p in samples.skip(1)) {
            await good.moveTo(at(p));
          }
          await good.up();
          await tester.pumpAndSettle();
          expect(c.read(traceProvider(id)).requireValue.strokeIndex, 1);
          if (id == 'h-가') {
            final state = tester.state<TraceCanvasState>(
              find.byType(TraceCanvas),
            );
            state.demonstrate();
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 700));
            expect(state.demo.isAnimating, isTrue);
            await photo('demo');
            await tester.pumpAndSettle();
            expect(state.demo.isAnimating, isFalse);
            expect(
              c.read(traceProvider(id)).requireValue.strokeIndex,
              1,
              reason: 'A demonstration cannot complete a stroke',
            );
          }
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      },
    );
  }
}
