import 'trace_engine.dart';

/// Dot tapping is an explicit readiness activity, never a letter shortcut.
class PrewritingStrategy extends TraceStrategy {
  const PrewritingStrategy(super.age);
  @override
  bool acceptsTap(StrokePath stroke) => stroke.length <= .05;
  @override
  double toleranceFor(StrokePath stroke) =>
      acceptsTap(stroke) ? .12 : super.toleranceFor(stroke);
  @override
  TraceResult evaluate(StrokePath stroke, List<TracePoint> input) {
    if (!acceptsTap(stroke)) return super.evaluate(stroke, input);
    final accepted =
        input.isNotEmpty &&
        input.every(
          (p) =>
              p.x.isFinite &&
              p.y.isFinite &&
              p.distance(const TracePoint(.5, .5)) <= .12,
        ) &&
        StrokePath(input).length <= .22;
    return TraceResult(
      accepted,
      accepted ? TraceFeedback.complete : TraceFeedback.startHere,
      accepted ? 1 : 0,
    );
  }
}
