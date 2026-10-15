import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/story/data/story_art.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all story backgrounds map to bundled decodable PNG assets', () async {
    for (final scene in storyEpisodes.expand((e) => e.scenes)) {
      expect(
        storyArtAssets.containsKey(scene.background),
        true,
        reason: scene.id,
      );
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
