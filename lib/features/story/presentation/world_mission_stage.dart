import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../domain/world_mission.dart';
import 'world_mission_layout.dart';

class WorldMissionStage extends StatefulWidget {
  final WorldMission mission;
  final List<int> placed;
  final bool solved, animate, active;
  final Future<void> Function(int, int) onPlace;
  final ValueChanged<double> onJourney;
  const WorldMissionStage({
    super.key,
    required this.mission,
    required this.placed,
    required this.solved,
    required this.animate,
    required this.active,
    required this.onPlace,
    required this.onJourney,
  });
  @override
  State<WorldMissionStage> createState() => _WorldMissionStageState();
}

class _WorldMissionStageState extends State<WorldMissionStage> {
  late final WorldMissionGame game = WorldMissionGame(
    mission: widget.mission,
    placed: widget.placed,
    solved: widget.solved,
    onPlace: request,
    onJourney: reportJourney,
  );

  void reportJourney(double value) {
    // This stage and the actors are siblings; synchronization may run in build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onJourney(value);
    });
  }

  Future<void> request(int piece, int slot) async {
    if (!mounted || !widget.active) return;
    try {
      await widget.onPlace(piece, slot);
    } finally {
      if (mounted) game.finishRequest();
    }
  }

  void sync() => game.synchronize(
    widget.placed,
    solved: widget.solved,
    motion: widget.animate && !MediaQuery.disableAnimationsOf(context),
    active: widget.active && TickerMode.valuesOf(context).enabled,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(covariant WorldMissionStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final layout = WorldMissionLayout(
        bounds.biggest,
        widget.mission.count,
        widget.mission.bridge,
      );
      return Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: GameWidget<WorldMissionGame>(
                game: game,
                autofocus: false,
                errorBuilder: (_, _) => const Center(
                  child: Text(
                    '아래 ‘버튼으로 놓기’로 함께 해요.',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xe62b4350),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  widget.solved
                      ? widget.mission.resolution
                      : widget.placed.length == widget.mission.count
                      ? widget.mission.assembled
                      : widget.mission.instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Jua',
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
          if (!widget.solved)
            for (var i = 0; i < widget.mission.count; i++) ...[
              Positioned.fromRect(
                rect: layout.source(i),
                child: Semantics(
                  key: ValueKey('world-piece-$i'),
                  button: true,
                  label: '${widget.mission.artwork.objectName} ${i + 1}',
                  value: widget.placed.contains(i) ? '놓았어요' : '다음 빛나는 자리에 놓기',
                  enabled: widget.active && !widget.placed.contains(i),
                  onTap: widget.active && !widget.placed.contains(i)
                      ? () => game.requestPlacement(i, widget.placed.length)
                      : null,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned.fromRect(
                rect: layout.slot(i),
                child: Semantics(
                  key: ValueKey('world-slot-$i'),
                  label: '${widget.mission.artwork.objectName} 자리 ${i + 1}',
                  value: i < widget.placed.length ? '채웠어요' : '빈자리',
                  child: const SizedBox.expand(),
                ),
              ),
            ],
        ],
      );
    },
  );
}

/// Drag previews never mutate placed. Only the committed snapshot can light a
/// slot. The engine sleeps on idle; pointer movement wakes it for one repaint.
class WorldMissionGame extends FlameGame {
  final WorldMission mission;
  final Future<void> Function(int, int) onPlace;
  final ValueChanged<double> onJourney;
  List<int> placed;
  bool solved, motion = true, active = true;
  bool backgrounded = false;
  bool get interactive => active && !backgrounded;
  int? dragging, dragPointer, pending;
  Offset? dragPoint;
  double remaining = 0, journey = 1, pulse = 0;
  final pieces = <_MissionPiece>[];
  WorldMissionGame({
    required this.mission,
    required List<int> placed,
    required this.solved,
    required this.onPlace,
    required this.onJourney,
  }) : placed = List.of(placed);
  WorldMissionLayout get layout =>
      WorldMissionLayout(Size(size.x, size.y), mission.count, mission.bridge);

  @override
  Color backgroundColor() => Colors.transparent;
  @override
  Future<void> onLoad() async {
    await add(_MissionScenery(this));
    for (var i = 0; i < mission.count; i++) {
      final piece = _MissionPiece(this, i);
      pieces.add(piece);
      await add(piece);
    }
    _layout();
    journey = solved ? 1 : 0;
    onJourney(journey);
  }

  void wake([double seconds = 0]) {
    remaining = math.max(remaining, seconds);
    if (isAttached && interactive) resumeEngine();
  }

  void synchronize(
    List<int> committed, {
    required bool solved,
    required bool motion,
    required bool active,
  }) {
    final grew = committed.length > placed.length;
    final resolved = !this.solved && solved;
    placed = List.of(committed);
    if (placed.contains(dragging)) {
      dragging = dragPointer = null;
      dragPoint = null;
    }
    this.solved = solved;
    this.motion = motion;
    this.active = active;
    if (!interactive || !motion) {
      pulse = 0;
      journey = solved ? 1 : 0;
      dragging = dragPointer = null;
      dragPoint = null;
      remaining = 0;
      onJourney(journey);
    } else if (resolved) {
      journey = 0;
      pulse = 1;
    } else if (grew) {
      pulse = 1;
    }
    if (!interactive) {
      pauseEngine();
      return;
    }
    wake(
      motion && resolved
          ? 2.8
          : motion && grew
          ? .8
          : 0,
    );
  }

  void requestPlacement(int piece, int slot) {
    if (!interactive ||
        solved ||
        pending != null ||
        placed.contains(piece) ||
        piece < 0 ||
        piece >= mission.count) {
      return;
    }
    pending = piece;
    wake();
    // The widget catches persistence errors and presents the existing retry UI.
    onPlace(piece, slot);
  }

  void finishRequest() {
    pending = null;
    wake();
  }

  bool beginDrag(int piece, int pointer, Offset at) {
    if (!interactive ||
        solved ||
        pending != null ||
        dragging != null ||
        placed.contains(piece) ||
        piece < 0 ||
        piece >= mission.count) {
      return false;
    }
    dragging = piece;
    dragPointer = pointer;
    dragPoint = at;
    wake();
    return true;
  }

  void moveDrag(int pointer, Offset at) {
    if (pointer != dragPointer || !at.dx.isFinite || !at.dy.isFinite) return;
    dragPoint = at;
    wake();
  }

  void endDrag(int pointer, {bool cancel = false}) {
    if (pointer != dragPointer) return;
    final piece = dragging!, slot = layout.slotAt(dragPoint!);
    dragging = dragPointer = null;
    dragPoint = null;
    if (!cancel && slot != null) requestPlacement(piece, slot);
    wake();
  }

  void _layout() {
    for (final piece in pieces) {
      final rect = layout.source(piece.index);
      piece
        ..position = Vector2(rect.left, rect.top)
        ..size = Vector2(rect.width, rect.height);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    dragging = dragPointer = null;
    dragPoint = null;
    _layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    pulse = math.max(0, pulse - dt * 1.3);
    if (solved && motion && journey < 1) {
      journey = math.min(1, journey + dt / 2.4);
      onJourney(Curves.easeInOut.transform(journey));
    }
    remaining = math.max(0, remaining - dt);
    // Drags repaint on input, not with an unbounded game loop.
    if (!interactive || remaining == 0) pauseEngine();
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    backgrounded = state != AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed) {
      dragging = dragPointer = null;
      dragPoint = null;
      pulse = 0;
      journey = solved ? 1 : 0;
      remaining = 0;
      pauseEngine();
    }
  }

  @override
  void onDispose() {
    pauseEngine();
    dispose();
  }
}

class _MissionPiece extends PositionComponent with TapCallbacks, DragCallbacks {
  final WorldMissionGame stage;
  final int index;
  int? captured;
  _MissionPiece(this.stage, this.index);
  @override
  void onTapUp(TapUpEvent event) =>
      stage.requestPlacement(index, stage.placed.length);
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (stage.beginDrag(
      index,
      event.pointerId,
      Offset(event.canvasPosition.x, event.canvasPosition.y),
    )) {
      captured = event.pointerId;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (captured != event.pointerId) return;
    stage.moveDrag(
      event.pointerId,
      Offset(event.canvasStartPosition.x, event.canvasStartPosition.y),
    );
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (captured == event.pointerId) {
      stage.endDrag(event.pointerId);
      captured = null;
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    // Clear the stage before the mixin forwards cancel to end.
    if (captured == event.pointerId) {
      stage.endDrag(event.pointerId, cancel: true);
      captured = null;
    }
    super.onDragCancel(event);
  }
}

class _MissionScenery extends Component {
  final WorldMissionGame stage;
  _MissionScenery(this.stage);
  @override
  void render(Canvas canvas) {
    final l = stage.layout, n = stage.mission.count;
    final fill = stage.solved ? n : stage.placed.length;
    canvas.drawRect(
      Offset.zero & l.size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x33304057),
            const Color(0x002c404c),
            const Color(0x9922383b),
          ],
        ).createShader(Offset.zero & l.size),
    );
    final road = Path()..moveTo(l.slot(0).center.dx, l.slot(0).center.dy);
    for (var i = 1; i < n; i++) {
      road.lineTo(l.slot(i).center.dx, l.slot(i).center.dy);
    }
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0x80445564)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stage.mission.bridge ? 2 : 5
        ..strokeCap = StrokeCap.round,
    );
    if (fill > 1) {
      final lit = Path()..moveTo(l.slot(0).center.dx, l.slot(0).center.dy);
      for (var i = 1; i < fill; i++) {
        lit.lineTo(l.slot(i).center.dx, l.slot(i).center.dy);
      }
      canvas.drawPath(
        lit,
        Paint()
          ..color = const Color(0xffffe9a6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var i = 0; i < n; i++) {
      final rect = l.slot(i),
          filled = i < fill,
          next = i == fill && !stage.solved;
      canvas.drawOval(
        rect.deflate(3),
        Paint()
          ..color = filled
              ? stage.mission.bridge
                    ? const Color(0x18ffeeb4)
                    : const Color(0x66ffeeb4)
              : const Color(0x9930454e),
      );
      canvas.drawOval(
        rect.deflate(3),
        Paint()
          ..color = next ? const Color(0xffffd675) : const Color(0x9996b9b5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = next ? 3 : 1.5,
      );
      if (filled && !stage.mission.bridge) {
        _object(canvas, rect.center, rect.width * .32, stage.mission.bridge);
      } else if (!filled) {
        _label(canvas, '${i + 1}', rect.center, const Color(0xfff5e7ba), 20);
      }
      if (stage.pulse > 0 && i == fill - 1) {
        canvas.drawCircle(
          rect.center,
          rect.width * (.5 + (1 - stage.pulse) * .35),
          Paint()
            ..color = Color.fromRGBO(255, 235, 161, stage.pulse * .6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
    if (!stage.solved) {
      final tray = Rect.fromLTRB(
        8,
        l.source(0).top - 6,
        l.size.width - 8,
        l.size.height - 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tray, const Radius.circular(20)),
        Paint()..color = const Color(0xeafff5dd),
      );
      for (var i = 0; i < n; i++) {
        final rect = l.source(i);
        if (stage.placed.contains(i)) {
          canvas.drawCircle(
            rect.center,
            4,
            Paint()..color = const Color(0xff9bb7a8),
          );
        } else if (stage.dragging != i) {
          _object(
            canvas,
            rect.center,
            rect.width * .3,
            stage.mission.bridge,
            pending: stage.pending == i,
          );
        }
      }
    } else if (!stage.mission.bridge) {
      // The restored constellation shines toward the library, without flashing.
      final center = l.slot(2).center;
      canvas.drawCircle(
        center,
        l.size.shortestSide * .38,
        Paint()
          ..shader =
              RadialGradient(
                colors: [const Color(0x50ffeab0), const Color(0x00ffeab0)],
              ).createShader(
                Rect.fromCircle(
                  center: center,
                  radius: l.size.shortestSide * .38,
                ),
              ),
      );
    }
    if (stage.dragPoint case final point?) {
      _object(canvas, point, l.edge * .34, stage.mission.bridge);
    }
  }
}

void _label(
  Canvas canvas,
  String text,
  Offset center,
  Color color,
  double size,
) {
  final label = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Jua', color: color, fontSize: size),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
}

void _object(
  Canvas canvas,
  Offset center,
  double r,
  bool stone, {
  bool pending = false,
}) {
  final path = Path();
  if (stone) {
    path.moveTo(center.dx - r, center.dy + r * .3);
    path.cubicTo(
      center.dx - r,
      center.dy - r,
      center.dx + r * .7,
      center.dy - r,
      center.dx + r,
      center.dy + r * .2,
    );
    path.quadraticBezierTo(
      center.dx + r * .7,
      center.dy + r * .8,
      center.dx - r * .7,
      center.dy + r * .7,
    );
    path.close();
  } else {
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5 - math.pi / 2, d = i.isEven ? r : r * .48;
      final point = center + Offset(math.cos(a), math.sin(a)) * d;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
  }
  final rect = Rect.fromCircle(center: center, radius: r);
  canvas.drawShadow(path, const Color(0x992b363b), 4, false);
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: stone
            ? [const Color(0xffffe7b9), const Color(0xffbca782)]
            : [const Color(0xffffedb4), const Color(0xffe7b357)],
      ).createShader(rect),
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = stone ? const Color(0xff8b7654) : const Color(0xffbc8643)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  if (pending) _label(canvas, '…', center, const Color(0xff3d5b56), r);
}
