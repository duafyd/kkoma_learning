import 'package:flutter/material.dart';

import 'drawing.dart';
import 'drawing_stamps.dart';

class DrawingPainter extends CustomPainter {
  final DrawingDocument document;
  final DrawingLine? current;
  const DrawingPainter(this.document, {this.current});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Color(document.background), BlendMode.src);
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final line in [...document.lines, ?current]) {
      if (line.points.isEmpty) continue;
      Offset p(int i) =>
          Offset(line.points[i].x * size.width, line.points[i].y * size.height);
      if (line.stamp != null) {
        final edge = size.shortestSide * .12;
        canvas.save();
        canvas.translate(p(0).dx - edge / 2, p(0).dy - edge / 2);
        DrawingStampPainter(
          line.stamp!,
          Color(line.color),
        ).paint(canvas, Size.square(edge));
        canvas.restore();
        continue;
      }
      final paint = Paint()
        ..color = Color(line.color)
        ..strokeWidth = line.width * size.shortestSide
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (line.eraser) paint.blendMode = BlendMode.clear;
      if (line.points.length == 1) {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(p(0), paint.strokeWidth / 2, paint);
      } else {
        final path = Path()..moveTo(p(0).dx, p(0).dy);
        for (var i = 1; i < line.points.length; i++) {
          path.lineTo(p(i).dx, p(i).dy);
        }
        canvas.drawPath(path, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
