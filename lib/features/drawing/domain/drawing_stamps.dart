import 'dart:math' as math;

import 'package:flutter/material.dart';

const drawingStamps = [
  ('flower', '꽃'),
  ('butterfly', '나비'),
  ('star', '별'),
  ('circle', '동그라미'),
  ('triangle', '세모'),
];

/// Saved named/legacy stamps share a font-independent renderer, also used in PNG.
class DrawingStampPainter extends CustomPainter {
  final String stamp;
  final Color color;
  const DrawingStampPainter(this.stamp, this.color);
  @override
  void paint(Canvas c, Size size) {
    final center = Offset(size.width / 2, size.height / 2),
        r = size.shortestSide * .43;
    final path = Path();
    switch (stamp) {
      case 'flower' || '🌼':
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          path.addOval(
            Rect.fromCircle(
              center: center + Offset(math.cos(a), math.sin(a)) * r * .58,
              radius: r * .43,
            ),
          );
        }
      case 'butterfly' || '🦋':
        for (final side in [-1, 1]) {
          path.addOval(
            Rect.fromCenter(
              center: center + Offset(side * r * .48, -r * .3),
              width: r,
              height: r * 1.1,
            ),
          );
          path.addOval(
            Rect.fromCenter(
              center: center + Offset(side * r * .4, r * .4),
              width: r * .78,
              height: r * .8,
            ),
          );
        }
      case 'circle' || '●':
        path.addOval(Rect.fromCircle(center: center, radius: r));
      default:
        final star = stamp == 'star' || stamp == '⭐';
        final n = star ? 10 : 3;
        for (var i = 0; i < n; i++) {
          final a = -math.pi / 2 + i * math.pi * 2 / n;
          final radius = star && i.isOdd ? r * .48 : r;
          final p = center + Offset(math.cos(a), math.sin(a)) * radius;
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
    }
    c.drawShadow(path, const Color(0x553c4533), 2, true);
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [Color.lerp(color, Colors.white, .35)!, color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
    c.drawPath(
      path,
      Paint()
        ..color = Color.lerp(color, const Color(0xff3c4533), .3)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    if (stamp == 'flower' || stamp == '🌼') {
      c.drawCircle(center, r * .29, Paint()..color = const Color(0xffffd579));
    }
    if (stamp == 'butterfly' || stamp == '🦋') {
      c.drawLine(
        center - Offset(0, r * .6),
        center + Offset(0, r * .7),
        Paint()
          ..color = const Color(0xff5f593c)
          ..strokeWidth = r * .18
          ..strokeCap = StrokeCap.round,
      );
      c.drawCircle(
        center - Offset(0, r * .64),
        r * .15,
        Paint()..color = const Color(0xff5f593c),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DrawingStampPainter old) =>
      old.stamp != stamp || old.color != color;
}

class DrawingStampPicture extends StatelessWidget {
  final String stamp;
  final Color color;
  final double edge;
  const DrawingStampPicture({
    super.key,
    required this.stamp,
    required this.color,
    this.edge = 40,
  });
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(edge),
    painter: DrawingStampPainter(stamp, color),
  );
}
