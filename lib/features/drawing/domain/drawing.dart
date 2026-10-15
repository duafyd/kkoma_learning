import '../../tracing/domain/trace_engine.dart';

class DrawingLine {
  final List<TracePoint> points;
  final int color;
  final double width;
  final bool eraser;
  final String? stamp;
  const DrawingLine(
    this.points, {
    this.color = 0xff376e64,
    this.width = .012,
    this.eraser = false,
    this.stamp,
  });
  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'color': color,
    'width': width,
    'eraser': eraser,
    'stamp': stamp,
  };
  factory DrawingLine.fromJson(Map<String, dynamic> j) => DrawingLine(
    (j['points'] as List).map((p) => TracePoint.fromJson(p as List)).toList(),
    color: j['color'] as int,
    width: (j['width'] as num).toDouble(),
    eraser: j['eraser'] as bool? ?? false,
    stamp: j['stamp'] as String?,
  );
}

class DrawingDocument {
  final List<DrawingLine> lines;
  final int background;
  const DrawingDocument({this.lines = const [], this.background = 0xfffffdf7});
  Map<String, dynamic> toJson() => {
    'lines': lines.map((l) => l.toJson()).toList(),
    'background': background,
  };
  factory DrawingDocument.fromJson(Map<String, dynamic> j) => DrawingDocument(
    lines: (j['lines'] as List? ?? [])
        .map((l) => DrawingLine.fromJson(Map<String, dynamic>.from(l as Map)))
        .toList(),
    background: j['background'] as int? ?? 0xfffffdf7,
  );
}

class DrawingHistory {
  final List<DrawingDocument> past, future;
  final DrawingDocument current;
  const DrawingHistory({
    this.current = const DrawingDocument(),
    this.past = const [],
    this.future = const [],
  });
  DrawingHistory edit(DrawingDocument next) => DrawingHistory(
    current: next,
    past: [...past.skip(past.length > 49 ? past.length - 49 : 0), current],
  );
  DrawingHistory undo() => past.isEmpty
      ? this
      : DrawingHistory(
          current: past.last,
          past: past.sublist(0, past.length - 1),
          future: [...future, current],
        );
  DrawingHistory redo() => future.isEmpty
      ? this
      : DrawingHistory(
          current: future.last,
          past: [...past, current],
          future: future.sublist(0, future.length - 1),
        );
}

class Artwork {
  final String id, path;
  final DateTime created;
  final DrawingDocument document;
  const Artwork({
    required this.id,
    required this.path,
    required this.created,
    required this.document,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'created': created.toIso8601String(),
    'document': document.toJson(),
  };
  factory Artwork.fromJson(Map<String, dynamic> j) => Artwork(
    id: j['id'] as String,
    path: j['path'] as String,
    created: DateTime.parse(j['created'] as String),
    document: DrawingDocument.fromJson(
      Map<String, dynamic>.from(j['document'] as Map),
    ),
  );
}
