import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';

// Run explicitly with flutter test tool/tracing_preview_test.dart.
// This exports original path data for visual review, not a golden acceptance test.
void main() {
  test('export tracing review sheet', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = File('C:/Windows/Fonts/malgun.ttf');
    if (font.existsSync()) {
      await (FontLoader('ReviewLabels')..addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          ))
          .load();
    }
    final items = learningItems.where((i) => i.strokes.isNotEmpty).toList();
    const columns = 10, cell = 140.0;
    final rows = (items.length / columns).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.white, BlendMode.src);
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.deepOrange,
      Colors.purple,
    ];
    for (var i = 0; i < items.length; i++) {
      canvas.save();
      canvas.translate(i % columns * cell, i ~/ columns * cell);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, cell, cell),
        Paint()
          ..color = Colors.black12
          ..style = PaintingStyle.stroke,
      );
      final label = TextPainter(
        text: TextSpan(
          text: '${items[i].symbol} · ${items[i].strokes.length}획',
          style: const TextStyle(
            fontFamily: 'ReviewLabels',
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, const Offset(8, 2));
      canvas.translate(10, 25);
      for (var s = 0; s < items[i].strokes.length; s++) {
        final points = items[i].strokes[s].points;
        final path = Path()..moveTo(points.first.x * 120, points.first.y * 105);
        for (final p in points.skip(1)) {
          path.lineTo(p.x * 120, p.y * 105);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = colors[s % colors.length]
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          Offset(points.first.x * 120, points.first.y * 105),
          3,
          Paint()..color = Colors.red,
        );
      }
      canvas.restore();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (columns * cell).toInt(),
      (rows * cell).toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('docs/tracing_preview.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
}
