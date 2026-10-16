import 'dart:convert';

import 'package:sqflite/sqflite.dart';

abstract class LocalStore {
  Future<Map<String, dynamic>?> read(String key);
  Future<Map<String, Map<String, dynamic>>> readMany(Iterable<String> keys);
  Future<void> write(String key, Map<String, dynamic> value);
  Future<void> remove(String key);
  Future<bool> writeIfUnchanged(
    String key,
    Map<String, dynamic> expected,
    Map<String, dynamic> next,
  );
}

class SqliteStore implements LocalStore {
  final Database db;
  SqliteStore(this.db);
  static Future<SqliteStore> open({String fileName = 'kkoma.db'}) async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      '$dir/$fileName',
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE documents (id TEXT PRIMARY KEY, value TEXT NOT NULL)',
      ),
    );
    return SqliteStore(db);
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final rows = await db.query('documents', where: 'id = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(
      jsonDecode(rows.first['value'] as String) as Map,
    );
  }

  @override
  Future<Map<String, Map<String, dynamic>>> readMany(
    Iterable<String> keys,
  ) async {
    final ids = keys.toSet().toList();
    final result = <String, Map<String, dynamic>>{};
    // Stay below SQLite's variable limit, including older Android versions.
    for (var start = 0; start < ids.length; start += 400) {
      final batch = ids.skip(start).take(400).toList();
      final rows = await db.query(
        'documents',
        where: 'id IN (${List.filled(batch.length, '?').join(',')})',
        whereArgs: batch,
      );
      for (final row in rows) {
        result[row['id'] as String] = Map<String, dynamic>.from(
          jsonDecode(row['value'] as String) as Map,
        );
      }
    }
    return result;
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    await db.insert('documents', {
      'id': key,
      'value': jsonEncode(value),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> remove(String key) async {
    await db.delete('documents', where: 'id = ?', whereArgs: [key]);
  }

  @override
  Future<bool> writeIfUnchanged(
    String key,
    Map<String, dynamic> expected,
    Map<String, dynamic> next,
  ) async =>
      await db.update(
        'documents',
        {'value': jsonEncode(next)},
        where: 'id = ? AND value = ?',
        whereArgs: [key, jsonEncode(expected)],
      ) ==
      1;
}

class MemoryStore implements LocalStore {
  final Map<String, Map<String, dynamic>> documents = {};
  @override
  Future<Map<String, dynamic>?> read(String key) async => documents[key] == null
      ? null
      : Map<String, dynamic>.from(
          jsonDecode(jsonEncode(documents[key])) as Map,
        );
  @override
  Future<Map<String, Map<String, dynamic>>> readMany(
    Iterable<String> keys,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    for (final key in keys.toSet()) {
      final value = await read(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    documents[key] = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(value)) as Map,
    );
  }

  @override
  Future<void> remove(String key) async {
    documents.remove(key);
  }

  @override
  Future<bool> writeIfUnchanged(
    String key,
    Map<String, dynamic> expected,
    Map<String, dynamic> next,
  ) async {
    if (documents[key] == null ||
        jsonEncode(documents[key]) != jsonEncode(expected)) {
      return false;
    }
    documents[key] = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(next)) as Map,
    );
    return true;
  }
}
