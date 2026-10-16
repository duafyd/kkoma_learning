import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../learning/domain/learning_models.dart';
import 'story_placement_board.dart';

/// Story props and picture choices. Correctness and counting live in the VM.
class StoryPictureQuiz extends StatelessWidget {
  final QuizDefinition quiz;
  final List<int> observed;
  final int hints;
  final bool animate;
  final bool answerEnabled;
  final bool worldPlacement;
  final bool sceneChoices;
  final String sceneInstruction;
  final ValueChanged<int> onAnswer, onObserve;
  final void Function(int, int)? onPlace;
  const StoryPictureQuiz({
    super.key,
    required this.quiz,
    required this.observed,
    required this.hints,
    required this.animate,
    this.answerEnabled = true,
    this.worldPlacement = false,
    this.sceneChoices = false,
    this.sceneInstruction = '그림 속 글자를 눌러요.',
    required this.onAnswer,
    required this.onObserve,
    this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    final artwork = quiz.artwork!;
    final motion = animate && !MediaQuery.disableAnimationsOf(context);
    if (sceneChoices) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(quiz.prompt, style: const TextStyle(fontSize: 25, height: 1.4)),
          const SizedBox(height: 8),
          Text(sceneInstruction, style: const TextStyle(fontSize: 19)),
          Material(
            color: Colors.transparent,
            child: ExpansionTile(
              key: const ValueKey('letter-choice-alternative'),
              title: const Text('버튼으로 고르기'),
              children: [
                StoryPictureQuiz(
                  quiz: quiz,
                  observed: observed,
                  hints: hints,
                  animate: animate,
                  answerEnabled: answerEnabled,
                  onAnswer: onAnswer,
                  onObserve: onObserve,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(quiz.prompt, style: const TextStyle(fontSize: 25, height: 1.4)),
        const SizedBox(height: 16),
        if (worldPlacement)
          Material(
            color: Colors.transparent,
            child: ExpansionTile(
              key: const ValueKey('placement-alternative'),
              title: const Text('버튼으로 놓기'),
              children: [
                StoryPlacementBoard(
                  artwork: artwork,
                  placed: observed,
                  onPlace: onPlace ?? (_, _) {},
                ),
              ],
            ),
          )
        else if (artwork.arrangement != QuizArrangement.tray)
          StoryPlacementBoard(
            artwork: artwork,
            placed: observed,
            onPlace: onPlace ?? (_, _) {},
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xfff8eed5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xffe7d9b4)),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 12,
              children: List.generate(artwork.objects.length, (i) {
                final order = observed.indexOf(i);
                final counted = order >= 0;
                return Semantics(
                  button: artwork.countOnTap,
                  label: artwork.countOnTap
                      ? '${artwork.objectName} ${i + 1}, ${counted ? '${order + 1}번째로 세었어요' : '눌러서 세어 봐요'}'
                      : '찾을 모양: ${artwork.objects[i].label}',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey('quiz-object-$i'),
                      borderRadius: BorderRadius.circular(18),
                      onTap: artwork.countOnTap ? () => onObserve(i) : null,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: motion ? 180 : 0),
                        width: 72,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: counted
                              ? const Color(0xffdbece4)
                              : const Color(0xfffffcf2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: counted
                                ? const Color(0xff397c70)
                                : const Color(0xffe8d9b5),
                            width: 2,
                          ),
                        ),
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              QuizGlyphPicture(
                                glyph: artwork.objects[i],
                                edge: 54,
                              ),
                              if (artwork.countOnTap)
                                Text(
                                  counted ? '${order + 1}' : '톡',
                                  style: const TextStyle(fontSize: 18),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 420 && quiz.options.length == 3
                ? 3
                : 2;
            final width = (c.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(quiz.options.length, (i) {
                final highlighted = hints >= 2 && i == quiz.answer;
                return SizedBox(
                  width: width,
                  child: FilledButton.tonal(
                    key: ValueKey('picture-answer-$i'),
                    onPressed: answerEnabled ? () => onAnswer(i) : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      minimumSize: const Size(80, 100),
                      backgroundColor: highlighted
                          ? const Color(0xfff7db99)
                          : const Color(0xffe3eee6),
                      foregroundColor: const Color(0xff36584c),
                      side: BorderSide(
                        color: highlighted
                            ? const Color(0xffb47a25)
                            : const Color(0xffbfd4c7),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExcludeSemantics(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 3,
                            runSpacing: 3,
                            children: artwork.choices[i]
                                .map(
                                  (g) => QuizGlyphPicture(
                                    glyph: g,
                                    edge: g.symbol == null ? 28 : 46,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          quiz.options[i],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 19, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class QuizGlyphPicture extends StatelessWidget {
  final QuizGlyph glyph;
  final double edge;
  const QuizGlyphPicture({super.key, required this.glyph, required this.edge});
  @override
  Widget build(BuildContext context) {
    if (glyph.symbol != null) {
      return SizedBox.square(
        dimension: edge,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            glyph.symbol!,
            style: TextStyle(
              fontSize: edge * .86,
              height: 1.1,
              color: const Color(0xff315f59),
            ),
          ),
        ),
      );
    }
    return CustomPaint(
      size: Size.square(edge),
      painter: QuizGlyphPainter(glyph),
    );
  }
}

class QuizGlyphPainter extends CustomPainter {
  final QuizGlyph glyph;
  QuizGlyphPainter(this.glyph);
  @override
  void paint(Canvas canvas, Size size) {
    if (glyph.symbol != null) {
      final text = TextPainter(
        text: TextSpan(
          text: glyph.symbol,
          style: TextStyle(
            fontFamily: 'Jua',
            fontSize: size.shortestSide * .83,
            height: 1.1,
            color: const Color(0xff315f59),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      text.paint(
        canvas,
        Offset((size.width - text.width) / 2, (size.height - text.height) / 2),
      );
      text.dispose();
      return;
    }
    final center = Offset(size.width / 2, size.height / 2),
        r = size.shortestSide * .4;
    final path = Path();
    if (glyph == QuizGlyph.circle) {
      path.addOval(Rect.fromCircle(center: center, radius: r));
    } else if (glyph == QuizGlyph.apple) {
      path.moveTo(center.dx, center.dy - r * .65);
      path.cubicTo(
        center.dx - r * 1.2,
        center.dy - r * 1.1,
        center.dx - r * 1.1,
        center.dy + r * .6,
        center.dx - r * .35,
        center.dy + r,
      );
      path.quadraticBezierTo(
        center.dx,
        center.dy + r * .8,
        center.dx + r * .35,
        center.dy + r,
      );
      path.cubicTo(
        center.dx + r * 1.1,
        center.dy + r * .6,
        center.dx + r * 1.2,
        center.dy - r * 1.1,
        center.dx,
        center.dy - r * .65,
      );
      path.close();
    } else if (glyph == QuizGlyph.banana) {
      path.moveTo(center.dx - r * .7, center.dy - r * .85);
      path.cubicTo(
        center.dx - r * .6,
        center.dy + r * .9,
        center.dx + r * .9,
        center.dy + r,
        center.dx + r * .9,
        center.dy - r * .3,
      );
      path.cubicTo(
        center.dx + r * .1,
        center.dy + r * .35,
        center.dx - r * .35,
        center.dy + r * .1,
        center.dx - r * .7,
        center.dy - r * .85,
      );
      path.close();
    } else if (glyph == QuizGlyph.stone) {
      path.addOval(
        Rect.fromCenter(center: center, width: r * 2, height: r * 1.5),
      );
    } else if (glyph == QuizGlyph.book) {
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: r * 2, height: r * 1.6),
          Radius.circular(r * .15),
        ),
      );
    } else if (glyph == QuizGlyph.sprout || glyph == QuizGlyph.tree) {
      canvas.drawLine(
        center + Offset(0, r),
        center + Offset(0, -r * .4),
        Paint()
          ..color = const Color(0xff826038)
          ..strokeWidth = r * .2
          ..strokeCap = StrokeCap.round,
      );
      if (glyph == QuizGlyph.tree) {
        path.addOval(
          Rect.fromCenter(
            center: center - Offset(0, r * .35),
            width: r * 1.9,
            height: r * 1.5,
          ),
        );
      } else {
        path.addOval(
          Rect.fromCenter(
            center: center + Offset(-r * .4, -r * .25),
            width: r * .9,
            height: r * .5,
          ),
        );
        path.addOval(
          Rect.fromCenter(
            center: center + Offset(r * .4, -r * .5),
            width: r * .9,
            height: r * .5,
          ),
        );
      }
    } else if ([
      QuizGlyph.flower,
      QuizGlyph.redFlower,
      QuizGlyph.blueFlower,
    ].contains(glyph)) {
      for (var i = 0; i < 5; i++) {
        final a = i * math.pi * 2 / 5 - math.pi / 2;
        path.addOval(
          Rect.fromCircle(
            center: center + Offset(math.cos(a), math.sin(a)) * r * .55,
            radius: r * .48,
          ),
        );
      }
    } else if (glyph == QuizGlyph.leaf || glyph == QuizGlyph.seed) {
      path.moveTo(center.dx, center.dy - r);
      path.cubicTo(
        center.dx + r * 1.2,
        center.dy - r * .3,
        center.dx + r,
        center.dy + r,
        center.dx,
        center.dy + r,
      );
      path.cubicTo(
        center.dx - r,
        center.dy + r,
        center.dx - r * 1.2,
        center.dy - r * .3,
        center.dx,
        center.dy - r,
      );
      path.close();
    } else {
      final n = glyph == QuizGlyph.star ? 10 : 3;
      for (var i = 0; i < n; i++) {
        final angle = -math.pi / 2 + math.pi * 2 * i / n;
        final radius = glyph == QuizGlyph.star && i.isOdd ? r * .48 : r;
        final point =
            center + Offset(math.cos(angle), math.sin(angle)) * radius;
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
    }
    final color = switch (glyph) {
      QuizGlyph.star => const Color(0xffedb545),
      QuizGlyph.circle => const Color(0xff70b5a9),
      QuizGlyph.triangle => const Color(0xffe3a182),
      QuizGlyph.flower => const Color(0xffe5a3b7),
      QuizGlyph.leaf => const Color(0xff92b46e),
      QuizGlyph.seed => const Color(0xffd9ac66),
      QuizGlyph.apple => const Color(0xffdc796d),
      QuizGlyph.banana => const Color(0xffedcc64),
      QuizGlyph.stone => const Color(0xff91a5ac),
      QuizGlyph.book => const Color(0xffc19265),
      QuizGlyph.sprout || QuizGlyph.tree => const Color(0xff78a95c),
      QuizGlyph.redFlower => const Color(0xffd75e61),
      QuizGlyph.blueFlower => const Color(0xff579ed1),
      _ => const Color(0xff315f59),
    };
    canvas.drawShadow(path, const Color(0x55634b33), 2, true);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(color, const Color(0xff634b33), .25)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      center + Offset(-r * .22, -r * .24),
      r * .11,
      Paint()..color = const Color(0x99ffffff),
    );
    if (glyph == QuizGlyph.apple) {
      canvas.drawLine(
        center + Offset(0, -r * .55),
        center + Offset(r * .1, -r * .94),
        Paint()
          ..color = const Color(0xff765534)
          ..strokeWidth = 2,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(r * .34, -r * .8),
          width: r * .65,
          height: r * .3,
        ),
        Paint()..color = const Color(0xff7f9d5a),
      );
    }
    if (glyph == QuizGlyph.book) {
      final pages = Rect.fromCenter(
        center: center - Offset(0, r * .08),
        width: r * 1.65,
        height: r * 1.23,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pages, Radius.circular(r * .1)),
        Paint()..color = const Color(0xfffff3d4),
      );
      canvas.drawLine(
        Offset(center.dx, pages.top),
        Offset(center.dx, pages.bottom),
        Paint()
          ..color = const Color(0xffb99a70)
          ..strokeWidth = r * .06,
      );
    }
    if ([
      QuizGlyph.flower,
      QuizGlyph.redFlower,
      QuizGlyph.blueFlower,
    ].contains(glyph)) {
      canvas.drawCircle(
        center,
        r * .32,
        Paint()..color = const Color(0xffffd87f),
      );
    }
    if (glyph == QuizGlyph.leaf || glyph == QuizGlyph.seed) {
      canvas.drawLine(
        center + Offset(0, -r * .65),
        center + Offset(0, r * .65),
        Paint()
          ..color = const Color(0xffa27a42)
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant QuizGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph;
}
