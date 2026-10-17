import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../domain/story_quest.dart';

/// Every chapter uses the same visible collection book and physical fragment.
/// Flame animates only changes already committed by the story VM.
class StoryQuestStage extends StatefulWidget {
  final StoryQuest quest;
  final bool animate, active;
  final VoidCallback onCollect;
  const StoryQuestStage({
    super.key,
    required this.quest,
    required this.animate,
    required this.active,
    required this.onCollect,
  });
  @override
  State<StoryQuestStage> createState() => _StoryQuestStageState();
}

class _StoryQuestStageState extends State<StoryQuestStage> {
  late final game = StoryQuestGame(widget.quest);
  void sync() => game.synchronize(
    widget.quest,
    animate: widget.animate && !MediaQuery.disableAnimationsOf(context),
    active: widget.active && TickerMode.valuesOf(context).enabled,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(covariant StoryQuestStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final rect = StoryQuestGame.fragmentRect(Size(c.maxWidth, c.maxHeight));
      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: GameWidget<StoryQuestGame>(game: game, autofocus: false),
            ),
          ),
          Positioned(
            top: 3,
            left: 8,
            right: 8,
            height: 64,
            child: Semantics(
              key: const ValueKey('fragment-book'),
              label: '도서관 책의 별조각 ${widget.quest.collected.length}개, 전체12칸',
              image: true,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned.fromRect(
            rect: rect,
            child: Semantics(
              label: widget.quest.hasFragment
                  ? '책에 담은 ${widget.quest.chapter}번째 별조각'
                  : widget.quest.ready
                  ? '별조각 담기'
                  : '별조각: 미션 ${widget.quest.done}/${widget.quest.total}',
              button: widget.quest.ready && !widget.quest.hasFragment,
              child: widget.quest.ready && !widget.quest.hasFragment
                  ? Tooltip(
                      message: '별조각 담기',
                      child: GestureDetector(
                        key: const ValueKey('collect-story-fragment'),
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onCollect,
                        child: const SizedBox.expand(),
                      ),
                    )
                  : const SizedBox.expand(),
            ),
          ),
        ],
      );
    },
  );
}

class StoryQuestGame extends FlameGame {
  StoryQuest quest;
  double remaining = 0, elapsed = 0;
  bool active = true;
  StoryQuestGame(this.quest);
  @override
  Color backgroundColor() => Colors.transparent;
  static Rect fragmentRect(Size size) => Rect.fromCenter(
    center: Offset(
      size.width - (size.width * .12).clamp(48, 85),
      (size.height * .31).clamp(95, math.max(95, size.height - 65)),
    ),
    width: (size.width * .23).clamp(76, 110),
    height: (size.width * .23).clamp(76, 110),
  );
  void synchronize(
    StoryQuest next, {
    required bool animate,
    required bool active,
  }) {
    final changed =
        next.chapter == quest.chapter &&
        (next.hasFragment != quest.hasFragment ||
            next.ready != quest.ready ||
            next.done != quest.done);
    quest = next;
    this.active = active;
    if (!animate || !active) {
      remaining = 0;
    } else if (changed) {
      remaining = 1.25;
      elapsed = 0;
    }
    if (isAttached) {
      if (active) {
        resumeEngine();
      } else {
        pauseEngine();
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!active) return;
    elapsed += dt;
    remaining = math.max(0, remaining - dt);
    if (remaining == 0) pauseEngine();
  }

  void star(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius : radius * .46;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawShadow(path, const Color(0xff7c511c), 3, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xffaa7932),
    );
  }

  void label(
    Canvas canvas,
    String text,
    Offset offset,
    double width, {
    double fontSize = 17,
    Color color = const Color(0xfff8eccb),
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: 'Jua', fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  void obstacle(Canvas canvas, Offset center, double radius) {
    final r = radius * 1.7;
    final progress = quest.total == 0 ? 0.0 : quest.done / quest.total;
    final open = quest.ready;
    final wood = Paint()..color = const Color(0xffa16c43);
    final light = Paint()..color = const Color(0xffffdfa2);
    final outline = Paint()
      ..color = const Color(0xff376660)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final box = Rect.fromCenter(center: center, width: r * 2, height: r * 1.7);
    switch (quest.chapter) {
      case 2:
      case 7:
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final petal =
              center + Offset(math.cos(a), math.sin(a)) * r * (open ? .9 : .5);
          canvas.drawOval(
            Rect.fromCenter(center: petal, width: r * .95, height: r * .7),
            Paint()
              ..color = quest.chapter == 7 && !open
                  ? const Color(0xffe5e9d7)
                  : const Color(0xfff6b3bc),
          );
        }
      case 3:
        canvas.drawLine(
          center + Offset(-r, -r * .6),
          center + Offset(r, -r * .6 - progress * r * .25),
          wood
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round,
        );
        for (final x in [-.7, .7]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: center + Offset(r * x, -r * .9),
              width: r * .6,
              height: r * .3,
            ),
            Paint()..color = const Color(0xff78a54e),
          );
        }
      case 4:
        final roof = Path()
          ..moveTo(box.left, box.top)
          ..lineTo(center.dx, box.top - r * .35)
          ..lineTo(box.right, box.top)
          ..close();
        canvas.drawPath(roof, wood);
        for (final x in [-.6, .6]) {
          canvas.drawLine(
            center + Offset(r * x, r * .45),
            center + Offset(r * x, r * 1.15),
            outline,
          );
        }
        for (var i = 0; i < (open ? 4 : 2); i++) {
          canvas.drawLine(
            center + Offset(-r * .6, r * (.55 + i * .17)),
            center + Offset(r * .6, r * (.55 + i * .17)),
            outline,
          );
        }
      case 5:
        final rock = Path()
          ..moveTo(box.left, box.bottom)
          ..lineTo(box.left - r * .1, box.top + r * .2)
          ..lineTo(center.dx - r * .25, box.top)
          ..lineTo(center.dx, box.top + r * .3)
          ..lineTo(box.right, box.top)
          ..lineTo(box.right + r * .2, box.bottom)
          ..close();
        canvas.drawPath(rock, Paint()..color = const Color(0xff7b8e9b));
        if (open) {
          canvas.drawCircle(
            center,
            r * 1.2,
            Paint()..color = const Color(0x88ffedaa),
          );
        }
      case 6:
      case 11:
        for (var i = 0; i < 5; i++) {
          final p =
              center +
              Offset(
                (i - 2) * r * .48,
                r * .75 + math.sin(i * math.pi / 4) * r * .3,
              );
          canvas.drawCircle(
            p,
            r * .16,
            Paint()
              ..color = i < 5 * progress
                  ? const Color(0xffffdf77)
                  : const Color(0xff6c7a87),
          );
          if (i > 0 && i < 5 * progress) {
            canvas.drawLine(
              p - Offset(r * .48, 0),
              p,
              outline..color = const Color(0xffffdf77),
            );
          }
        }
      case 9:
        for (var i = 0; i < 3; i++) {
          final p = center + Offset((i - 1) * r * .7, r * .8);
          canvas.drawLine(p, p + Offset(0, -r * .6), wood..strokeWidth = 4);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: p + Offset(0, -r * .6),
                width: r * .55,
                height: r * .3,
              ),
              const Radius.circular(3),
            ),
            light,
          );
        }
      case 1:
      case 8:
      case 10:
      case 12:
        canvas.drawRRect(
          RRect.fromRectAndRadius(box, const Radius.circular(12)),
          wood,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(box.deflate(5), const Radius.circular(9)),
          light,
        );
        if (!open) {
          final lid = Rect.fromLTWH(
            box.left - 3,
            box.top - 5 - progress * r * .3,
            box.width + 6,
            r * .35,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(lid, const Radius.circular(4)),
            wood,
          );
          canvas.drawCircle(
            Offset(center.dx, lid.center.dy),
            3,
            Paint()..color = const Color(0xffffe2a4),
          );
        }
      default:
        break;
    }
  }

  void completeBook(Canvas canvas) {
    final w = math.min(size.x * .49, size.y * .65), h = w * .62;
    final center = Offset(size.x * .48, math.max(80 + h / 2, size.y * .30));
    final cover = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w + 12, height: h + 12),
      const Radius.circular(14),
    );
    canvas.drawShadow(
      Path()..addRRect(cover),
      const Color(0xff6f4d21),
      8,
      false,
    );
    canvas.drawRRect(cover, Paint()..color = const Color(0xff507f70));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w, height: h),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xffffefc3),
    );
    canvas.drawLine(
      center + Offset(0, -h * .46),
      center + Offset(0, h * .46),
      Paint()
        ..color = const Color(0xffcead6c)
        ..strokeWidth = 3,
    );
    for (var i = 0; i < 12; i++) {
      final page = i < 6 ? -1 : 1, cell = i % 6;
      star(
        canvas,
        center +
            Offset(
              page * w * .24 + (cell % 2 - .5) * w * .16,
              (cell ~/ 2 - 1) * h * .28,
            ),
        w * .055,
        const Color(0xffffce4b),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;
    final width = size.x, height = size.y;
    final book = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 6, width - 16, 59),
      const Radius.circular(18),
    );
    canvas.drawRRect(book, Paint()..color = const Color(0xed233e50));
    label(
      canvas,
      '도서관 책  ${quest.collected.length}/12',
      const Offset(20, 10),
      width - 40,
      fontSize: 16,
    );
    final step = (width - 42) / 12;
    for (var i = 1; i <= 12; i++) {
      final position = Offset(20 + step * (i - .5), 46);
      star(
        canvas,
        position,
        math.min(10, step * .4),
        quest.collected.contains(i)
            ? const Color(0xffffdc62)
            : const Color(0xff637782),
      );
    }
    final rect = fragmentRect(Size(width, height));
    var center = rect.center;
    if (quest.hasFragment && remaining > 0) {
      final progress = (elapsed / 1.1).clamp(0.0, 1.0);
      final target = Offset(20 + step * (quest.chapter - .5), 46);
      center = Offset.lerp(
        center,
        target,
        Curves.easeInOutCubic.transform(progress),
      )!;
    }
    final radius = rect.width * .28;
    if (quest.collected.length == 12) completeBook(canvas);
    if (!quest.hasFragment || remaining > 0) {
      if (!quest.hasFragment) obstacle(canvas, center, radius);
      if (quest.ready) {
        canvas.drawCircle(
          center,
          radius * 1.65,
          Paint()..color = const Color(0x66ffe28b),
        );
      }
      star(
        canvas,
        center,
        radius * (remaining > 0 ? 1 + math.sin(elapsed * 10) * .06 : 1),
        quest.ready ? const Color(0xffffdf68) : const Color(0xffb6c0c2),
      );
      if (!quest.ready) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius * 1.45),
          -math.pi / 2,
          math.pi * 2 * (quest.total == 0 ? 0 : quest.done / quest.total),
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xffffdf68),
        );
      }
      if (remaining > 0) {
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final distance = radius * (1 + elapsed);
          canvas.drawCircle(
            center + Offset(math.cos(angle), math.sin(angle)) * distance,
            2.8,
            Paint()..color = const Color(0xffffefad),
          );
        }
      }
      final caption = quest.ready ? '톡! 담기' : '${quest.done}/${quest.total} 준비';
      final textRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.center.dx, rect.bottom - 5),
          width: rect.width,
          height: 25,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(textRect, Paint()..color = const Color(0xed233e50));
      label(
        canvas,
        caption,
        Offset(textRect.left + 8, textRect.top + 3),
        rect.width - 16,
        fontSize: 16,
      );
    }
  }
}
