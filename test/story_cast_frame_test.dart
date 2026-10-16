import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/story/data/story_art.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_cast_frame.dart';
import 'package:flutter_application_1/features/story/presentation/story_character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'atlas has genuine transparency and sixteen valid source frames',
    (tester) async {
      await tester.runAsync(() async {
        final data = await rootBundle.load(storyMotionCastAsset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        try {
          final pixels = (await frame.image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
          var transparent = 0;
          for (var i = 3; i < pixels.length; i += 4) {
            if (pixels[i] == 0) transparent++;
          }
          expect(
            transparent / (frame.image.width * frame.image.height),
            greaterThan(.25),
          );
          final imageSize = Size(
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          );
          final rects = [
            for (final character in storyCharacterCells.keys)
              for (final pose in CastPose.values)
                castFrameRect(imageSize, character, pose),
          ];
          expect(rects.toSet().length, 16);
          for (final rect in rects) {
            expect(rect.shortestSide, greaterThan(200));
            expect(
              rect.left >= 0 &&
                  rect.top >= 0 &&
                  rect.right <= imageSize.width &&
                  rect.bottom <= imageSize.height,
              isTrue,
            );
          }
        } finally {
          frame.image.dispose();
          codec.dispose();
        }
      });
    },
  );
  testWidgets(
    'real steps change with journey; background, reduced motion and restore stay still',
    (tester) async {
      var progress = .1, animate = true;
      Widget actor({bool reduced = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Center(
            child: StoryCharacter(
              character: '루루',
              edge: 240,
              animate: animate,
              reaction: StoryReaction.celebrate,
              travelProgress: progress,
            ),
          ),
        ),
      );
      CastPose pose() =>
          tester.widget<StoryCastFrame>(find.byType(StoryCastFrame)).pose;
      await tester.pumpWidget(actor());
      await tester.pump(const Duration(milliseconds: 100));
      expect(pose(), CastPose.stepB);
      progress = .2;
      await tester.pumpWidget(actor());
      expect(pose(), CastPose.stepA);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(pose(), CastPose.idle);
      animate = false;
      await tester.pumpWidget(actor());
      expect(pose(), CastPose.idle);
      await tester.pumpWidget(const SizedBox.shrink());
      animate = true;
      progress = 1;
      await tester.pumpWidget(actor(reduced: true));
      await tester.pumpAndSettle();
      expect(pose(), CastPose.idle);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'all frame cuts render without neighboring actors or missing assets',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: const ValueKey('atlas-review'),
            child: ColoredBox(
              color: const Color(0xff365649),
              child: Column(
                children: [
                  for (final character in storyCharacterCells.keys)
                    Expanded(
                      child: Row(
                        children: [
                          for (final pose in CastPose.values)
                            Expanded(
                              child: StoryCastFrame(
                                character: character,
                                pose: pose,
                                edge: 240,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          const ResizeImage(AssetImage(storyMotionCastAsset), width: 1024),
          tester.element(find.byType(MaterialApp)),
        );
      });
      await tester.pumpAndSettle();
      if (const bool.fromEnvironment('CAST_CAPTURE')) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('atlas-review')),
              )
              .toImage();
          try {
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File('docs/screenshots/cast-motion-review.png')
                .writeAsBytes(data!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
      expect(find.byType(StoryCastFrame), findsNWidgets(16));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
