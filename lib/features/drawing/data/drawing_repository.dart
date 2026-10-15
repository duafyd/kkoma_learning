import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/providers.dart';
import '../../../core/storage/local_store.dart';
import '../domain/drawing.dart';
import '../domain/drawing_renderer.dart';

final artworkDirectoryProvider = FutureProvider<Directory>(
  (ref) async =>
      Directory('${(await getApplicationDocumentsDirectory()).path}/artworks')
        ..createSync(recursive: true),
);
final drawingRepositoryProvider = Provider(
  (ref) => DrawingRepository(
    ref.watch(storeProvider),
    () => ref.read(artworkDirectoryProvider.future),
  ),
);

class DrawingRepository {
  final LocalStore store;
  final Future<Directory> Function() directory;
  Future<void> _operations = Future.value();
  DrawingRepository(this.store, this.directory);
  Future<T> _exclusive<T>(Future<T> Function() action) {
    final next = _operations.then((_) => action());
    _operations = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<DrawingDocument> draft() async =>
      DrawingDocument.fromJson(await store.read('drawing-draft') ?? {});
  Future<void> saveDraft(DrawingDocument d) =>
      store.write('drawing-draft', d.toJson());
  Future<List<Artwork>> list() => _exclusive(_list);
  Future<List<Artwork>> _list() async {
    final items = ((await store.read('artworks'))?['items'] as List? ?? [])
        .map((j) => Artwork.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
    if (items.isEmpty) return items;
    final dir = await directory();
    for (final art in items) {
      final file = File(art.path), staged = File('${art.path}.deleting');
      // Recover an interrupted delete only if its metadata still exists.
      if (file.absolute.parent.path == dir.absolute.path &&
          !await file.exists() &&
          await staged.exists()) {
        await staged.rename(file.path);
      }
    }
    return items;
  }

  Future<Artwork> save(DrawingDocument document) =>
      _exclusive(() => _save(document));
  Future<Artwork> _save(DrawingDocument document) async {
    final dir = await directory(),
        id = 'art-${DateTime.now().microsecondsSinceEpoch}';
    final file = File('${dir.path}/$id.png');
    final recorder = ui.PictureRecorder();
    DrawingPainter(document)
        .paint(ui.Canvas(recorder), const ui.Size(1200, 900));
    final picture = recorder.endRecording(),
        image = await picture.toImage(1200, 900).whenComplete(picture.dispose);
    final data = await image
        .toByteData(format: ui.ImageByteFormat.png)
        .whenComplete(image.dispose);
    if (data == null) throw const FileSystemException('PNG 생성 실패');
    final artwork = Artwork(
      id: id,
      path: file.path,
      created: DateTime.now(),
      document: document,
    );
    try {
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      final items = await _list();
      await store.write('artworks', {
        'items': [...items, artwork].map((a) => a.toJson()).toList(),
      });
    } catch (_) {
      if (await file.exists()) await file.delete();
      rethrow;
    }
    return artwork;
  }

  Future<void> delete(String id) => _exclusive(() => _delete(id));
  Future<void> _delete(String id) async {
    final items = await _list(), matches = items.where((a) => a.id == id);
    if (matches.isEmpty) return;
    final dir = await directory(), file = File(matches.first.path);
    if (file.absolute.parent.path != dir.absolute.path) {
      throw const FileSystemException('작품 경로 오류');
    }
    final originalPath = file.path;
    File? staged;
    if (await file.exists()) {
      staged = await file.rename('$originalPath.deleting');
    }
    try {
      await store.write('artworks', {
        'items': items.where((a) => a.id != id).map((a) => a.toJson()).toList(),
      });
    } catch (_) {
      if (staged != null) await staged.rename(originalPath);
      rethrow;
    }
    if (staged != null) {
      try {
        await staged.delete();
      } catch (_) {
        // Keep a failed deletion visible and retriable in the parent's list.
        await staged.rename(originalPath);
        await store.write('artworks', {
          'items': items.map((a) => a.toJson()).toList(),
        });
        rethrow;
      }
    }
  }
}
