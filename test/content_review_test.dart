import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/tracing/data/trace_catalog.dart';
import 'package:flutter_application_1/features/tracing/data/prewriting_content.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all 128 guides have finite in-canvas ink and reject incomplete/cross-canvas shortcuts', () {
    expect(traceItems.length, 128);
    for (final item in traceItems) {
      for (var index = 0; index < item.strokes.length; index++) {
        final path = item.strokes[index];
        final reason = '${item.id} stroke ${index + 1}';
        expect(path.length, greaterThan(0), reason: reason);
        for (final p in path.points) {
          expect(
            p.x.isFinite &&
                p.y.isFinite &&
                p.x >= 0 &&
                p.x <= 1 &&
                p.y >= 0 &&
                p.y <= 1,
            isTrue,
            reason: reason,
          );
        }
        for (var age = 2; age <= 5; age++) {
          final strategy = item.subject == 'prewriting'
              ? PrewritingStrategy(AgeStrategy(age))
              : TraceStrategy(AgeStrategy(age));
          final samples = path.samples(100);
          expect(
            strategy.evaluate(path, samples).accepted,
            isTrue,
            reason: '$reason age $age',
          );
          expect(
            strategy.evaluate(path, const [
              TracePoint(.05, .05),
              TracePoint(.95, .95),
              TracePoint(.05, .95),
              TracePoint(.95, .05),
            ]).accepted,
            isFalse,
            reason: '$reason scribble age $age',
          );
          if (!strategy.acceptsTap(path)) {
            expect(
              strategy.evaluate(path, samples.take(35).toList()).accepted,
              isFalse,
              reason: '$reason partial age $age',
            );
            expect(
              strategy.evaluate(path, [samples.first, samples.first]).accepted,
              isFalse,
              reason: '$reason tap age $age',
            );
          }
        }
      }
    }
  });
  test('export complete numbered visual/coordinate review pack without claiming expert approval', () async {
    if (!const bool.fromEnvironment('REVIEW_EXPORT')) return;
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
    final directory = Directory('docs/review')..createSync(recursive: true);
    final groups = {
      'hangul-1': traceItems
          .where((i) => i.subject == 'hangul')
          .take(25)
          .toList(),
      'hangul-2': traceItems
          .where((i) => i.subject == 'hangul')
          .skip(25)
          .toList(),
      'english-upper': traceItems
          .where(
            (i) => i.subject == 'english' && i.symbol == i.symbol.toUpperCase(),
          )
          .toList(),
      'english-lower': traceItems
          .where(
            (i) => i.subject == 'english' && i.symbol == i.symbol.toLowerCase(),
          )
          .toList(),
      'numbers': traceItems.where((i) => i.subject == 'math').toList(),
      'prewriting': prewritingItems,
    };
    for (final group in groups.entries) {
      const columns = 5, width = 1200.0, cell = 240.0;
      final rows = (group.value.length / columns).ceil(),
          height = rows * 270.0 + 50;
      final recorder = ui.PictureRecorder();
      // A single recorder bounds the export; no app widgets or storage involved.
      final c = Canvas(recorder);
      c.drawColor(const Color(0xfffffcf2), BlendMode.src);
      void text(String value, Offset at, double size) {
        final p = TextPainter(
          text: TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: 'Jua',
              fontSize: size,
              color: const Color(0xff283b49),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: size == 23 ? width - 30 : 230);
        p.paint(c, at);
        p.dispose();
      }

      text('${group.key} / 자동 구조 검사 / 교육자 검수 대기', const Offset(15, 10), 23);
      for (var i = 0; i < group.value.length; i++) {
        final item = group.value[i],
            origin = Offset((i % columns) * cell, 50 + (i ~/ columns) * 270.0);
        c.drawRect(
          origin & const Size(cell, 270),
          Paint()
            ..color = const Color(0xffe2dac2)
            ..style = PaintingStyle.stroke,
        );
        text(
          '${item.symbol} / ${item.strokes.length}획',
          origin + const Offset(10, 8),
          22,
        );
        final at = origin + const Offset(12, 40);
        for (var j = 0; j < item.strokes.length; j++) {
          final path = item.strokes[j];
          final color = Colors.primaries[j % Colors.primaries.length].shade700;
          Offset p(TracePoint v) => at + Offset(v.x * 210, v.y * 200);
          final ink = Path()
            ..moveTo(p(path.points.first).dx, p(path.points.first).dy);
          for (final point in path.points.skip(1)) {
            ink.lineTo(p(point).dx, p(point).dy);
          }
          c.drawPath(
            ink,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..strokeCap = StrokeCap.round,
          );
          c.drawCircle(p(path.points.first), 4, Paint()..color = color);
          text(
            '${j + 1}',
            p(path.points.first) + Offset(6 * math.cos(j), -14 - (j % 2) * 8),
            17,
          );
        }
        text(item.id, origin + const Offset(10, 242), 16);
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${directory.path}/${group.key}.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }
    final manifest = {
      'automatedStructuralReview': 'passed',
      'educatorApproval': 'pending',
      'pronunciationListening': 'pending',
      'ageAndChildObservation': 'pending',
      'items': [
        for (final item in traceItems)
          {
            'id': item.id,
            'symbol': item.symbol,
            'subject': item.subject,
            'name': item.name,
            'example': item.example,
            'minimumLevel': item.minimumLevel,
            'language': item.language,
            'educatorApproval': 'pending',
            'strokes': [
              for (final (i, path) in item.strokes.indexed)
                {
                  'order': i + 1,
                  'length': path.length,
                  'points': [for (final p in path.points) p.toJson()],
                },
            ],
          },
      ],
    };
    await File('${directory.path}/learning_review.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
  });
}
