import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/drawing/domain/drawing.dart';
import 'package:flutter_application_1/features/drawing/data/drawing_repository.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';

void main() {
  test('undo redo and new edits maintain independent history', () {
    const a = DrawingDocument(
      lines: [
        DrawingLine([TracePoint(.2, .3)]),
      ],
    );
    var history = const DrawingHistory().edit(a);
    expect(history.undo().current.lines, isEmpty);
    expect(history.undo().redo().current.lines.length, 1);
    history = history.undo().edit(
      const DrawingDocument(background: 0xff000000),
    );
    expect(history.future, isEmpty);
  });
  test('draft survives new repository, retains strokes and eraser', () async {
    final store = MemoryStore();
    final repo = DrawingRepository(
      store,
      () => throw StateError('not required'),
    );
    const document = DrawingDocument(
      lines: [
        DrawingLine([TracePoint(.1, .2), TracePoint(.9, .8)], eraser: true),
      ],
    );
    await repo.saveDraft(document);
    final restored = await DrawingRepository(
      store,
      () => throw StateError('not required'),
    ).draft();
    expect(restored.lines.single.eraser, true);
    expect(restored.lines.single.points.last.x, .9);
  });
}
