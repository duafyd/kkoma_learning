import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/story/data/story_art.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('character atlas has four usable transparent cells and every speaker is mapped', () async {
    for (final scene in storyEpisodes.expand((e) => e.scenes)) {
      expect(
        storyCharacterCells.containsKey(scene.character),
        true,
        reason: scene.id,
      );
    }
    expect(storyCharacterCells.values.toSet(), {0, 1, 2, 3});
    for (final atlas in [storyCastAsset, storySearchCastAsset]) {
      final bytes = await rootBundle.load(atlas);
      final codec = await instantiateImageCodec(bytes.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      expect(image.width % 2, 0);
      expect(image.height, image.width);
      final pixels = (await image.toByteData())!;
      if (atlas == storySearchCastAsset) {
        // Keep a clear central gutter so a puppet cannot include its neighbour.
        var crossed = 0;
        for (var y = 0; y < image.height; y += 4) {
          for (var x = 0; x < image.width; x += 4) {
            if ((x - image.width / 2).abs() < image.width * .025 ||
                (y - image.height / 2).abs() < image.height * .025) {
              if (pixels.getUint8((y * image.width + x) * 4 + 3) > 240) {
                crossed++;
              }
            }
          }
        }
        expect(crossed, 0, reason: 'search poses stay inside their own cell');
      }
      for (var cell = 0; cell < 4; cell++) {
        final left = (cell % 2) * image.width ~/ 2,
            top = (cell ~/ 2) * image.height ~/ 2;
        var transparent = 0, solid = 0;
        for (var y = top; y < top + image.height ~/ 2; y += 8) {
          for (var x = left; x < left + image.width ~/ 2; x += 8) {
            final alpha = pixels.getUint8((y * image.width + x) * 4 + 3);
            if (alpha < 10) transparent++;
            if (alpha > 240) solid++;
          }
        }
        expect(
          transparent,
          greaterThan(100),
          reason: 'cell $cell transparent border',
        );
        expect(solid, greaterThan(100), reason: 'cell $cell character');
      }
      image.dispose();
      codec.dispose();
    }
  });
  test('all story backgrounds map to bundled decodable PNG assets', () async {
    for (final scene in storyEpisodes.expand((e) => e.scenes)) {
      expect(
        storyArtAssets.containsKey(scene.background),
        true,
        reason: scene.id,
      );
      if (scene.successBackground != null) {
        expect(
          storyArtAssets.containsKey(scene.successBackground),
          true,
          reason: '${scene.id} success',
        );
      }
    }
    for (final asset in storyArtAssets.values.toSet()) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.buffer.asUint8List().take(8), [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ]);
      final codec = await instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThanOrEqualTo(1200));
      frame.image.dispose();
      codec.dispose();
    }
  });
}
