import 'dart:io';
import 'dart:convert';
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
  int _lastArtworkMicros = 0;
  DrawingRepository(this.store, this.directory);
  Future<T> _exclusive<T>(Future<T> Function() action) {
    final next = _operations.then((_) => action());
    _operations = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<DrawingDocument> draft({String key = 'drawing-draft'}) async =>
      DrawingDocument.fromJson(await store.read(key) ?? {});
  Future<void> saveDraft(DrawingDocument d, {String key = 'drawing-draft'}) =>
      store.write(key, d.toJson());
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
  Future<Artwork> prepare(DrawingDocument document) =>
      _exclusive(() => _prepare(document));
  Future<Artwork> _prepare(DrawingDocument document) async {
    final dir = await directory(), items = await _list();
    var micros = DateTime.now().microsecondsSinceEpoch;
    if (micros <= _lastArtworkMicros) micros = _lastArtworkMicros + 1;
    while (items.any((a) => a.id == 'art-$micros') ||
        await File('${dir.path}/art-$micros.png').exists() ||
        await File('${dir.path}/art-$micros.png.saving').exists()) {
      micros++;
    }
    _lastArtworkMicros = micros;
    return Artwork(
      id: 'art-$micros',
      path: '${dir.path}/art-$micros.png',
      created: DateTime.now(),
      document: document,
    );
  }

  Future<Artwork> _save(DrawingDocument document) async =>
      _savePrepared(await _prepare(document));

  /// The caller persists this prepared ID before creating any file.
  Future<Artwork> savePrepared(Artwork artwork) =>
      _exclusive(() => _savePrepared(artwork));
  Future<Artwork> _savePrepared(Artwork artwork) async {
    final dir = await directory();
    final file = File(artwork.path), temporary = File('${artwork.path}.saving');
    if (!RegExp(r'^art-[0-9]+$').hasMatch(artwork.id) ||
        file.absolute.path !=
            File('${dir.path}/${artwork.id}.png').absolute.path) {
      throw const FileSystemException('작품 경로 오류');
    }
    final items = await _list(),
        existing = items.where((a) => a.id == artwork.id).firstOrNull;
    if (existing != null &&
        jsonEncode(existing.toJson()) != jsonEncode(artwork.toJson())) {
      throw StateError('같은 작품 ID에 다른 그림이 있어요.');
    }
    if (existing != null && await file.exists()) return existing;
    final recorder = ui.PictureRecorder();
    DrawingPainter(artwork.document)
        .paint(ui.Canvas(recorder), const ui.Size(1200, 900));
    final picture = recorder.endRecording(),
        image = await picture.toImage(1200, 900).whenComplete(picture.dispose);
    final data = await image
        .toByteData(format: ui.ImageByteFormat.png)
        .whenComplete(image.dispose);
    if (data == null) throw const FileSystemException('PNG 생성 실패');
    try {
      await temporary.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await temporary.rename(file.path);
      if (existing == null) {
        await store.write('artworks', {
          'items': [...items, artwork].map((a) => a.toJson()).toList(),
        });
      }
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      if (existing == null && await file.exists()) await file.delete();
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
