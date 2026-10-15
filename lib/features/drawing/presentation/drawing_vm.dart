import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/drawing_repository.dart';
import '../domain/drawing.dart';

final drawingProvider = AsyncNotifierProvider<DrawingVM, DrawingHistory>(
  DrawingVM.new,
);
final storyDrawingProvider = AsyncNotifierProvider<DrawingVM, DrawingHistory>(
  () => DrawingVM(draftKey: 'story-garden-draft'),
);

class DrawingVM extends AsyncNotifier<DrawingHistory> {
  final String draftKey;
  DrawingVM({this.draftKey = 'drawing-draft'});
  Future<void> _writes = Future.value();
  @override
  Future<DrawingHistory> build() async => DrawingHistory(
    current: await ref.read(drawingRepositoryProvider).draft(key: draftKey),
  );
  Future<void> _set(DrawingHistory next) {
    state = AsyncData(next);
    final repository = ref.read(drawingRepositoryProvider);
    final write = _writes
        .catchError((Object _) {})
        .then((_) => repository.saveDraft(next.current, key: draftKey));
    _writes = write;
    return write;
  }

  Future<void> add(DrawingLine line) => _set(
    state.requireValue.edit(
      DrawingDocument(
        lines: [...state.requireValue.current.lines, line],
        background: state.requireValue.current.background,
      ),
    ),
  );
  Future<void> undo() => _set(state.requireValue.undo());
  Future<void> redo() => _set(state.requireValue.redo());
  Future<void> clear() => _set(
    state.requireValue.edit(
      DrawingDocument(background: state.requireValue.current.background),
    ),
  );
  Future<void> background(int color) => _set(
    state.requireValue.edit(
      DrawingDocument(
        lines: state.requireValue.current.lines,
        background: color,
      ),
    ),
  );
  Future<void> load(DrawingDocument document) =>
      _set(DrawingHistory(current: document));
  Future<Artwork> save() async {
    await _writes;
    return ref.read(drawingRepositoryProvider).save(state.requireValue.current);
  }
}

final galleryProvider = AsyncNotifierProvider<GalleryVM, List<Artwork>>(
  GalleryVM.new,
);

class GalleryVM extends AsyncNotifier<List<Artwork>> {
  @override
  Future<List<Artwork>> build() => ref.read(drawingRepositoryProvider).list();
  Future<void> refresh() async {
    state = AsyncData(await ref.read(drawingRepositoryProvider).list());
  }

  Future<void> delete(String id) async {
    await ref.read(drawingRepositoryProvider).delete(id);
    await refresh();
  }
}
