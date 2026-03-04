import 'dart:io';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

class FileUploadService {
  final AppDatabase db;

  FileUploadService(this.db);

  static const int maxVideoSizeBytes = 500 * 1024 * 1024;
  static const int maxDocSizeBytes = 50 * 1024 * 1024;

  void validateFileSize(int sizeBytes, String fileType) {
    final maxSize = fileType == 'video' ? maxVideoSizeBytes : maxDocSizeBytes;
    if (sizeBytes > maxSize) {
      final maxMB = maxSize ~/ (1024 * 1024);
      throw FileTooLargeException(
        'File too large. Maximum size is ${maxMB}MB',
      );
    }
  }

  Future<CourseFile> uploadFromBytes({
    required String fileName,
    required List<int> fileBytes,
    required int uploadedBy,
    required String fileType,
    int? lessonId,
  }) async {
    validateFileSize(fileBytes.length, fileType);

    final uploadDir = fileType == 'video' ? 'videos' : 'documents';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final relativePath = 'uploads/$uploadDir/$timestamp-$safeFileName';

    final ext = fileName.split('.').last.toLowerCase();
    final mimeType = getMimeType(ext);

    final dir = Directory('uploads/$uploadDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(relativePath);
    await file.writeAsBytes(fileBytes);

    final record = await db.into(db.courseFiles).insertReturning(
          CourseFilesCompanion.insert(
            uploadedBy: uploadedBy,
            lessonId: Value(lessonId),
            fileName: fileName,
            filePath: relativePath,
            fileType: fileType,
            fileSizeBytes: fileBytes.length,
            mimeType: mimeType,
            uploadedAt: DateTime.now(),
          ),
        );

    return record;
  }

  Future<CourseFile> uploadFromMetadata({
    required String fileName,
    required int uploadedBy,
    required String fileType,
    int? lessonId,
    int fileSizeBytes = 0,
    String? mimeType,
  }) async {
    final uploadDir = fileType == 'video' ? 'videos' : 'documents';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '/uploads/$uploadDir/$timestamp-$fileName';
    final resolvedMime = mimeType ?? 'application/octet-stream';

    final record = await db.into(db.courseFiles).insertReturning(
          CourseFilesCompanion.insert(
            uploadedBy: uploadedBy,
            lessonId: Value(lessonId),
            fileName: fileName,
            filePath: filePath,
            fileType: fileType,
            fileSizeBytes: fileSizeBytes,
            mimeType: resolvedMime,
            uploadedAt: DateTime.now(),
          ),
        );

    return record;
  }

  Future<void> deleteFile(int fileId) async {
    final record = await (db.select(db.courseFiles)
          ..where((f) => f.id.equals(fileId)))
        .getSingleOrNull();

    if (record != null) {
      final file = File(record.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await (db.delete(db.courseFiles)..where((f) => f.id.equals(fileId))).go();
    }
  }

  static String getMimeType(String extension) {
    switch (extension) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}

class FileTooLargeException implements Exception {
  final String message;
  FileTooLargeException(this.message);

  @override
  String toString() => message;
}
