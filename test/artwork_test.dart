import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/drawing/data/drawing_repository.dart';
import 'package:flutter_application_1/features/drawing/domain/drawing.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';

class RejectMetadata extends MemoryStore {
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key == 'artworks') throw const FileSystemException('full');
    await super.write(key, value);
  }
}

class SlowArtworkStore extends MemoryStore {
  bool reject = false;
  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final saved = await super.read(key);
    if (key == 'artworks') {
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
    return saved;
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (reject && key == 'artworks') {
      throw const FileSystemException('metadata full');
    }
    await super.write(key, value);
  }
}

void main() {
  testWidgets(
    'reopening recovers a delete interrupted before metadata commit',
    (tester) async {
      await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp(
          'kkoma-interrupted-delete-',
        );
        try {
          final store = MemoryStore(),
              repo = DrawingRepository(store, () async => dir);
          final art = await repo.save(const DrawingDocument());
          await File(art.path).rename('${art.path}.deleting');
          final restored = await DrawingRepository(
            store,
            () async => dir,
          ).list();
          expect(restored.single.id, art.id);
          expect(await File(art.path).exists(), true);
          expect(await File('${art.path}.deleting').exists(), false);
        } finally {
          await dir.delete(recursive: true);
        }
      });
    },
  );
  testWidgets(
    'simultaneous saves and deletion preserve all remaining artworks',
    (tester) async {
      await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp(
          'kkoma-concurrent-art-',
        );
        try {
          final repo = DrawingRepository(SlowArtworkStore(), () async => dir);
          final arts = await Future.wait([
            repo.save(const DrawingDocument()),
            repo.save(const DrawingDocument(background: 0xffaabbcc)),
          ]);
          expect(
            (await repo.list()).map((a) => a.id).toSet(),
            arts.map((a) => a.id).toSet(),
          );
          await Future.wait<Object?>([
            repo.save(const DrawingDocument()),
            repo.delete(arts.first.id),
          ]);
          expect((await repo.list()).length, 2);
          expect(await dir.list().length, 2);
        } finally {
          await dir.delete(recursive: true);
        }
      });
    },
  );
  testWidgets(
    'metadata failure restores deleted artwork and queue accepts retry',
    (tester) async {
      await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp(
          'kkoma-delete-rollback-',
        );
        try {
          final store = SlowArtworkStore(),
              repo = DrawingRepository(store, () async => dir);
          final art = await repo.save(const DrawingDocument());
          store.reject = true;
          await expectLater(
            repo.delete(art.id),
            throwsA(isA<FileSystemException>()),
          );
          expect(await File(art.path).exists(), true);
          expect((await repo.list()).single.id, art.id);
          expect(await dir.list().length, 1);
          store.reject = false;
          await repo.delete(art.id);
          expect(await repo.list(), isEmpty);
          expect(await dir.list().length, 0);
        } finally {
          await dir.delete(recursive: true);
        }
      });
    },
  );
  testWidgets('PNG artwork reopens and deletion removes its own file', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('kkoma-art-test-');
      try {
        final store = MemoryStore(),
            repo = DrawingRepository(store, () async => dir);
        final art = await repo.save(
          const DrawingDocument(
            lines: [
              DrawingLine([TracePoint(.2, .2), TracePoint(.8, .8)]),
            ],
          ),
        );
        final bytes = await File(art.path).readAsBytes();
        expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
        final reopened = await DrawingRepository(store, () async => dir).list();
        expect(reopened.single.document.lines.length, 1);
        await repo.delete(art.id);
        expect(await File(art.path).exists(), false);
        expect(await repo.list(), isEmpty);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
  testWidgets('failed metadata write rolls back newly generated PNG', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('kkoma-rollback-test-');
      try {
        await expectLater(
          DrawingRepository(
            RejectMetadata(),
            () async => dir,
          ).save(const DrawingDocument()),
          throwsA(isA<FileSystemException>()),
        );
        expect(await dir.list().toList(), isEmpty);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
