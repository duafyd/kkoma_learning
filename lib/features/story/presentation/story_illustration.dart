import 'package:flutter/material.dart';

import '../data/story_art.dart';
import 'story_character.dart';
import 'story_letter_signs.dart';
import '../domain/story_models.dart';

/// Bundled picture-book illustrations: no network requests during play.
class StoryIllustration extends StatelessWidget {
  final String background, character, companion;
  final bool animate;
  final String reactionId;
  final bool celebrate;
  final VoidCallback? onCharacterTap;
  final StoryReaction reaction;
  const StoryIllustration({
    super.key,
    required this.background,
    required this.character,
    required this.animate,
    this.companion = '루루',
    this.reactionId = '',
    this.celebrate = false,
    this.onCharacterTap,
    this.reaction = StoryReaction.greet,
  });

  static String assetFor(String background) =>
      storyArtAssets[background] ?? storyArtAssets['library']!;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$character와 $companion의 별빛 모험, $background',
    image: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: LayoutBuilder(
        builder: (context, c) {
          final train = background.startsWith('ep4-');
          final edge = (c.maxWidth * (train ? .34 : .42)).clamp(
            0.0,
            c.maxHeight * (train ? .48 : .68),
          );
          final focus = storyArtFocus(background);
          final friend = companion == character
              ? (character == '루루' ? '토토' : '루루')
              : companion;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                assetFor(background),
                key: ValueKey('$background-$character'),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment(focus.x, focus.y),
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
              if (storyLetterSigns.containsKey(background))
                StoryLetterSigns(background: background),
              Positioned(
                left: c.maxWidth * .08,
                bottom: c.maxHeight * .01,
                child: StoryCharacter(
                  key: ValueKey('speaker-$character'),
                  character: character,
                  edge: edge,
                  animate: animate,
                  celebrate: celebrate,
                  reactionId: reactionId,
                  onTap: onCharacterTap,
                  reaction: reaction,
                ),
              ),
              Positioned(
                right: c.maxWidth * .06,
                bottom: c.maxHeight * .015,
                child: StoryCharacter(
                  key: ValueKey('companion-$friend'),
                  character: friend,
                  faceLeft: true,
                  edge: edge * .88,
                  animate: animate,
                  celebrate: celebrate,
                  reactionId: reactionId,
                  onTap: onCharacterTap,
                  reaction: reaction,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
