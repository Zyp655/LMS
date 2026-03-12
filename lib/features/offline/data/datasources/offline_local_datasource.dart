import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class OfflineLocalDataSource {
  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, 'offline_cache.db');

    return openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_courses (
            course_id INTEGER PRIMARY KEY,
            data_json TEXT NOT NULL,
            cached_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            version INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE downloaded_files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lesson_id INTEGER NOT NULL,
            course_id INTEGER NOT NULL,
            file_type TEXT NOT NULL,
            original_url TEXT NOT NULL,
            local_path TEXT NOT NULL,
            file_size_bytes INTEGER NOT NULL,
            encryption_key TEXT NOT NULL,
            download_status TEXT DEFAULT 'pending',
            progress_percent REAL DEFAULT 0,
            downloaded_at TEXT,
            UNIQUE(lesson_id, file_type)
          )
        ''');

        await db.execute('''
          CREATE TABLE pending_sync_actions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action_type TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            retry_count INTEGER DEFAULT 0,
            last_error TEXT,
            synced_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_quizzes (
            quiz_id INTEGER PRIMARY KEY,
            data_json TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> cacheCourse(int courseId, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('cached_courses', {
      'course_id': courseId,
      'data_json': jsonEncode(data),
      'cached_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String(),
      'version': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCachedCourse(int courseId) async {
    final db = await database;
    final results = await db.query(
      'cached_courses',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    if (results.isEmpty) return null;
    return jsonDecode(results.first['data_json'] as String)
        as Map<String, dynamic>;
  }

  Future<void> deleteCachedCourse(int courseId) async {
    final db = await database;
    await db.delete(
      'cached_courses',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
  }

  Future<void> saveDownloadedFile({
    required int lessonId,
    required int courseId,
    required String fileType,
    required String originalUrl,
    required String localPath,
    required int fileSizeBytes,
    required String encryptionKey,
  }) async {
    final db = await database;
    await db.insert('downloaded_files', {
      'lesson_id': lessonId,
      'course_id': courseId,
      'file_type': fileType,
      'original_url': originalUrl,
      'local_path': localPath,
      'file_size_bytes': fileSizeBytes,
      'encryption_key': encryptionKey,
      'download_status': 'completed',
      'progress_percent': 100.0,
      'downloaded_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getDownloadedFiles() async {
    final db = await database;
    return db.query('downloaded_files');
  }

  Future<Map<String, dynamic>?> getDownloadedFile(int lessonId) async {
    final db = await database;
    final results = await db.query(
      'downloaded_files',
      where: 'lesson_id = ? AND download_status = ?',
      whereArgs: [lessonId, 'completed'],
    );
    return results.isEmpty ? null : results.first;
  }

  Future<void> deleteDownloadedFile(int lessonId) async {
    final db = await database;
    await db.delete(
      'downloaded_files',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );
  }

  Future<void> deleteDownloadedCourse(int courseId) async {
    final db = await database;
    await db.delete(
      'downloaded_files',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
  }

  Future<int> getUsedStorageBytes() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(file_size_bytes), 0) as total FROM downloaded_files WHERE download_status = ?',
      ['completed'],
    );
    return result.first['total'] as int? ?? 0;
  }

  Future<void> queueSyncAction({
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    await db.insert('pending_sync_actions', {
      'action_type': actionType,
      'payload_json': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncActions() async {
    final db = await database;
    return db.query(
      'pending_sync_actions',
      where: 'synced_at IS NULL AND retry_count < 5',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markActionSynced(int id) async {
    final db = await database;
    await db.update(
      'pending_sync_actions',
      {'synced_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateRetryCount(int id, int count, String error) async {
    final db = await database;
    await db.update(
      'pending_sync_actions',
      {'retry_count': count, 'last_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getStoragePerCourse() async {
    final db = await database;
    return db.rawQuery('''
      SELECT course_id,
             COUNT(*) as lesson_count,
             COALESCE(SUM(file_size_bytes), 0) as total_size
      FROM downloaded_files
      WHERE download_status = 'completed'
      GROUP BY course_id
    ''');
  }

  Future<int> getPendingActionCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pending_sync_actions WHERE synced_at IS NULL',
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<void> cacheQuiz(int quizId, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('cached_quizzes', {
      'quiz_id': quizId,
      'data_json': jsonEncode(data),
      'cached_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCachedQuiz(int quizId) async {
    final db = await database;
    final results = await db.query(
      'cached_quizzes',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
    if (results.isEmpty) return null;
    return jsonDecode(results.first['data_json'] as String)
        as Map<String, dynamic>;
  }
}
