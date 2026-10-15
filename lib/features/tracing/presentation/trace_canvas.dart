import 'package:flutter/material.dart';

import '../domain/trace_engine.dart';
import 'trace_vm.dart';

class TraceCanvas extends StatefulWidget {
  final List<StrokePath> strokes;
  final TraceState state;
  final double tolerance;
  final bool animate;
  final ValueChanged<List<TracePoint>> onStroke;
  const TraceCanvas({
    super.key,
    required this.strokes,
    required this.state,
    required this.tolerance,
    required this.onStroke,
    this.animate = true,
  });
  @override
  State<TraceCanvas> createState() => TraceCanvasState();
}

class TraceCanvasState extends State<TraceCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController demo = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  final current = <TracePoint>[];
  int? pointer;
  @override
  void dispose() {
    demo.dispose();
    super.dispose();
  }

  void demonstrate() {
    if (widget.animate) {
      demo.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final edge = c.biggest.shortestSide;
      TracePoint point(Offset p) =>
          TracePoint((p.dx / edge).clamp(0, 1), (p.dy / edge).clamp(0, 1));
      return Center(
        child: SizedBox(
          width: edge,
          height: edge,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Listener(
              onPointerDown: (e) {
                if (widget.state.done || pointer != null) return;
                pointer = e.pointer;
                setState(() {
                  current.clear();
                  current.add(point(e.localPosition));
                });
              },
              onPointerMove: (e) {
                if (pointer != e.pointer) return;
                setState(() {
                  current.add(point(e.localPosition));
                });
              },
              onPointerUp: (e) {
                if (pointer != e.pointer) return;
                final input = List<TracePoint>.from(current);
                setState(() {
                  pointer = null;
                  current.clear();
                });
                widget.onStroke(input);
              },
              onPointerCancel: (e) {
                if (pointer == e.pointer) {
                  setState(() {
                    pointer = null;
                    current.clear();
                  });
                }
              },
              child: AnimatedBuilder(
                animation: demo,
                builder: (context, _) => CustomPaint(
                  size: Size(edge, edge),
                  painter: _TracePainter(
                    widget.strokes,
                    widget.state,
                    current,
                    widget.tolerance,
                    demo.value,
                    widget.animate,
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
  final double tolerance, demo;
  final bool animate;
  _TracePainter(
    this.strokes,
    this.state,
    this.current,
    this.tolerance,
    this.demo,
    this.animate,
  );
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xfffffdf7), BlendMode.src);
    Offset p(TracePoint v) => Offset(v.x * size.width, v.y * size.height);
    void line(List<TracePoint> points, Color color, double width) {
      if (points.isEmpty) return;
      final path = Path()..moveTo(p(points.first).dx, p(points.first).dy);
      for (final v in points.skip(1)) {
        path.lineTo(p(v).dx, p(v).dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (var i = 0; i < strokes.length; i++) {
      line(
        strokes[i].points,
        i == state.strokeIndex
            ? const Color(0xffe2e8ba)
            : const Color(0xffeeeeee),
        size.width * tolerance * 1.6,
      );
      for (final v in strokes[i].samples(25)) {
        canvas.drawCircle(p(v), 2.5, Paint()..color = const Color(0xff8c9b72));
      }
    }
    if (!state.done) {
      final active = strokes[state.strokeIndex];
      canvas.drawCircle(
        p(active.points.first),
        14,
        Paint()..color = const Color(0xffffbc43),
      );
      final a = p(active.points.first), b = p(active.points[1]);
      final d = (b - a) / (b - a).distance;
      final tip = a + d * 48;
      canvas.drawLine(
        a + d * 18,
        tip,
        Paint()
          ..color = const Color(0xff456f67)
          ..strokeWidth = 4,
      );
      canvas.drawLine(
        tip,
        tip - d * 12 + Offset(-d.dy, d.dx) * 8,
        Paint()
          ..color = const Color(0xff456f67)
          ..strokeWidth = 4,
      );
      canvas.drawLine(
        tip,
        tip - d * 12 - Offset(-d.dy, d.dx) * 8,
        Paint()
          ..color = const Color(0xff456f67)
          ..strokeWidth = 4,
      );
      if (animate && demo > 0 && demo < 1) {
        final samples = active.samples(100);
        line(
          samples.take((samples.length * demo).ceil()).toList(),
          const Color(0xffe9a033),
          9,
        );
      }
    }
    for (final completed in state.completed) {
      line(completed, const Color(0xff376e64), 9);
    }
    line(current, const Color(0xff568fa7), 9);
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) => true;
}
