import 'dart:developer';

import 'package:flutter_poc/models/db_mode.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

import '../models/note.dart';
import '../models/quiz.dart';
import '../models/video.dart';

class DatabaseService {
  final PowerSyncDatabase db;

  const DatabaseService({required this.db});

  // ─── Generic CRUD ────────────────────────────────────────────────────────────

  /// Insert a new record. Generates a UUID if model id is empty.
  Future<void> insert(DbModel model) async {
    final map = model.toMap();

    // Ensure ID is always present
    if ((map['id'] as String?)?.isEmpty ?? true) {
      map['id'] = const Uuid().v4();
    }

    final columns = map.keys.join(', ');
    final placeholders = map.keys.map((_) => '?').join(', ');
    await _excute('INSERT INTO ${model.tableName} ($columns) VALUES ($placeholders)', map.values.toList());
  }

  Future<void> _excute(String sql, [List<dynamic>? params]) async {
    try {
      _logTimeStamp('Start Executing SQL ==> $sql params: $params');
      await db.execute(sql, params ?? []);
      _logTimeStamp('End SQL execution ==> $sql ');
    } catch (e) {
      log('DB execute error: $e');
      log(e.toString());
    }
  }

  /// Update an existing record by id.
  Future<void> update(DbModel model) async {
    final map = model.toMap()..remove('id');
    final setClause = map.keys.map((k) => '$k = ?').join(', ');
    await _excute('UPDATE ${model.tableName} SET $setClause WHERE id = ?', [...map.values, model.id]);
  }

  /// Delete a record by id.
  Future<void> delete(DbModel model) async {
    await _excute('DELETE FROM ${model.tableName} WHERE id = ?', [model.id]);
  }

  /// Get a single record by id.
  Future<Map<String, dynamic>?> findById(DbModel model) async {
    final results = await db.getAll('SELECT ${model.selectColumns} FROM ${model.tableName} WHERE id = ?', [model.id]);
    return results.isEmpty ? null : results.first;
  }

  /// Get all records from a table.
  Future<List<Map<String, dynamic>>> findAll(DbModel model) async {
    return await db.getAll('SELECT ${model.selectColumns} FROM ${model.tableName} ORDER BY id');
  }

  // ─── Typed convenience methods ────────────────────────────────────────────────

  Future<List<Note>> getAllNotes() async {
    final rows = await findAll(Note(id: '', title: '', content: ''));
    return rows.map(Note.fromMap).toList();
  }

  Future<List<Video>> getAllVideos() async {
    final rows = await findAll(Video(id: '', name: ''));
    return rows.map(Video.fromMap).toList();
  }

  Future<List<Quiz>> getAllQuizzes() async {
    final rows = await findAll(Quiz(id: '', name: ''));
    return rows.map(Quiz.fromMap).toList();
  }

  // ─── Stream variants ──────────────────────────────────────────────────────────

  Stream<List<Note>> watchAllNotes() =>
      db.watch('SELECT * FROM notes ORDER BY id').map((rows) => rows.map(Note.fromMap).toList());

  Stream<List<Video>> watchAllVideos() =>
      db.watch('SELECT * FROM videos ORDER BY id').map((rows) => rows.map(Video.fromMap).toList());

  Stream<List<Quiz>> watchAllQuizzes() =>
      db.watch('SELECT * FROM quizzes ORDER BY id').map((rows) => rows.map(Quiz.fromMap).toList());

  // ─── Metrics ──────────────────────────────────────────────────────────────────

  // Stream<int> watchPendingOpsCount() => db
  //     .watch('SELECT COUNT(*) as count FROM ps_crud')
  //     .map((rows) => rows.isEmpty ? 0 : (rows.first['count'] as int?) ?? 0);

  // Future<int> dbFileSizeBytes() async {
  //   final dir = await getApplicationDocumentsDirectory();
  //   final file = File(join(dir.path, 'powersync.db'));
  //   if (!await file.exists()) return 0;
  //   return await file.length();
  // }

  // ─── Bulk insert ──────────────────────────────────────────────────────────────

  Future<void> bulkInsert(List<DbModel> models) async {
    try {
      _logTimeStamp('Starting bulk insert of ${models.length} records');
      for (final model in models) {
        final map = model.toMap();
        if ((map['id'] as String?)?.isEmpty ?? true) map['id'] = const Uuid().v4();
        final columns = map.keys.join(', ');
        final placeholders = map.keys.map((_) => '?').join(', ');
        await _excute('INSERT INTO ${model.tableName} ($columns) VALUES ($placeholders)', map.values.toList());
      }
      _logTimeStamp('Completed bulk insert');
    } catch (e) {
      log('Bulk insert error: $e');
    }
  }

  void _logTimeStamp(String message) {
    // final now = DateTime.now();
    // log('[$now] =======> $message');
  }
}
