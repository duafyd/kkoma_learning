import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Finite book-leaf transition. Old content is never interactive or announced.
class StoryPageTurn extends StatefulWidget {
  final String pageId;
  final bool animate;
  final Widget child;
  const StoryPageTurn({
    super.key,
    required this.pageId,
    required this.animate,
    required this.child,
  });
  @override
  State<StoryPageTurn> createState() => _StoryPageTurnState();
}

class _StoryPageTurnState extends State<StoryPageTurn>
    with SingleTickerProviderStateMixin {
  late final turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: 1,
  );
  Widget? previous;
  @override
  void initState() {
    super.initState();
    turn.addStatusListener((status) {
      if (status == AnimationStatus.completed && previous != null) {
        setState(() => previous = null);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      turn.value = 1;
      previous = null;
    }
  }

  @override
  void didUpdateWidget(StoryPageTurn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      turn.value = 1;
      previous = null;
    } else if (oldWidget.pageId != widget.pageId) {
      previous = oldWidget.child;
      turn.forward(from: 0);
    }
  }

  @override
  void dispose() {
    turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: turn,
    builder: (context, _) {
      if (previous == null) return widget.child;
      final progress = Curves.easeInOutCubic.transform(turn.value);
      return IgnorePointer(
        ignoring: turn.isAnimating,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              ExcludeSemantics(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: ((1 - progress) * 10).clamp(0, 1),
                    child: Transform(
                      alignment: Alignment.centerLeft,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, .00025)
                        ..rotateY(-progress * math.pi / 2),
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: previous,
                      ),
                    ),
                  ),
                ),
              ),
              if (progress > .05 && progress < .95)
                IgnorePointer(
                  child: Align(
                    alignment: Alignment(1 - 2 * progress, 0),
                    child: FractionallySizedBox(
                      widthFactor: .06,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0x26634b33),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
