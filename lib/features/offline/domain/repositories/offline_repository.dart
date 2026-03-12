import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/download_task.dart';
import '../entities/sync_status.dart';
import '../entities/storage_info.dart';

abstract class OfflineRepository {
  Stream<DownloadTask> downloadLesson({
    required int lessonId,
    required int courseId,
    required String title,
    required String contentUrl,
  });

  Future<Either<Failure, void>> pauseDownload(int lessonId);

  Future<Either<Failure, void>> resumeDownload(int lessonId);

  Future<Either<Failure, void>> cancelDownload(int lessonId);

  Stream<DownloadTask> downloadCourse(int courseId);

  Future<Either<Failure, List<DownloadTask>>> getDownloadedFiles();

  Future<Either<Failure, StorageInfo>> getStorageInfo();

  Future<Either<Failure, void>> deleteOfflineCourse(int courseId);

  Future<Either<Failure, Map<String, dynamic>>> getCachedCourse(int courseId);

  Future<Either<Failure, void>> cacheCourse(
    int courseId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, SyncStatus>> syncPendingActions();

  Future<Either<Failure, SyncStatus>> getSyncStatus();

  Future<Either<Failure, void>> queueAction({
    required String actionType,
    required Map<String, dynamic> payload,
  });

  Future<bool> isLessonAvailableOffline(int lessonId);

  Future<Either<Failure, String>> getDecryptedFilePath(int lessonId);

  Future<Either<Failure, void>> cacheQuiz(
    int quizId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, Map<String, dynamic>>> getCachedQuiz(int quizId);
}
