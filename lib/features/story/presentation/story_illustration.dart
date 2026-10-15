import 'package:flutter/material.dart';

import '../data/story_art.dart';

/// Bundled picture-book illustrations: no network requests during play.
class StoryIllustration extends StatelessWidget {
  final String background, character, companion;
  final bool animate;
  const StoryIllustration({
    super.key,
    required this.background,
    required this.character,
    required this.animate,
    this.companion = '루루',
  });

  static String assetFor(String background) =>
      storyArtAssets[background] ?? storyArtAssets['library']!;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$character와 $companion의 별빛 모험, $background',
    image: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: animate ? 550 : 0),
        child: Image.asset(
          assetFor(background),
          key: ValueKey('$background-$character'),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment(character == '모아' ? .25 : -.15, .15),
          cacheWidth: 1536,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stack) => const ColoredBox(
            color: Color(0xff243e50),
            child: Center(
              child: Text(
                '그림을 불러오지 못했어요.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
