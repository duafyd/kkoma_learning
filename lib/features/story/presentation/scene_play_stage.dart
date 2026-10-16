import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../domain/scene_play.dart';

/// Flame owns rendering and hit testing only. Collected props come exclusively
/// from committed StorySnapshot state; a tap cannot award itself a reward.
class ScenePlayStage extends StatefulWidget {
  final ScenePlay play;
  final int count;
  final List<int> found;
  final bool animate, active;
  final ValueChanged<int> onDiscover;
  const ScenePlayStage({
    super.key,
    required this.play,
    required this.count,
    required this.found,
    required this.animate,
    required this.active,
    required this.onDiscover,
  });
  @override
  State<ScenePlayStage> createState() => _ScenePlayStageState();
}

class _ScenePlayStageState extends State<ScenePlayStage> {
  late final ScenePlayGame game = ScenePlayGame(
    kind: widget.play.kind,
    count: widget.count,
    found: widget.found,
    onDiscover: (i) => widget.onDiscover(i),
  );

  void sync() => game.synchronize(
    widget.found,
    animate: widget.animate && !MediaQuery.disableAnimationsOf(context),
    active: widget.active && TickerMode.valuesOf(context).enabled,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(covariant ScenePlayStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final rects = ScenePlayGame.targets(
        Size(c.maxWidth, c.maxHeight),
        widget.count,
      );
      return Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: GameWidget<ScenePlayGame>(
                game: game,
                autofocus: false,
                errorBuilder: (context, error) => Stack(
                  children: [
                    for (var i = 0; i < widget.count; i++)
                      Positioned.fromRect(
                        rect: rects[i],
                        child: IconButton.filledTonal(
                          tooltip: widget.play.object,
                          onPressed: widget.found.contains(i)
                              ? null
                              : () => widget.onDiscover(i),
                          icon: Icon(
                            widget.found.contains(i)
                                ? Icons.check
                                : Icons.auto_awesome,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Semantics do not intercept ordinary pointers: those go through Flame's
          // component dispatcher. Screen readers have the same large target areas.
          for (var i = 0; i < widget.count; i++)
            Positioned.fromRect(
              rect: rects[i],
              child: Semantics(
                key: ValueKey('scene-prop-$i'),
                button: true,
                label: '${widget.play.object} ${i + 1}',
                value: widget.found.contains(i) ? '찾았어요' : '눌러서 찾기',
                enabled: !widget.found.contains(i),
                onTap: widget.found.contains(i)
                    ? null
                    : () => widget.onDiscover(i),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      );
    },
  );
}

class ScenePlayGame extends FlameGame {
  final ScenePropKind kind;
  final int count;
  final ValueChanged<int> onDiscover;
  Set<int> found;
  final props = <_SceneProp>[];
  bool motion = true, active = true;
  double remaining = 0, clock = 0;
  ScenePlayGame({
    required this.kind,
    required this.count,
    required List<int> found,
    required this.onDiscover,
  }) : found = found.toSet();

  static List<Rect> targets(Size size, int count) {
    final edge = math.min(
      84.0,
      math.min(size.height, size.width / (count + 1)),
    );
    return List.generate(
      count,
      (i) => Rect.fromCenter(
        center: Offset(
          size.width * (i + 1) / (count + 1),
          (size.height * (i.isEven ? .18 : .24)).clamp(
            edge / 2,
            size.height - edge / 2,
          ),
        ),
        width: edge,
        height: edge,
      ),
    );
  }

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await add(_SceneLight(this));
    for (var i = 0; i < count; i++) {
      final prop = _SceneProp(this, i);
      props.add(prop);
      await add(prop);
    }
    _layout();
    remaining = motion && active ? 1.1 : 0;
  }

  void synchronize(
    List<int> committed, {
    required bool animate,
    required bool active,
  }) {
    final next = committed.toSet();
    final additions = next.difference(found);
    found = next;
    motion = animate;
    this.active = active;
    if (!motion || !active) {
      for (final prop in props) {
        prop.burst = 0;
      }
    }
    if (!active) {
      remaining = 0;
      pauseEngine();
      return;
    }
    for (final prop in props) {
      if (additions.contains(prop.index)) prop.burst = motion ? 1 : 0;
    }
    remaining = motion && additions.isNotEmpty ? 1.2 : 0;
    // One update is necessary even with motion disabled, to repaint committed
    // state and process any pending component mounts. Then the engine sleeps.
    if (isAttached) resumeEngine();
  }

  void _layout() {
    final areas = targets(Size(size.x, size.y), count);
    for (var i = 0; i < props.length; i++) {
      props[i]
        ..position = Vector2(areas[i].left, areas[i].top)
        ..size = Vector2(areas[i].width, areas[i].height);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layout();
  }

  @override
  void update(double dt) {
    clock += dt;
    super.update(dt);
    remaining = math.max(0, remaining - dt);
    if (!active || remaining == 0) pauseEngine();
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    // Restore is silent and static; never replay a burst after backgrounding.
    if (state != AppLifecycleState.resumed) {
      remaining = 0;
      for (final prop in props) {
        prop.burst = 0;
      }
      pauseEngine();
    }
  }

  @override
  void onDispose() {
    pauseEngine();
    dispose();
  }
}

class _SceneProp extends PositionComponent with TapCallbacks {
  final ScenePlayGame stage;
  final int index;
  double burst = 0;
  _SceneProp(this.stage, this.index);

  @override
  void onTapUp(TapUpEvent event) {
    if (stage.active && !stage.found.contains(index)) stage.onDiscover(index);
  }

  @override
  void update(double dt) {
    super.update(dt);
    burst = math.max(0, burst - dt);
  }

  @override
  void render(Canvas canvas) {
    final collected = stage.found.contains(index);
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x * .29;
    final phase = stage.motion && stage.remaining > 0
        ? math.sin(stage.clock * 3 + index)
        : 0.0;
    canvas.save();
    canvas.translate(center.dx, center.dy + phase * 3);
    final color = [
      const Color(0xffffd87a),
      const Color(0xff9be5ce),
      const Color(0xffbdb3ff),
    ][index % 3];
    canvas.drawCircle(
      Offset.zero,
      radius * 1.55,
      Paint()
        ..shader =
            RadialGradient(
              colors: [color.withValues(alpha: .5), color.withValues(alpha: 0)],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: radius * 1.55),
            ),
    );
    if (collected) {
      canvas.drawCircle(
        Offset.zero,
        radius * .14,
        Paint()..color = const Color(0xfffff2bf),
      );
    } else {
      canvas.rotate(phase * .06);
      _drawObject(canvas, radius, color);
      canvas.drawCircle(
        Offset(-radius * .15, -radius * .24),
        radius * .09,
        Paint()..color = Colors.white.withValues(alpha: .85),
      );
    }
    if (burst > 0) {
      for (var i = 0; i < 10; i++) {
        final angle = i * math.pi / 5;
        final distance = radius * (1 + (1 - burst) * 1.5);
        canvas.drawCircle(
          Offset(math.cos(angle), math.sin(angle)) * distance,
          3 * burst,
          Paint()..color = color.withValues(alpha: burst),
        );
      }
    }
    canvas.restore();
    if (burst > 0) {
      // A committed prop travels back into the story, rather than becoming
      // a dashboard checkbox. The route is recalculated on viewport resize.
      final start = center;
      final end = Offset(
        stage.size.x * .5 - position.x,
        stage.size.y * .66 - position.y,
      );
      final t = Curves.easeInOut.transform(1 - burst);
      final control = Offset(
        (start.dx + end.dx) / 2 - 35,
        math.min(start.dy, end.dy) - 45,
      );
      final at =
          start * ((1 - t) * (1 - t)) +
          control * (2 * t * (1 - t)) +
          end * (t * t);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(.8 - t * .5);
      _drawObject(canvas, radius, color);
      canvas.restore();
    }
  }

  void _drawObject(Canvas c, double r, Color color) {
    final p = Paint()..color = color;
    final outline = Paint()
      ..color = const Color(0xff665374)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    switch (stage.kind) {
      case ScenePropKind.star:
      case ScenePropKind.comet:
        for (var i = 0; i < 10; i++) {
          final a = i * math.pi / 5 - math.pi / 2;
          final d = i.isEven ? r : r * .48;
          if (i == 0) {
            path.moveTo(math.cos(a) * d, math.sin(a) * d);
          } else {
            path.lineTo(math.cos(a) * d, math.sin(a) * d);
          }
        }
        path.close();
      case ScenePropKind.flower:
        for (var i = 0; i < 5; i++) {
          final a = i * math.pi * 2 / 5;
          c.drawCircle(Offset(math.cos(a), math.sin(a)) * r * .58, r * .46, p);
        }
        c.drawCircle(
          Offset.zero,
          r * .35,
          Paint()..color = const Color(0xffffb24e),
        );
        return;
      case ScenePropKind.fruit:
        path.addOval(
          Rect.fromCenter(
            center: Offset(0, r * .12),
            width: r * 1.6,
            height: r * 1.7,
          ),
        );
        c.drawOval(
          Rect.fromLTWH(0, -r, r * .8, r * .45),
          Paint()..color = const Color(0xff7bb583),
        );
      case ScenePropKind.drop:
      case ScenePropKind.leaf:
        path.moveTo(0, -r);
        path.cubicTo(r * 1.5, r * .3, r * .8, r, 0, r);
        path.cubicTo(-r * .9, r, -r * 1.2, r * .1, 0, -r);
      case ScenePropKind.stone:
        path.moveTo(-r, r * .5);
        path.lineTo(-r * .65, -r * .55);
        path.lineTo(r * .25, -r * .8);
        path.lineTo(r, r * .1);
        path.lineTo(r * .7, r * .65);
        path.close();
      case ScenePropKind.ticket:
      case ScenePropKind.page:
      case ScenePropKind.book:
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(-r * .85, -r, r * .85, r),
            const Radius.circular(5),
          ),
        );
      case ScenePropKind.beacon:
      case ScenePropKind.lantern:
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(-r * .65, -r * .7, r * .65, r * .85),
            const Radius.circular(7),
          ),
        );
        c.drawArc(
          Rect.fromCircle(center: Offset(0, -r * .65), radius: r * .4),
          math.pi,
          math.pi,
          false,
          outline,
        );
    }
    c.drawShadow(path, const Color(0xff222340), 3, false);
    c.drawPath(path, p);
    c.drawPath(path, outline);
    if ([
      ScenePropKind.ticket,
      ScenePropKind.page,
      ScenePropKind.book,
    ].contains(stage.kind)) {
      for (var i = 0; i < 3; i++) {
        c.drawLine(
          Offset(-r * .4, r * (-.4 + i * .4)),
          Offset(r * .4, r * (-.4 + i * .4)),
          outline,
        );
      }
    }
  }
}

/// Soft connecting light is part of the scene, below props and Flutter actors.
/// It remains static after a bounded reaction; no idle particle emitter runs.
class _SceneLight extends Component {
  final ScenePlayGame stage;
  _SceneLight(this.stage);
  @override
  void render(Canvas canvas) {
    if (stage.found.isEmpty) return;
    final goal = Offset(stage.size.x * .5, stage.size.y * .66);
    final radius = math.min(stage.size.x, stage.size.y) * .42;
    final rect = Rect.fromCircle(center: goal, radius: radius);
    final all = stage.found.length == stage.count;
    canvas.drawCircle(
      goal,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(all ? 0x70ffe7a0 : 0x35ffe7a0),
            const Color(0x00ffe7a0),
          ],
        ).createShader(rect),
    );
    final areas = ScenePlayGame.targets(
      Size(stage.size.x, stage.size.y),
      stage.count,
    );
    for (final i in stage.found) {
      if (i < 0 || i >= areas.length) continue;
      final start = areas[i].center;
      final ribbon = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(goal.dx - 35, start.dy - 45, goal.dx, goal.dy);
      canvas.drawPath(
        ribbon,
        Paint()
          ..color = const Color(0x33ffefbb)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    if (all) {
      for (var i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5;
        final at =
            goal + Offset(math.cos(angle), math.sin(angle)) * radius * .23;
        canvas.drawCircle(at, 3, Paint()..color = const Color(0xfffff4d1));
      }
    }
  }
}
