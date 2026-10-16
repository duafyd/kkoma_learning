import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/trace_engine.dart';
import '../domain/trace_coach.dart';
import 'trace_vm.dart';

class TraceCanvas extends StatefulWidget {
  final List<StrokePath> strokes;
  final TraceState state;
  final TraceStrategy strategy;
  final bool animate;
  final String? semanticLabel;
  final ValueChanged<List<TracePoint>> onStroke;
  final ValueChanged<TracePreview?>? onPreview;
  const TraceCanvas({
    super.key,
    required this.strokes,
    required this.state,
    required this.strategy,
    required this.onStroke,
    this.animate = true,
    this.semanticLabel,
    this.onPreview,
  });
  @override
  State<TraceCanvas> createState() => TraceCanvasState();
}

class TraceCanvasState extends State<TraceCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController demo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  final current = <TracePoint>[];
  int? pointer;
  TraceCoach? coach;
  TracePreview? preview;

  bool get motion => widget.animate && !MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) demonstrate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!motion) demo.stop();
  }

  @override
  void didUpdateWidget(covariant TraceCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.strokes != widget.strokes ||
        oldWidget.state.strokeIndex != widget.state.strokeIndex ||
        oldWidget.state.done != widget.state.done ||
        oldWidget.strategy.age.level != widget.strategy.age.level) {
      pointer = null;
      current.clear();
      coach = null;
      preview = null;
      demo.stop();
      demo.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onPreview?.call(null);
        demonstrate();
      });
    } else if (oldWidget.state != widget.state && pointer != null) {
      pointer = null;
      current.clear();
      preview = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPreview?.call(null);
      });
    } else if (!widget.animate) {
      demo.stop();
    }
  }

  @override
  void dispose() {
    demo.dispose();
    super.dispose();
  }

  void demonstrate() {
    if (!widget.state.done && pointer == null && motion) demo.forward(from: 0);
  }

  void track(TracePoint p) {
    current.add(p);
    preview = coach?.add(p);
    widget.onPreview?.call(preview);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final edge = c.biggest.shortestSide;
      TracePoint point(Offset p) => TracePoint(p.dx / edge, p.dy / edge);
      return Center(
        child: SizedBox(
          width: edge,
          height: edge,
          child: Semantics(
            label:
                widget.semanticLabel ??
                (widget.state.done
                    ? '글자를 완성했어요'
                    : '${widget.state.strokeIndex + 1}번째 획, 빛나는 시작점에서 화살표 방향으로 그려요'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Listener(
                onPointerDown: (e) {
                  if (widget.state.done || pointer != null) return;
                  demo.stop();
                  demo.value = 0;
                  pointer = e.pointer;
                  coach = TraceCoach(
                    widget.strokes[widget.state.strokeIndex],
                    widget.strategy,
                  );
                  setState(() {
                    current.clear();
                    track(point(e.localPosition));
                  });
                },
                onPointerMove: (e) {
                  if (pointer == e.pointer) {
                    setState(() => track(point(e.localPosition)));
                  }
                },
                onPointerUp: (e) {
                  if (pointer != e.pointer) return;
                  track(point(e.localPosition));
                  final input = List<TracePoint>.from(current);
                  setState(() {
                    pointer = null;
                    current.clear();
                    preview = null;
                  });
                  widget.onPreview?.call(null);
                  widget.onStroke(input);
                },
                onPointerCancel: (e) {
                  if (pointer != e.pointer) return;
                  setState(() {
                    pointer = null;
                    current.clear();
                    preview = null;
                  });
                  widget.onPreview?.call(null);
                },
                child: AnimatedBuilder(
                  animation: demo,
                  builder: (context, _) => CustomPaint(
                    size: Size(edge, edge),
                    painter: _TracePainter(
                      widget.strokes,
                      widget.state,
                      current,
                      widget.strategy,
                      motion && demo.isAnimating ? demo.value : null,
                      preview,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _TracePainter extends CustomPainter {
  final List<StrokePath> strokes;
  final TraceState state;
  final List<TracePoint> current;
  final TraceStrategy strategy;
  final double? demo;
  final TracePreview? preview;
  _TracePainter(
    this.strokes,
    this.state,
    this.current,
    this.strategy,
    this.demo,
    this.preview,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final edge = size.width;
    final inkWidth = (edge * .025).clamp(5.0, 14.0);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xfffffefa), Color(0xfff7f0df)],
        ).createShader(Offset.zero & size),
    );
    final grid = Paint()
      ..color = const Color(0xffe7dfce)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final v = edge * i / 4;
      canvas.drawLine(Offset(v, 0), Offset(v, edge), grid);
      canvas.drawLine(Offset(0, v), Offset(edge, v), grid);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(2),
        const Radius.circular(28),
      ),
      Paint()
        ..color = const Color(0xffd5c9ac)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    Offset p(TracePoint v) => Offset(v.x * edge, v.y * edge);
    Path path(List<TracePoint> points, {bool smooth = false}) {
      final result = Path();
      if (points.isEmpty) return result;
      result.moveTo(p(points.first).dx, p(points.first).dy);
      if (smooth && points.length > 2) {
        for (var i = 1; i < points.length - 1; i++) {
          final a = p(points[i]), b = p(points[i + 1]);
          final middle = (a + b) / 2;
          result.quadraticBezierTo(a.dx, a.dy, middle.dx, middle.dy);
        }
      }
      for (final v
          in smooth ? points.skip(points.length - 1) : points.skip(1)) {
        result.lineTo(p(v).dx, p(v).dy);
      }
      return result;
    }

    void line(
      List<TracePoint> points,
      Color color,
      double width, {
      bool smooth = false,
    }) {
      if (points.length == 1) {
        canvas.drawCircle(p(points.first), width / 2, Paint()..color = color);
      } else {
        canvas.drawPath(
          path(points, smooth: smooth),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    // Future strokes stay behind the active lane at shared intersections.
    for (var i = strokes.length - 1; i >= state.strokeIndex; i--) {
      final active = i == state.strokeIndex && !state.done;
      final corridor = edge * strategy.toleranceFor(strokes[i]) * 2;
      line(
        strokes[i].points,
        active ? const Color(0xfff3cf80) : const Color(0xffe3dece),
        math.max(corridor, 2),
      );
      if (active) {
        line(
          strokes[i].points,
          const Color(0xffffe8b1),
          math.max(2, corridor - 5),
        );
      }
      for (final v in strokes[i].samples(32)) {
        canvas.drawCircle(
          p(v),
          active ? 1.8 : 1.2,
          Paint()
            ..color = active
                ? const Color(0xffb08643)
                : const Color(0xffbdb4a2),
        );
      }
    }
    for (final completed in state.completed) {
      line(completed, const Color(0xffaac9b6), inkWidth + 4, smooth: true);
      line(completed, const Color(0xff347966), inkWidth, smooth: true);
    }
    if (!state.done && strategy.acceptsTap(strokes[state.strokeIndex])) {
      canvas.drawCircle(
        const Offset(.5, .5) * edge,
        edge * .12,
        Paint()..color = const Color(0xffffe1a1),
      );
      canvas.drawCircle(
        const Offset(.5, .5) * edge,
        edge * .055,
        Paint()..color = const Color(0xffdd9b30),
      );
    } else if (!state.done) {
      final active = strokes[state.strokeIndex];
      final samples = active.samples(100);
      final total = active.length * edge;
      // Arc-length positions also work for circles/curves whose first segment
      // is tiny; never infer direction from a single tessellation segment.
      final tipIndex = (math.min(55.0, total * .65) / total * 100)
          .round()
          .clamp(2, 65);
      final tip = p(samples[tipIndex]);
      final before = p(samples[math.max(0, tipIndex - 5)]);
      final direction = (tip - before).distance > .01
          ? (tip - before) / (tip - before).distance
          : const Offset(0, 1);
      final compact = total < 64;
      final a = p(samples.first), end = p(samples.last);
      final tangent = p(samples[2]) - a;
      final unit = tangent.distance > 0
          ? tangent / tangent.distance
          : const Offset(0, 1);
      final badge = a + Offset(-unit.dy, unit.dx) * (compact ? 24 : 22);
      final badgeCenter = Offset(
        badge.dx.clamp(16.0, edge - 16),
        badge.dy.clamp(16.0, edge - 16),
      );
      canvas.drawCircle(
        end,
        compact ? 5 : 9,
        Paint()..color = const Color(0xff8fbaa3),
      );
      canvas.drawCircle(end, compact ? 2 : 4, Paint()..color = Colors.white);
      line(
        samples
            .skip((tipIndex * .35).round())
            .take((tipIndex * .65).ceil() + 1)
            .toList(),
        const Color(0xff886b35),
        compact ? 2.5 : 3.5,
      );
      final arrow = math.min(10.0, total * .15);
      final perpendicular = Offset(-direction.dy, direction.dx);
      canvas.drawPath(
        Path()
          ..moveTo(
            (tip - direction * arrow + perpendicular * arrow * .65).dx,
            (tip - direction * arrow + perpendicular * arrow * .65).dy,
          )
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(
            (tip - direction * arrow - perpendicular * arrow * .65).dx,
            (tip - direction * arrow - perpendicular * arrow * .65).dy,
          ),
        Paint()
          ..color = const Color(0xff886b35)
          ..strokeWidth = compact ? 2.5 : 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        a,
        badgeCenter,
        Paint()
          ..color = const Color(0xffc79943)
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        a,
        compact ? 5 : 8,
        Paint()..color = const Color(0xffefb34f),
      );
      canvas.drawCircle(
        badgeCenter,
        14,
        Paint()..color = const Color(0xffc58b32),
      );
      final number = TextPainter(
        text: TextSpan(
          text: '${state.strokeIndex + 1}',
          style: const TextStyle(
            fontFamily: 'Jua',
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      number.paint(
        canvas,
        badgeCenter - Offset(number.width / 2, number.height / 2),
      );
      if (demo != null && current.isEmpty) {
        final shown = samples.take(math.max(1, (101 * demo!).ceil())).toList();
        line(shown, const Color(0xff449b8d), inkWidth);
        final head = p(shown.last);
        canvas.drawCircle(
          head,
          inkWidth + 7,
          Paint()..color = const Color(0x443e9a88),
        );
        canvas.drawCircle(head, inkWidth * .65, Paint()..color = Colors.white);
        canvas.drawCircle(
          head,
          inkWidth * .3,
          Paint()..color = const Color(0xff347966),
        );
      }
    }
    final color = preview == null || preview!.onPath
        ? const Color(0xff3b8e9f)
        : const Color(0xffb78b4b);
    line(current, color.withValues(alpha: .15), inkWidth + 8, smooth: true);
    line(current, color, inkWidth, smooth: true);
    if (current.isNotEmpty) {
      canvas.drawCircle(
        p(current.last),
        inkWidth * .35,
        Paint()..color = const Color(0xfff8fffd),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) => true;
}
