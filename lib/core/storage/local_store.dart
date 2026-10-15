import 'dart:convert';

import 'package:sqflite/sqflite.dart';

abstract class LocalStore {
  Future<Map<String, dynamic>?> read(String key);
  Future<void> write(String key, Map<String, dynamic> value);
  Future<void> remove(String key);
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
  Future<void> write(String key, Map<String, dynamic> value) async {
    documents[key] = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(value)) as Map,
    );
  }

  @override
  Future<void> remove(String key) async {
    documents.remove(key);
  }
}
