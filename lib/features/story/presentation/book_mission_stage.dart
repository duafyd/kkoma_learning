import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../learning/domain/learning_models.dart';
import '../domain/book_mission.dart';
import 'story_picture_quiz.dart';

class BookMissionStage extends StatefulWidget {
  final BookMission mission;
  final bool animate, active;
  final Future<void> Function(int)? onAnswer, onObserve;
  const BookMissionStage({
    super.key,
    required this.mission,
    required this.animate,
    required this.active,
    this.onAnswer,
    this.onObserve,
  });
  @override
  State<BookMissionStage> createState() => _BookMissionStageState();
}

class _BookMissionStageState extends State<BookMissionStage> {
  late final game = BookMissionGame(
    widget.mission,
    onAnswer: (i) async {
      if (mounted) await widget.onAnswer?.call(i);
    },
    onObserve: (i) async {
      if (mounted) await widget.onObserve?.call(i);
    },
  );
  void sync() => game.synchronize(
    widget.mission,
    motion: widget.animate && !MediaQuery.disableAnimationsOf(context),
    active: widget.active && TickerMode.valuesOf(context).enabled,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(covariant BookMissionStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final quiz = widget.mission.quiz;
      final enabled = widget.active && !widget.mission.solved;
      return Stack(
        children: [
          Positioned.fill(child: GameWidget(game: game, autofocus: false)),
          if (quiz != null && !widget.mission.solved) ...[
            for (var i = 0; i < quiz.options.length; i++)
              Positioned.fromRect(
                rect: BookMissionGame.choiceRect(
                  c.biggest,
                  quiz.options.length,
                  i,
                ),
                child: Semantics(
                  key: ValueKey('book-choice-$i'),
                  button: true,
                  label: '${widget.mission.location}, ${quiz.options[i]}',
                  enabled: enabled,
                  onTap: enabled ? () => game.choose(i) : null,
                  child: const SizedBox.expand(),
                ),
              ),
            if (quiz.artwork!.countOnTap)
              for (var i = 0; i < quiz.artwork!.objects.length; i++)
                Positioned.fromRect(
                  rect: BookMissionGame.objectRect(
                    c.biggest,
                    quiz.artwork!.objects.length,
                    i,
                  ),
                  child: Semantics(
                    key: ValueKey('book-object-$i'),
                    button: true,
                    label:
                        '${quiz.artwork!.objectName} ${i + 1}, ${widget.mission.observed.contains(i) ? '세었어요' : '눌러서 세어요'}',
                    enabled: enabled,
                    onTap: enabled ? () => game.observe(i) : null,
                    child: const SizedBox.expand(),
                  ),
                ),
          ],
        ],
      );
    },
  );
}

/// Flame owns finite visual interpolation and input hitboxes only.
/// VM persistence must succeed before energy or counted props can change.
class BookMissionGame extends FlameGame {
  BookMission mission;
  final Future<void> Function(int) onAnswer, onObserve;
  bool motion = true, active = true, backgrounded = false, pending = false;
  bool resumeQuietly = false;
  double from = 0, target = 0, elapsed = duration;
  static const duration = 1.8;
  final targets = <_BookTarget>[];
  BookMissionGame(
    this.mission, {
    required this.onAnswer,
    required this.onObserve,
  }) {
    from = target = mission.energy;
  }
  double get energy =>
      from +
      (target - from) *
          Curves.easeInOut.transform((elapsed / duration).clamp(0, 1));
  bool get interactive => active && !backgrounded;
  static Rect choiceRect(Size size, int count, int i) {
    final gap = math.min(14.0, size.width * .03);
    final width = math.min(
      142.0,
      (size.width - 24 - gap * (count - 1)) / count,
    );
    final height = math.min(124.0, size.height * .35);
    final span = count * width + (count - 1) * gap;
    return Rect.fromLTWH(
      (size.width - span) / 2 + i * (width + gap),
      size.height * .44 - height / 2,
      width,
      height,
    );
  }

  static Rect objectRect(Size size, int count, int i) {
    final edge = math.min(64.0, (size.width - 28) / count);
    return Rect.fromCenter(
      center: Offset(
        size.width / 2 + (i - (count - 1) / 2) * edge,
        size.height * .15,
      ),
      width: edge,
      height: math.min(64.0, size.height * .21),
    );
  }

  Future<void> choose(int i) => _input(i, false);
  Future<void> observe(int i) => _input(i, true);
  Future<void> _input(int i, bool object) async {
    final q = mission.quiz;
    if (!interactive ||
        pending ||
        mission.solved ||
        q == null ||
        i < 0 ||
        i >= (object ? q.artwork!.objects.length : q.options.length) ||
        (object && (!q.artwork!.countOnTap || mission.observed.contains(i)))) {
      return;
    }
    pending = true;
    try {
      await (object ? onObserve : onAnswer)(i);
    } finally {
      pending = false;
    }
  }

  @override
  Color backgroundColor() => Colors.transparent;
  @override
  Future<void> onLoad() async {
    final q = mission.quiz;
    if (q != null) {
      for (var i = 0; i < q.options.length; i++) {
        final t = _BookTarget(this, i, false);
        targets.add(t);
        await add(t);
      }
      if (q.artwork!.countOnTap) {
        for (var i = 0; i < q.artwork!.objects.length; i++) {
          final t = _BookTarget(this, i, true);
          targets.add(t);
          await add(t);
        }
      }
    }
    layout();
  }

  void layout() {
    final q = mission.quiz;
    if (q == null) return;
    for (final t in targets) {
      final rect = t.object
          ? objectRect(Size(size.x, size.y), q.artwork!.objects.length, t.index)
          : choiceRect(Size(size.x, size.y), q.options.length, t.index);
      t.position = Vector2(rect.left, rect.top);
      t.size = Vector2(rect.width, rect.height);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    layout();
  }

  void synchronize(
    BookMission next, {
    required bool motion,
    required bool active,
  }) {
    final current = energy;
    final changed = next.energy != target;
    mission = next;
    this.motion = motion;
    this.active = active;
    if (changed) {
      from = current;
      target = next.energy;
      elapsed = motion && interactive && !resumeQuietly ? 0 : duration;
    }
    if (!motion || !interactive) {
      from = target;
      elapsed = duration;
    }
    if (interactive) resumeQuietly = false;
    if (isAttached && interactive) {
      resumeEngine();
    } else if (!interactive) {
      pauseEngine();
    }
  }

  @override
  void update(double dt) {
    elapsed = math.min(duration, elapsed + dt);
    super.update(dt);
    if (!interactive || elapsed >= duration) pauseEngine();
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    backgrounded = state != AppLifecycleState.resumed;
    if (backgrounded) {
      resumeQuietly = true;
      from = target;
      elapsed = duration;
      pauseEngine();
    } else if (active) {
      resumeEngine();
    }
  }

  @override
  void render(Canvas canvas) {
    final viewport = Size(size.x, size.y);
    final q = mission.quiz;
    if (q != null && energy < 1) {
      canvas.saveLayer(
        Offset.zero & viewport,
        Paint()
          ..color = Color.fromRGBO(
            255,
            255,
            255,
            mission.solved ? 1 - energy : 1,
          ),
      );
      final objects = q.artwork!.objects;
      if (objects.isNotEmpty) {
        final first = objectRect(viewport, objects.length, 0);
        final last = objectRect(viewport, objects.length, objects.length - 1);
        _paper(
          canvas,
          first.expandToInclude(last).inflate(6),
          const Color(0xf5fff8de),
        );
        for (var i = 0; i < objects.length; i++) {
          final rect = objectRect(viewport, objects.length, i);
          _glyph(canvas, objects[i], rect.deflate(8));
          if (mission.observed.contains(i)) {
            final order = mission.observed.indexOf(i) + 1;
            canvas.drawCircle(
              rect.bottomRight - const Offset(9, 7),
              12,
              Paint()..color = const Color(0xff315f59),
            );
            _text(
              canvas,
              '$order',
              Rect.fromCenter(
                center: rect.bottomRight - const Offset(9, 7),
                width: 24,
                height: 24,
              ),
              16,
              Colors.white,
            );
          }
        }
      }
      for (var i = 0; i < q.options.length; i++) {
        final rect = choiceRect(viewport, q.options.length, i);
        final selected =
            (mission.solved || mission.hints >= 2) && i == q.answer;
        _choice(canvas, rect, q.artwork!.choices[i], q.options[i], selected);
      }
      canvas.restore();
    }
    if (mission.tracing || energy > 0) {
      _result(canvas, viewport, energy);
    }
    super.render(canvas);
  }

  void _paper(Canvas c, Rect r, Color color) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(16)));
    c.drawShadow(path, const Color(0x88433329), 5, true);
    c.drawPath(path, Paint()..color = color);
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xffbd9963)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  void _choice(
    Canvas c,
    Rect r,
    List<QuizGlyph> glyphs,
    String label,
    bool selected,
  ) {
    _paper(c, r, selected ? const Color(0xffffe1a1) : const Color(0xfafff8e6));
    final basket = [BookWorld.garden, BookWorld.wind].contains(mission.world);
    if (basket) {
      final handle = Rect.fromLTWH(
        r.left + r.width * .12,
        r.top - 9,
        r.width * .76,
        35,
      );
      c.drawArc(
        handle,
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xffae7b43)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }
    final cols = glyphs.length > 3 ? 3 : glyphs.length;
    final rows = (glyphs.length / cols).ceil();
    final edge = math.min((r.width - 14) / cols, (r.height - 35) / rows);
    for (var i = 0; i < glyphs.length; i++) {
      final row = i ~/ cols, col = i % cols;
      final n = math.min(cols, glyphs.length - row * cols);
      _glyph(
        c,
        glyphs[i],
        Rect.fromLTWH(
          r.center.dx - n * edge / 2 + col * edge,
          r.top + 5 + row * edge,
          edge,
          edge,
        ),
      );
    }
    _text(
      c,
      label,
      Rect.fromLTWH(r.left + 3, r.bottom - 32, r.width - 6, 30),
      16,
      const Color(0xff4f4934),
    );
    if (selected) {
      c.drawRRect(
        RRect.fromRectAndRadius(r.deflate(3), const Radius.circular(13)),
        Paint()
          ..color = const Color(0xffa66e29)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _glyph(Canvas c, QuizGlyph glyph, Rect r) {
    final edge = math.min(r.width, r.height);
    c.save();
    c.translate(r.center.dx - edge / 2, r.center.dy - edge / 2);
    QuizGlyphPainter(glyph).paint(c, Size.square(edge));
    c.restore();
  }

  void _text(Canvas c, String value, Rect r, double font, Color color) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Jua',
          fontSize: font,
          color: color,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: r.width);
    text.paint(
      c,
      Offset(r.center.dx - text.width / 2, r.center.dy - text.height / 2),
    );
    text.dispose();
  }

  void _result(Canvas c, Size s, double p) {
    final height = mission.tracing
        ? .55
        : switch (mission.world) {
            BookWorld.garden => .65,
            BookWorld.wind => .61,
            BookWorld.crossroads => .60,
            BookWorld.paperForest => .50,
            BookWorld.sky => .43,
            BookWorld.library => .47,
          };
    final center = Offset(s.width * .52, s.height * height);
    final edge = math.min(
      s.width * .6,
      s.height * (mission.tracing ? .54 : .32),
    );
    final ink = Paint()
      ..color = const Color(0xffffd67f)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    switch (mission.world) {
      case BookWorld.garden:
        for (var i = 0; i < 7; i++) {
          final at =
              center +
              Offset((i - 3) * edge * .29, math.sin(i * .9) * edge * .1);
          final scale = ((p * 7 - i) / 1.3).clamp(0.0, 1.0);
          if (scale > 0) {
            _glyph(
              c,
              i.isEven ? QuizGlyph.redFlower : QuizGlyph.blueFlower,
              Rect.fromCenter(
                center: at,
                width: edge * .42 * scale,
                height: edge * .42 * scale,
              ),
            );
          }
        }
      case BookWorld.wind:
        final basket = Rect.fromCenter(
          center: center + Offset(edge * .48 * p, 0),
          width: edge * .75,
          height: edge * .55,
        );
        _paper(c, basket, const Color(0xffe8bb7c));
        _text(
          c,
          mission.tracing ? mission.symbol : 'A  C',
          basket,
          edge * .28,
          const Color(0xff315f59),
        );
        for (var i = 0; i < 3; i++) {
          final at =
              Offset.lerp(
                center - Offset(edge * (.75 + i * .25), edge * .1),
                basket.center,
                p,
              )! -
              Offset(0, math.sin(p * math.pi) * edge * .6);
          c.save();
          c.translate(at.dx, at.dy);
          c.rotate((1 - p) * (i - 1) * .4);
          _paper(
            c,
            Rect.fromCenter(
              center: Offset.zero,
              width: edge * .2,
              height: edge * .25,
            ),
            const Color(0xfffff1cf),
          );
          c.restore();
        }
      case BookWorld.crossroads:
        final route = switch (mission.variation) {
          '영어 길' => 0,
          '숫자 길' => 1,
          _ => -1,
        };
        final start = center + Offset(route * edge * .65, -edge * .4);
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(
            center.dx,
            center.dy,
            center.dx,
            center.dy + edge * .4,
          );
        final metric = path.computeMetrics().first;
        c.drawPath(
          metric.extractPath(0, metric.length * p),
          ink..strokeWidth = 7,
        );
        if (mission.tracing) {
          _text(
            c,
            mission.symbol,
            Rect.fromCenter(
              center: center,
              width: edge * .6,
              height: edge * .6,
            ),
            edge * .5,
            const Color(0xffffe7a8),
          );
        }
      case BookWorld.paperForest:
        _book(c, center, edge, p, mission.tracing ? mission.symbol : '');
        for (var i = 0; i < 3; i++) {
          if (p * 3 > i) {
            _glyph(
              c,
              [QuizGlyph.seed, QuizGlyph.sprout, QuizGlyph.tree][i],
              Rect.fromCenter(
                center: center + Offset((i - 1) * edge * .52, -edge * .65),
                width: edge * .35,
                height: edge * .35,
              ),
            );
          }
        }
      case BookWorld.sky:
        final left = center - Offset(edge * .6, 0),
            right = center + Offset(edge * .6, 0);
        c.drawLine(left, Offset.lerp(left, right, p)!, ink);
        for (final at in [left, right]) {
          _glyph(
            c,
            QuizGlyph.star,
            Rect.fromCenter(
              center: at,
              width: edge * (.25 + p * .18),
              height: edge * (.25 + p * .18),
            ),
          );
        }
        if (mission.tracing) {
          _text(
            c,
            mission.symbol,
            Rect.fromCenter(
              center: center,
              width: edge * .6,
              height: edge * .6,
            ),
            edge * .5,
            const Color(0xffffe7a8),
          );
        }
      case BookWorld.library:
        _book(c, center, edge, p, mission.tracing ? mission.symbol : '');
        for (var i = 0; i < 5; i++) {
          final angle = math.pi + i * math.pi / 4;
          final at =
              center + Offset(math.cos(angle), math.sin(angle)) * edge * .8;
          if (p > i / 6) {
            _glyph(
              c,
              mission.variation == '꽃 방' ? QuizGlyph.flower : QuizGlyph.star,
              Rect.fromCenter(center: at, width: edge * .3, height: edge * .3),
            );
          }
        }
    }
  }

  void _book(Canvas c, Offset at, double edge, double p, String symbol) {
    final book = Rect.fromCenter(
      center: at,
      width: edge * (1 + p * .45),
      height: edge * .65,
    );
    _paper(c, book.inflate(4), const Color(0xff886044));
    _paper(c, book, const Color(0xfffff1cf));
    c.drawLine(
      Offset(at.dx, book.top + 3),
      Offset(at.dx, book.bottom - 3),
      Paint()
        ..color = const Color(0xffbf9b62)
        ..strokeWidth = 2,
    );
    _text(c, symbol, book, edge * .45, const Color(0xff46685a));
    if (p > 0) {
      c.drawOval(
        book.inflate(edge * .16),
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color.fromRGBO(255, 222, 142, .25 * p),
              const Color(0x00ffde8e),
            ],
          ).createShader(book.inflate(edge * .16)),
      );
    }
  }
}

class _BookTarget extends PositionComponent with TapCallbacks {
  final BookMissionGame stage;
  final int index;
  final bool object;
  _BookTarget(this.stage, this.index, this.object);
  @override
  void onTapDown(TapDownEvent event) {
    if (object) {
      stage.observe(index);
    } else {
      stage.choose(index);
    }
  }
}
