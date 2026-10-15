import 'dart:math' as math;

import 'package:flutter/material.dart';

class StoryIllustration extends StatelessWidget {
  final String background, character;
  final bool animate;
  final String companion;
  const StoryIllustration({
    super.key,
    required this.background,
    required this.character,
    required this.animate,
    this.companion = '루루',
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$character와 $companion, 별빛 $background',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$background-$character'),
        tween: Tween(begin: animate ? 0 : 1, end: 1),
        duration: Duration(milliseconds: animate ? 600 : 0),
        builder: (context, v, _) => CustomPaint(
          painter: _BookPainter(background, character, v),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _BookPainter extends CustomPainter {
  final String background, character;
  final double reveal;
  _BookPainter(this.background, this.character, this.reveal);
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 800, sy = size.height / 400;
    canvas.save();
    canvas.scale(sx, sy);
    final sky = background == 'rain'
        ? const Color(0xffc6d8e4)
        : background == 'sky'
        ? const Color(0xffb9cedc)
        : const Color(0xffd8eae0);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 800, 400), Paint()..color = sky);
    canvas.drawOval(
      const Rect.fromLTWH(-100, 290, 1000, 220),
      Paint()..color = const Color(0xff98bca4),
    );
    void rect(Rect r, Color color) => canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(10)),
      Paint()..color = color,
    );
    void circle(Offset p, double r, Color c) =>
        canvas.drawCircle(p, r, Paint()..color = c);
    for (var i = 0; i < 7; i++) {
      circle(
        Offset(80 + i * 106, 50 + (i % 3) * 28),
        5,
        Color.lerp(sky, const Color(0xffffe5a0), reveal)!,
      );
    }
    if (background == 'library') {
      rect(const Rect.fromLTWH(245, 105, 310, 220), const Color(0xffac8056));
      rect(const Rect.fromLTWH(260, 120, 280, 195), const Color(0xfff1dcc1));
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 9; col++) {
          rect(
            Rect.fromLTWH(272 + col * 29, 134 + row * 57, 20, 42),
            [
              const Color(0xff63998c),
              const Color(0xffdcae62),
              const Color(0xffad88a6),
            ][(row + col) % 3],
          );
        }
      }
    } else if (['forest', 'garden', 'rain'].contains(background)) {
      for (var i = 0; i < 5; i++) {
        rect(
          Rect.fromLTWH(85 + i * 155, 180, 16, 150),
          const Color(0xff97704c),
        );
        circle(Offset(95 + i * 155, 170), 48, const Color(0xff699f79));
        if (background == 'garden') {
          circle(Offset(110 + i * 150, 324), 16, const Color(0xffedb863));
          circle(Offset(104 + i * 150, 324), 6, const Color(0xfffaedd3));
        }
      }
      if (background == 'rain') {
        for (var i = 0; i < 22; i++) {
          canvas.drawLine(
            Offset(i * 40.0, 80 + (i % 4) * 35.0),
            Offset(i * 40.0 - 8, 100 + (i % 4) * 35.0),
            Paint()
              ..color = const Color(0xff81a1b2)
              ..strokeWidth = 3,
          );
        }
      }
    } else if (background == 'lighthouse') {
      rect(const Rect.fromLTWH(350, 120, 100, 205), const Color(0xfffaf0d8));
      rect(const Rect.fromLTWH(340, 95, 120, 45), const Color(0xff729387));
      circle(const Offset(400, 117), 16, const Color(0xffffd774));
    } else if (background == 'bridge') {
      rect(const Rect.fromLTWH(0, 235, 800, 90), const Color(0xff96bacd));
      for (var i = 0; i < 6; i++) {
        rect(Rect.fromLTWH(160 + i * 85, 260, 70, 36), const Color(0xffe4d5b4));
      }
    } else if (background == 'train') {
      for (var i = 0; i < 3; i++) {
        rect(
          Rect.fromLTWH(210 + i * 125, 175, 115, 90),
          const Color(0xffdfb170),
        );
        circle(Offset(238 + i * 125, 275), 18, const Color(0xff526a65));
        circle(Offset(292 + i * 125, 275), 18, const Color(0xff526a65));
      }
    }
    // Original vector silhouettes reused across every chapter.
    final x = character == '모아'
        ? 150.0
        : character == '루루'
        ? 200.0
        : character == '토토'
        ? 620.0
        : 650.0;
    final y = 300.0 - math.sin(reveal * math.pi) * 8;
    if (character == '루루') {
      final ears = Path()
        ..moveTo(x - 35, y - 30)
        ..lineTo(x - 28, y - 90)
        ..lineTo(x, y - 55)
        ..lineTo(x + 28, y - 90)
        ..lineTo(x + 35, y - 30)
        ..close();
      canvas.drawPath(ears, Paint()..color = const Color(0xffd99059));
      circle(Offset(x, y - 25), 44, const Color(0xffd99059));
      circle(Offset(x, y - 10), 25, const Color(0xffffe9c9));
    } else if (character == '토토') {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 115, height: 72),
        Paint()..color = const Color(0xff638b63),
      );
      circle(Offset(x - 55, y - 20), 26, const Color(0xffabc68f));
    } else if (character == '휙휙') {
      for (var i = 0; i < 3; i++) {
        circle(
          Offset(x - 25 + i * 25, y - 30 - (i % 2) * 12),
          25,
          const Color(0xfff7f9ed),
        );
      }
    } else {
      circle(Offset(x, y - 35), 34, const Color(0xfff7dda2));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y + 9), width: 72, height: 70),
        Paint()..color = const Color(0xffbc9cca),
      );
    }
    final eyeX = character == '토토' ? x - 55 : x;
    circle(Offset(eyeX - 11, y - 32), 3, const Color(0xff3e504b));
    circle(Offset(eyeX + 11, y - 32), 3, const Color(0xff3e504b));
    canvas.drawArc(
      Rect.fromCenter(center: Offset(eyeX, y - 20), width: 17, height: 13),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xff3e504b)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BookPainter old) =>
      old.reveal != reveal ||
      old.background != background ||
      old.character != character;
}
