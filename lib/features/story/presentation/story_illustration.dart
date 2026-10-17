import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/story_art.dart';
import 'story_character.dart';
import 'story_letter_signs.dart';
import '../domain/story_models.dart';
import '../domain/scene_play.dart';
import 'scene_play_stage.dart';
import '../domain/world_mission.dart';
import 'world_mission_stage.dart';
import 'world_mission_layout.dart';
import '../domain/letter_mission.dart';
import 'letter_mission_stage.dart';
import '../domain/book_mission.dart';
import 'book_mission_stage.dart';
import '../domain/story_quest.dart';
import 'story_quest_stage.dart';
import '../../drawing/domain/drawing.dart';
import '../../drawing/domain/drawing_renderer.dart';

/// Bundled picture-book illustrations: no network requests during play.
class StoryIllustration extends StatefulWidget {
  final String background, character, companion;
  final bool animate;
  final String reactionId;
  final bool celebrate;
  final VoidCallback? onCharacterTap;
  final StoryReaction reaction;
  final ScenePlay? scenePlay;
  final int playCount;
  final List<int> sceneFinds;
  final ValueChanged<int>? onDiscover;
  final bool active;
  final WorldMission? worldMission;
  final List<int> missionPlaced;
  final bool missionSolved;
  final Future<void> Function(int, int)? onPlace;
  final LetterMission? letterMission;
  final Future<void> Function(int)? onChoose;
  final BookMission? bookMission;
  final Future<void> Function(int)? onObserve;
  final DrawingDocument? gardenMap;
  final StoryQuest? quest;
  final VoidCallback? onCollect;
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
    this.scenePlay,
    this.playCount = 0,
    this.sceneFinds = const [],
    this.onDiscover,
    this.active = true,
    this.worldMission,
    this.missionPlaced = const [],
    this.missionSolved = false,
    this.onPlace,
    this.letterMission,
    this.onChoose,
    this.bookMission,
    this.onObserve,
    this.gardenMap,
    this.quest,
    this.onCollect,
  });

  static String assetFor(String background) =>
      storyArtAssets[background] ?? storyArtAssets['library']!;

  @override
  State<StoryIllustration> createState() => _StoryIllustrationState();
}

class _StoryIllustrationState extends State<StoryIllustration> {
  late final journey = ValueNotifier<double>(widget.missionSolved ? 1 : 0);
  late final restoredMission =
      (widget.worldMission != null && widget.missionSolved) ||
      (widget.bookMission?.solved ?? false) ||
      (widget.letterMission?.solved ?? false);
  @override
  void dispose() {
    journey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StoryIllustration(
      :background,
      :character,
      :companion,
      :animate,
      :reactionId,
      :celebrate,
      :onCharacterTap,
      :reaction,
      :scenePlay,
      :playCount,
      :sceneFinds,
      :onDiscover,
      :active,
      :worldMission,
      :missionPlaced,
      :missionSolved,
      :onPlace,
      :letterMission,
      :onChoose,
      :bookMission,
      :onObserve,
      :gardenMap,
    ) = widget;
    final actorMotion = animate && !restoredMission;
    return Semantics(
      label: '$character와 $companion의 별빛 모험, $background',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: LayoutBuilder(
          builder: (context, c) {
            final train = background.startsWith('ep4-');
            final edge =
                (c.maxWidth *
                        (worldMission != null
                            ? .22
                            : letterMission != null || bookMission != null
                            ? .28
                            : train
                            ? .34
                            : .42))
                    .clamp(
                      0.0,
                      c.maxHeight *
                          (widget.quest != null && scenePlay != null
                              ? .36
                              : worldMission != null
                              ? .25
                              : letterMission != null || bookMission != null
                              ? .5
                              : train
                              ? .48
                              : .68),
                    );
            final focus = storyArtFocus(background);
            final friend = companion == character
                ? (character == '루루' ? '토토' : '루루')
                : companion;
            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: Duration(
                    milliseconds:
                        animate &&
                            active &&
                            !MediaQuery.disableAnimationsOf(context) &&
                            (letterMission != null || bookMission != null)
                        ? 1000
                        : 0,
                  ),
                  child: Image.asset(
                    StoryIllustration.assetFor(background),
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
                ),
                if (worldMission?.bridge == true && missionPlaced.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipPath(
                        clipper: _RestoredStones(missionPlaced.length),
                        child: Image.asset(
                          StoryIllustration.assetFor('ep6-built'),
                          fit: BoxFit.cover,
                          alignment: Alignment(focus.x, focus.y),
                          cacheWidth: 1536,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  ),
                if (storyLetterSigns.containsKey(background) &&
                    !(letterMission != null &&
                        !letterMission.tracing &&
                        [
                          LetterWorld.seedTree,
                          LetterWorld.soundTrain,
                        ].contains(letterMission.world) &&
                        !letterMission.solved))
                  StoryLetterSigns(background: background),
                if (scenePlay != null && onDiscover != null)
                  Positioned(
                    left: 0,
                    right: widget.quest != null ? c.maxWidth * .24 : 0,
                    bottom: 0,
                    top: widget.quest != null ? 55 : 0,
                    child: ScenePlayStage(
                      key: ValueKey(
                        'scene-play-${scenePlay.kind.name}-$playCount',
                      ),
                      play: scenePlay,
                      count: playCount,
                      found: sceneFinds,
                      animate: animate,
                      active: active,
                      onDiscover: onDiscover,
                    ),
                  ),
                Positioned(
                  left: c.maxWidth * .08,
                  bottom: c.maxHeight * (worldMission != null ? .24 : .01),
                  child: StoryCharacter(
                    key: ValueKey('speaker-$character'),
                    character: character,
                    edge: edge,
                    animate: actorMotion,
                    celebrate: celebrate,
                    reactionId: reactionId,
                    onTap: worldMission != null ? null : onCharacterTap,
                    reaction: reaction,
                  ),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: journey,
                  builder: (context, progress, child) => Positioned(
                    right: worldMission != null ? null : c.maxWidth * .06,
                    left: worldMission != null
                        ? c.maxWidth * (.03 + progress * .72)
                        : null,
                    bottom:
                        c.maxHeight *
                        (worldMission != null
                            ? (worldMission.bridge ? .48 : .55) +
                                  progress * .05 +
                                  math.sin(progress * math.pi) * .015
                            : .015),
                    child: StoryCharacter(
                      key: ValueKey('companion-$friend'),
                      character: friend,
                      faceLeft: worldMission == null,
                      edge: edge * .88,
                      travelProgress: worldMission != null ? progress : null,
                      animate: actorMotion,
                      celebrate: celebrate,
                      reactionId: reactionId,
                      onTap: worldMission != null ? null : onCharacterTap,
                      reaction: reaction,
                    ),
                  ),
                ),
                if (worldMission != null && onPlace != null)
                  Positioned.fill(
                    child: WorldMissionStage(
                      key: ValueKey(
                        'world-mission-${worldMission.artwork.arrangement.name}',
                      ),
                      mission: worldMission,
                      placed: missionPlaced,
                      solved: missionSolved,
                      animate: animate,
                      active: active,
                      onPlace: onPlace,
                      onJourney: (p) => journey.value = p,
                    ),
                  ),
                if (letterMission != null)
                  Positioned.fill(
                    child: LetterMissionStage(
                      key: ValueKey(
                        'letter-${letterMission.world}-${letterMission.tracing}',
                      ),
                      mission: letterMission,
                      animate: animate,
                      active: active,
                      onChoose: onChoose,
                    ),
                  ),
                if (bookMission != null)
                  Positioned.fill(
                    child: BookMissionStage(
                      key: ValueKey(
                        'book-${bookMission.sceneId}-${bookMission.quiz?.id ?? 'trace'}',
                      ),
                      mission: bookMission,
                      animate: animate,
                      active: active,
                      onAnswer: onChoose,
                      onObserve: onObserve,
                    ),
                  ),
                if (gardenMap != null)
                  Positioned(
                    right: c.maxWidth * .08,
                    top: c.maxHeight * .08,
                    width: c.maxWidth * .5,
                    height: c.maxHeight * .52,
                    child: Semantics(
                      label: '내가 그린 정원 지도',
                      image: true,
                      child: Container(
                        key: const ValueKey('saved-garden-map'),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xffffdf9b),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xffad7b42),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x553e3424),
                              blurRadius: 10,
                              offset: Offset(3, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CustomPaint(
                            painter: DrawingPainter(gardenMap),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.quest != null)
                  Positioned.fill(
                    child: StoryQuestStage(
                      quest: widget.quest!,
                      animate: animate,
                      active: active,
                      onCollect: widget.onCollect ?? () {},
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RestoredStones extends CustomClipper<Path> {
  final int count;
  const _RestoredStones(this.count);
  @override
  Path getClip(Size size) {
    final layout = WorldMissionLayout(size, 3, true);
    final path = Path();
    for (var i = 0; i < count.clamp(0, 3); i++) {
      path.addOval(layout.restoration(i));
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _RestoredStones oldClipper) =>
      count != oldClipper.count;
}
