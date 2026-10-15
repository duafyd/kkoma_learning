import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/story_art.dart';
import '../domain/story_models.dart';

/// A separate transparent paper puppet, not a moving crop of the background.
class StoryCharacter extends StatefulWidget {
  final String character, reactionId;
  final double edge;
  final bool animate, celebrate, faceLeft;
  final VoidCallback? onTap;
  final StoryReaction reaction;
  const StoryCharacter({
    super.key,
    required this.character,
    required this.edge,
    required this.animate,
    this.celebrate = false,
    this.faceLeft = false,
    this.reactionId = '',
    this.onTap,
    this.reaction = StoryReaction.greet,
  });
  @override
  State<StoryCharacter> createState() => _StoryCharacterState();
}

class _StoryCharacterState extends State<StoryCharacter>
    with SingleTickerProviderStateMixin {
  late final movement = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  @override
  void initState() {
    super.initState();
    if (widget.animate) movement.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      movement.value = 1;
    }
  }

  @override
  void didUpdateWidget(StoryCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      movement.value = 1;
    } else if (oldWidget.character != widget.character ||
        oldWidget.reactionId != widget.reactionId ||
        oldWidget.reaction != widget.reaction) {
      movement.forward(from: 0);
    }
  }

  @override
  void dispose() {
    movement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = switch (storyCharacterCells[widget.character]) {
      0 => Alignment.topLeft,
      1 => Alignment.topRight,
      3 => Alignment.bottomRight,
      _ => Alignment.bottomLeft,
    };
    final sprite = SizedBox(
      width: widget.edge,
      height: widget.edge,
      child: ClipRect(
        child: OverflowBox(
          alignment: alignment,
          minWidth: widget.edge * 2,
          maxWidth: widget.edge * 2,
          minHeight: widget.edge * 2,
          maxHeight: widget.edge * 2,
          child: Image.asset(
            widget.reaction == StoryReaction.search ||
                    widget.reaction == StoryReaction.point
                ? storySearchCastAsset
                : storyCastAsset,
            width: widget.edge * 2,
            height: widget.edge * 2,
            fit: BoxFit.fill,
            cacheWidth: 1024,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) =>
                const Center(child: Icon(Icons.auto_awesome_rounded)),
          ),
        ),
      ),
    );
    return Semantics(
      label: '${widget.character}에게 인사하기',
      button: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.animate &&
                    !MediaQuery.disableAnimationsOf(context)) {
                  movement.forward(from: 0);
                }
                widget.onTap!();
              },
        child: AnimatedBuilder(
          animation: movement,
          child: Transform.flip(flipX: widget.faceLeft, child: sprite),
          builder: (context, child) {
            final animate =
                widget.animate && !MediaQuery.disableAnimationsOf(context);
            final t = animate ? movement.value : 1.0;
            final wave =
                math.sin(
                  t *
                      math.pi *
                      (widget.reaction == StoryReaction.search ? 3 : 2),
                ) *
                (1 - t);
            final celebrating =
                widget.celebrate || widget.reaction == StoryReaction.celebrate;
            final hop = celebrating ? math.sin(t * math.pi) * 12 : wave * 6;
            return Transform.translate(
              offset: Offset(
                (1 - t) * widget.edge * .18 * (widget.faceLeft ? 1 : -1),
                -hop,
              ),
              child: Transform.rotate(
                angle: wave * .055,
                child: Transform.scale(
                  scale: celebrating ? 1 + math.sin(t * math.pi) * .07 : 1,
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
