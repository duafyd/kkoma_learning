import 'dart:math' as math;
import 'dart:ui';

/// Screen geometry only; slot validity and ordering belong to StoryMachine.
class WorldMissionLayout {
  final Size size;
  final int count;
  final bool bridge;
  const WorldMissionLayout(this.size, this.count, this.bridge);
  double get artScale => math.max(size.width / 1536, size.height / 1024);
  Offset artPoint(Offset normalized) => Offset(
    normalized.dx * 1536 * artScale + (size.width - 1536 * artScale) / 2,
    normalized.dy * 1024 * artScale + (size.height - 1024 * artScale) * .575,
  );
  Rect restoration(int i) => Rect.fromCenter(
    center: artPoint(Offset([.44, .56, .675][i], .505)),
    width: 128 * artScale,
    height: 90 * artScale,
  );
  double get edge =>
      math.min(72, math.max(48, (size.width - 32 - (count - 1) * 8) / count));
  Rect source(int i) => Rect.fromCenter(
    center: Offset(
      size.width / 2 + (i - (count - 1) / 2) * (edge + 8),
      size.height - edge / 2 - 12,
    ),
    width: edge,
    height: edge,
  );
  Rect slot(int i) {
    final x = .14 + i * .18;
    final y = i.isEven ? .46 : .33;
    return Rect.fromCenter(
      center: bridge
          ? restoration(i).center
          : Offset(size.width * x, size.height * y),
      width: math.min(64, edge),
      height: math.min(64, edge),
    );
  }

  int? slotAt(Offset point) {
    int? nearest;
    var distance = double.infinity;
    for (var i = 0; i < count; i++) {
      final rect = slot(i);
      final d = (point - rect.center).distanceSquared;
      if (rect.inflate(5).contains(point) && d < distance) {
        nearest = i;
        distance = d;
      }
    }
    return nearest;
  }
}
