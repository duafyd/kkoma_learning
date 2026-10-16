import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../domain/letter_mission.dart';

/// World reactions consume saved strokes/success only. Flame cannot mark a
/// letter correct or advance the book; both actions belong to StoryVM.
class LetterMissionStage extends StatefulWidget {
  final LetterMission mission;
  final bool animate, active;
  final Future<void> Function(int)? onChoose;
  const LetterMissionStage({
    super.key,
    required this.mission,
    required this.animate,
    required this.active,
    this.onChoose,
  });
  @override
  State<LetterMissionStage> createState() => _LetterMissionStageState();
}

class _LetterMissionStageState extends State<LetterMissionStage> {
  late final game = LetterMissionGame(widget.mission, (i) async {
    if (mounted) await widget.onChoose?.call(i);
  });
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
  void didUpdateWidget(covariant LetterMissionStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Stack(
      children: [
        Positioned.fill(child: GameWidget(game: game, autofocus: false)),
        if (!widget.mission.tracing && !widget.mission.solved)
          for (var i = 0; i < widget.mission.choices.length; i++)
            Positioned.fromRect(
              rect: LetterMissionGame.choiceRect(c.biggest, widget.mission, i),
              child: Semantics(
                key: ValueKey('letter-world-choice-$i'),
                button: true,
                enabled: widget.active,
                label:
                    '${widget.mission.location} ${widget.mission.choices[i]}',
                onTap: widget.active ? () => game.choose(i) : null,
                child: const SizedBox.expand(),
              ),
            ),
      ],
    ),
  );
}

class LetterMissionGame extends FlameGame {
  LetterMission mission;
  final Future<void> Function(int) onChoose;
  final tokens = <_LetterToken>[];
  bool motion = true, active = true, backgrounded = false, pending = false;
  bool resumeQuietly = false;
  double from = 0, target = 0, elapsed = 1.6;
  double get energy =>
      from +
      (target - from) * Curves.easeInOut.transform((elapsed / 1.6).clamp(0, 1));
  bool get interactive => active && !backgrounded;
  LetterMissionGame(this.mission, this.onChoose) {
    from = target = mission.energy;
  }

  /// Same cover crop and .15 vertical alignment as the 1536×1024 artwork.
  static Offset artPoint(Size size, double x, double y) {
    final scale = math.max(size.width / 1536, size.height / 1024);
    return Offset(
      (size.width - 1536 * scale) / 2 + x * 1536 * scale,
      (size.height - 1024 * scale) * .575 + y * 1024 * scale,
    );
  }

  static Rect choiceRect(Size size, LetterMission mission, int i) {
    final gate = mission.world == LetterWorld.flowerGate;
    final plaqueDistance = .139 * math.max(size.width, size.height * 1.5);
    final edge = gate
        ? (plaqueDistance - 6).clamp(56.0, 100.0)
        : (math.min(size.width, size.height) * .24).clamp(56.0, 100.0);
    final gateCenter = artPoint(size, (.435 + .574) / 2, .292);
    final center = gate
        ? gateCenter +
              Offset(
                (mission.choices[i] == 'ㅏ' ? -1 : 1) *
                    math.max(plaqueDistance, edge + 6) /
                    2,
                0,
              )
        : Offset(
            size.width * (i == 0 ? .28 : .74),
            size.height * (mission.world == LetterWorld.seedTree ? .28 : .43),
          );
    return Rect.fromCenter(center: center, width: edge, height: edge);
  }

  Future<void> choose(int i) async {
    if (!interactive ||
        pending ||
        mission.solved ||
        mission.tracing ||
        i < 0 ||
        i >= mission.choices.length) {
      return;
    }
    pending = true;
    try {
      await onChoose(i);
    } finally {
      pending = false;
    }
  }

  @override
  Color backgroundColor() => Colors.transparent;
  @override
  Future<void> onLoad() async {
    for (var i = 0; i < mission.choices.length; i++) {
      final token = _LetterToken(this, i);
      tokens.add(token);
      await add(token);
    }
    layout();
  }

  void layout() {
    for (var i = 0; i < tokens.length; i++) {
      final rect = choiceRect(Size(size.x, size.y), mission, i);
      tokens[i]
        ..position = Vector2(rect.left, rect.top)
        ..size = Vector2(rect.width, rect.height);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    layout();
  }

  void synchronize(
    LetterMission next, {
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
      elapsed = motion && interactive && !resumeQuietly ? 0 : 1.6;
    }
    if (!motion || !interactive) {
      from = target;
      elapsed = 1.6;
    }
    if (interactive) resumeQuietly = false;
    if (isAttached && interactive) {
      resumeEngine(); // Repaint even when motion is off, then sleep.
    } else if (!interactive) {
      pauseEngine();
    }
  }

  @override
  void update(double dt) {
    elapsed = math.min(1.6, elapsed + dt);
    super.update(dt);
    if (!interactive || elapsed >= 1.6) pauseEngine();
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    backgrounded = state != AppLifecycleState.resumed;
    if (backgrounded) {
      resumeQuietly = true;
      from = target;
      elapsed = 1.6;
      pauseEngine();
    } else if (active) {
      resumeEngine();
    }
  }

  @override
  void render(Canvas canvas) {
    final viewport = Size(size.x, size.y);
    final amount = energy;
    if (amount > 0) {
      switch (mission.world) {
        case LetterWorld.flowerGate:
          _flowers(canvas, viewport, amount);
        case LetterWorld.lighthouse:
          _beacon(canvas, viewport, amount);
        case LetterWorld.seedTree:
          _seeds(canvas, viewport, amount);
        case LetterWorld.soundTrain:
          _train(canvas, viewport, amount);
      }
    }
    super.render(canvas);
  }

  void _flowers(Canvas canvas, Size viewport, double amount) {
    final path = Path();
    for (var i = 0; i < 9; i++) {
      final p = artPoint(
        viewport,
        .5 + math.sin(i * .7) * .055,
        .59 + i * .045,
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * amount),
      Paint()
        ..color = const Color(0xffffdd91).withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 9; i++) {
      final bloom = ((amount * 9 - i) * 1.8).clamp(0.0, 1.0);
      if (bloom == 0) continue;
      final p = artPoint(
        viewport,
        .5 + math.sin(i * .7) * .055,
        .59 + i * .045,
      );
      final r = (viewport.shortestSide * .014).clamp(3.0, 8.0) * bloom;
      canvas.drawCircle(
        p,
        r * 3.4,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xffffe4a0).withValues(alpha: .65),
              const Color(0xffffe4a0).withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: p, radius: r * 3.4)),
      );
      for (var petal = 0; petal < 5; petal++) {
        final angle = petal * math.pi * 2 / 5;
        canvas.drawCircle(
          p + Offset(math.cos(angle), math.sin(angle)) * r,
          r * .8,
          Paint()..color = const Color(0xffffe9bc),
        );
      }
      canvas.drawCircle(p, r * .6, Paint()..color = const Color(0xffe8ae4d));
    }
  }

  void _beacon(Canvas canvas, Size viewport, double amount) {
    final origin = artPoint(viewport, .606, .188);
    final reach = viewport.width * .75 * amount;
    final cone = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + reach, origin.dy - reach * .04)
      ..lineTo(origin.dx + reach, origin.dy + reach * .35)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader =
            LinearGradient(
              colors: [
                const Color(0xffffe6a6).withValues(alpha: .65 * amount),
                const Color(0xfffff2ce).withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromLTWH(
                origin.dx,
                origin.dy,
                math.max(1, reach),
                math.max(1, reach * .35),
              ),
            ),
    );
    final r = viewport.shortestSide * .12;
    canvas.drawCircle(
      origin,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xfffff3cd).withValues(alpha: .85 * amount),
            const Color(0xffffd781).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: origin, radius: r)),
    );
    for (var i = 0; i < 3; i++) {
      final lit = ((amount * 3 - i) * 2).clamp(0.0, 1.0);
      final p = artPoint(viewport, .73 + i * .08, .46 + i * .025);
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 22, height: 4),
        Paint()..color = const Color(0xffffe8af).withValues(alpha: lit * .8),
      );
    }
  }

  void _seeds(Canvas canvas, Size viewport, double amount) {
    final end = artPoint(viewport, .335, .425);
    final start = Offset(viewport.width * .5, viewport.height * .12);
    final center =
        Offset.lerp(start, end, amount)! +
        Offset(math.sin(amount * math.pi) * viewport.width * .12, 0);
    final edge = (viewport.shortestSide * .17).clamp(32.0, 78.0);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.sin(amount * math.pi) * .2);
    final parcel = Rect.fromCenter(
      center: Offset.zero,
      width: edge,
      height: edge * .8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(parcel, const Radius.circular(9)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffffe8ac), Color(0xffd99b41)],
        ).createShader(parcel),
    );
    canvas.drawLine(
      Offset(0, -edge * .4),
      Offset(0, edge * .4),
      Paint()
        ..color = const Color(0xff7e5935)
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, edge * .1),
          width: edge * .72,
          height: edge * .64,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xfff9f0d4),
    );
    _label(
      canvas,
      'ㄱ',
      Offset(0, edge * .1),
      edge * .48,
      const Color(0xff5b4631),
    );
    canvas.restore();
    if (amount > .8) {
      final r = edge * .8;
      canvas.drawCircle(
        end,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xffffe9ae).withValues(alpha: .12),
              const Color(0xffffe9ae).withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: end, radius: r)),
      );
    }
  }

  void _train(Canvas canvas, Size viewport, double amount) {
    final center = artPoint(
      viewport,
      mission.tracing ? .601 : .335,
      mission.tracing ? .583 : .577,
    );
    final scale = math.max(viewport.width / 1536, viewport.height / 1024);
    final plate = Rect.fromCenter(
      center: center,
      width: 295 * scale,
      height: 71 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, const Radius.circular(12)),
      Paint()..color = const Color(0xffffe6a6).withValues(alpha: .7 * amount),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, const Radius.circular(12)),
      Paint()
        ..color = const Color(0xfffff4c7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    _label(
      canvas,
      mission.tracing ? '나' : '가',
      center,
      58 * scale,
      const Color(0xff5b4631),
    );
    // A finite departure signal/steam response; the background train is still
    // an illustration, not a fabricated walking/driving sprite animation.
    if (elapsed < 1.6 && motion) {
      for (var i = 0; i < 4; i++) {
        final p = artPoint(
          viewport,
          .91 - amount * .13 - i * .025,
          .40 - amount * .19 - i * .025,
        );
        canvas.drawCircle(
          p,
          (10 + i * 5 + amount * 12) * scale,
          Paint()
            ..color = const Color(0xfffff8e7)
                .withValues(alpha: (1 - amount) * .65),
        );
      }
    }
    final lamp = artPoint(viewport, .91, .49);
    canvas.drawCircle(
      lamp,
      12 * scale,
      Paint()..color = const Color(0xffe9bc5b).withValues(alpha: amount),
    );
  }

  static void _label(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
  ) {
    final label = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Jua',
          fontSize: size,
          color: color,
          height: 1,
        ),
      ),
    )..layout();
    label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
    label.dispose();
  }

  @override
  void onDispose() {
    pauseEngine();
    dispose();
  }
}

class _LetterToken extends PositionComponent with TapCallbacks {
  final LetterMissionGame game;
  final int index;
  _LetterToken(this.game, this.index);
  @override
  void onTapUp(TapUpEvent event) => game.choose(index);
  @override
  void render(Canvas canvas) {
    if (game.mission.solved) return;
    final gate = game.mission.world == LetterWorld.flowerGate;
    final rect = Offset.zero & Size(size.x, size.y);
    final center = rect.center;
    final tree = game.mission.world == LetterWorld.seedTree;
    final train = game.mission.world == LetterWorld.soundTrain;
    if (!gate) {
      canvas.drawCircle(
        center + const Offset(0, 4),
        size.x * .48,
        Paint()..color = const Color(0xff27394e).withValues(alpha: .24),
      );
      if (tree) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center - Offset(0, size.y * .43),
            width: size.x * .35,
            height: size.y * .16,
          ),
          Paint()..color = const Color(0xff4b7751),
        );
      }
      if (train) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(12)),
          Paint()..color = const Color(0xffffe4a4),
        );
      }
      canvas.drawCircle(
        center,
        size.x * .46,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xfffff7df), Color(0xffeac97f)],
          ).createShader(rect),
      );
    }
    if (tree) {
      canvas.drawLine(
        center - Offset(0, size.y * .4),
        center - Offset(0, size.y * .64),
        Paint()
          ..color = const Color(0xff775235)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.save();
      canvas.translate(center.dx + size.x * .07, center.dy - size.y * .53);
      canvas.rotate(-.45);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.x * .36,
          height: size.y * .17,
        ),
        Paint()..color = const Color(0xff527c4d),
      );
      canvas.restore();
    }
    canvas.drawCircle(
      center,
      size.x * .47,
      Paint()
        ..color = game.mission.hintChoice == index
            ? const Color(0xff8e5b17)
            : const Color(0xffffe6a6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final text = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: game.mission.choices[index],
        style: TextStyle(
          fontFamily: 'Jua',
          fontSize: size.x * .55,
          color: const Color(0xff65492e),
          height: 1,
        ),
      ),
    )..layout();
    // Gate letters are already painted on the wooden plaques.
    if (!gate) {
      text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
    }
    text.dispose();
  }
}
