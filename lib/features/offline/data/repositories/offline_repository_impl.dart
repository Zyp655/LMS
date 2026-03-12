import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/storage_info.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/offline_repository.dart';
import '../datasources/offline_local_datasource.dart';
import '../services/download_manager.dart';
import '../services/encryption_service.dart';
import '../services/sync_service.dart';

class OfflineRepositoryImpl implements OfflineRepository {
  final OfflineLocalDataSource localDataSource;
  final DownloadManager downloadManager;
  final SyncService syncService;
  final EncryptionService encryptionService;

  OfflineRepositoryImpl({
    required this.localDataSource,
    required this.downloadManager,
    required this.syncService,
    required this.encryptionService,
  });

  @override
  Stream<DownloadTask> downloadLesson({
    required int lessonId,
    required int courseId,
    required String title,
    required String contentUrl,
  }) {
    final task = DownloadTask(
      lessonId: lessonId,
      courseId: courseId,
      title: title,
      fileType: 'video',
      originalUrl: contentUrl,
      fileSizeBytes: 0,
    );
    final key = encryptionService.generateKey();
    return downloadManager.downloadFile(task: task, encryptionKey: key);
  }

  @override
  Future<Either<Failure, void>> pauseDownload(int lessonId) async {
    try {
      downloadManager.pauseDownload(lessonId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to pause download: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resumeDownload(int lessonId) async {
    try {
      downloadManager.resumeDownload(lessonId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to resume download: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelDownload(int lessonId) async {
    try {
      downloadManager.cancelDownload(lessonId);
      await localDataSource.deleteDownloadedFile(lessonId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to cancel download: $e'));
    }
  }

  @override
  Stream<DownloadTask> downloadCourse(int courseId) async* {
    final cachedResult = await getCachedCourse(courseId);
    List<int> lessonIds = [];

    cachedResult.fold((_) {}, (data) {
      final modules = data['modules'] as List<dynamic>? ?? [];
      for (final module in modules) {
        final lessons =
            (module as Map<String, dynamic>)['lessons'] as List<dynamic>? ?? [];
        for (final lesson in lessons) {
          lessonIds.add((lesson as Map<String, dynamic>)['id'] as int);
        }
      }
    });

    if (lessonIds.isEmpty) {
      return;
    }

    for (final lessonId in lessonIds) {
      yield* downloadLesson(
        lessonId: lessonId,
        courseId: courseId,
        title: 'Lesson $lessonId',
        contentUrl: '',
      );
    }
  }

  @override
  Future<Either<Failure, List<DownloadTask>>> getDownloadedFiles() async {
    try {
      final files = await localDataSource.getDownloadedFiles();
      final tasks = files
          .map(
            (f) => DownloadTask(
              lessonId: f['lesson_id'] as int,
              courseId: f['course_id'] as int,
              title: 'Lesson ${f['lesson_id']}',
              fileType: f['file_type'] as String? ?? 'video',
              originalUrl: f['original_url'] as String? ?? '',
              localPath: f['local_path'] as String?,
              fileSizeBytes: f['file_size_bytes'] as int? ?? 0,
              progressPercent:
                  (f['progress_percent'] as num?)?.toDouble() ?? 0.0,
              status: _parseStatus(f['download_status'] as String?),
            ),
          )
          .toList();
      return Right(tasks);
    } catch (e) {
      return Left(ServerFailure('Failed to get downloaded files: $e'));
    }
  }

  @override
  Future<Either<Failure, StorageInfo>> getStorageInfo() async {
    try {
      final usedBytes = await localDataSource.getUsedStorageBytes();
      final appDir = await getApplicationSupportDirectory();
      final stat = await FileStat.stat(appDir.path);
      final totalBytes = stat.size > 0 ? stat.size : 1024 * 1024 * 1024;

      final courseStats = await localDataSource.getStoragePerCourse();
      final courses = courseStats
          .map(
            (c) => CourseStorageInfo(
              courseId: c['course_id'] as int,
              courseTitle: 'Course ${c['course_id']}',
              sizeBytes: c['total_size'] as int,
              downloadedLessons: c['lesson_count'] as int,
              totalLessons: c['lesson_count'] as int,
            ),
          )
          .toList();

      return Right(
        StorageInfo(
          totalBytes: totalBytes,
          usedBytes: usedBytes,
          courses: courses,
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to get storage info: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOfflineCourse(int courseId) async {
    try {
      await localDataSource.deleteDownloadedCourse(courseId);
      await localDataSource.deleteCachedCourse(courseId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete offline course: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCachedCourse(
    int courseId,
  ) async {
    try {
      final data = await localDataSource.getCachedCourse(courseId);
      if (data == null) {
        return Left(ServerFailure('Course not cached'));
      }
      return Right(data);
    } catch (e) {
      return Left(ServerFailure('Failed to get cached course: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheCourse(
    int courseId,
    Map<String, dynamic> data,
  ) async {
    try {
      await localDataSource.cacheCourse(courseId, data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to cache course: $e'));
    }
  }

  @override
  Future<Either<Failure, SyncStatus>> syncPendingActions() async {
    try {
      final result = await syncService.syncAll();
      return Right(
        SyncStatus(
          state: result.failed > 0 ? SyncState.error : SyncState.completed,
          pendingActions: result.pending,
          completedActions: result.synced,
          lastSyncAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to sync: $e'));
    }
  }

  @override
  Future<Either<Failure, SyncStatus>> getSyncStatus() async {
    try {
      final pendingCount = await localDataSource.getPendingActionCount();
      return Right(
        SyncStatus(
          state: pendingCount > 0 ? SyncState.idle : SyncState.completed,
          pendingActions: pendingCount,
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to get sync status: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> queueAction({
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await localDataSource.queueSyncAction(
        actionType: actionType,
        payload: payload,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to queue action: $e'));
    }
  }

  @override
  Future<bool> isLessonAvailableOffline(int lessonId) async {
    final file = await localDataSource.getDownloadedFile(lessonId);
    return file != null;
  }

  @override
  Future<Either<Failure, String>> getDecryptedFilePath(int lessonId) async {
    try {
      final file = await localDataSource.getDownloadedFile(lessonId);
      if (file == null) {
        return Left(ServerFailure('Lesson not downloaded'));
      }
      final localPath = file['local_path'] as String;
      final encryptionKey = file['encryption_key'] as String;
      final decryptedPath = await encryptionService.decryptToTemp(
        localPath,
        encryptionKey,
      );
      return Right(decryptedPath);
    } catch (e) {
      return Left(ServerFailure('Failed to decrypt file: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheQuiz(
    int quizId,
    Map<String, dynamic> data,
  ) async {
    try {
      await localDataSource.cacheQuiz(quizId, data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to cache quiz: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCachedQuiz(
    int quizId,
  ) async {
    try {
      final data = await localDataSource.getCachedQuiz(quizId);
      if (data == null) {
        return Left(ServerFailure('Quiz not cached'));
      }
      return Right(data);
    } catch (e) {
      return Left(ServerFailure('Failed to get cached quiz: $e'));
    }
  }

  DownloadStatus _parseStatus(String? status) {
    switch (status) {
      case 'downloading':
        return DownloadStatus.downloading;
      case 'paused':
        return DownloadStatus.paused;
      case 'completed':
        return DownloadStatus.completed;
      case 'failed':
        return DownloadStatus.failed;
      default:
        return DownloadStatus.pending;
    }
  }
}
