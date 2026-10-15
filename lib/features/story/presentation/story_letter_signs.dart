import 'package:flutter/material.dart';

import '../data/story_art.dart';

/// Paint onto the original blank plaques using the background's cover crop.
class StoryLetterSigns extends StatelessWidget {
  final String background;
  const StoryLetterSigns({super.key, required this.background});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(child: CustomPaint(painter: _Signs(background))),
  );
}

class _Signs extends CustomPainter {
  final String background;
  _Signs(this.background);
  @override
  void paint(Canvas canvas, Size size) {
    const sourceSize = Size(1536, 1024);
    final fitted = applyBoxFit(BoxFit.cover, sourceSize, size);
    final focus = storyArtFocus(background);
    final alignment = Alignment(focus.x, focus.y);
    final source = alignment.inscribe(fitted.source, Offset.zero & sourceSize);
    final destination = alignment.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final scale = destination.width / source.width;
    for (final sign in storyLetterSigns[background] ?? const []) {
      final label = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: sign.text,
          style: TextStyle(
            fontFamily: 'Jua',
            fontSize:
                (background == 'ep3-tree'
                    ? 48
                    : background == 'ep2-open'
                    ? 64
                    : 76) *
                scale,
            height: 1,
            color: const Color(0xff65492e),
          ),
        ),
      )..layout();
      final center = Offset(
        destination.left + (sign.x * sourceSize.width - source.left) * scale,
        destination.top + (sign.y * sourceSize.height - source.top) * scale,
      );
      label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
      label.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _Signs oldDelegate) =>
      oldDelegate.background != background;
}
