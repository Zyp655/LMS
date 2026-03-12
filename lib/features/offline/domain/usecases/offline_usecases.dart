import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/download_task.dart';
import '../entities/sync_status.dart';
import '../entities/storage_info.dart';
import '../repositories/offline_repository.dart';

class GetOfflineStatusUseCase {
  final OfflineRepository repository;

  GetOfflineStatusUseCase(this.repository);

  Future<
    ({
      List<DownloadTask> downloads,
      StorageInfo storageInfo,
      SyncStatus syncStatus,
    })
  >
  call() async {
    final downloadsResult = await repository.getDownloadedFiles();
    final storageResult = await repository.getStorageInfo();
    final syncResult = await repository.getSyncStatus();

    final downloads = downloadsResult.fold(
      (_) => <DownloadTask>[],
      (data) => data,
    );
    final storage = storageResult.fold(
      (_) => const StorageInfo(totalBytes: 0, usedBytes: 0, courses: []),
      (data) => data,
    );
    final sync = syncResult.fold((_) => const SyncStatus(), (data) => data);

    return (downloads: downloads, storageInfo: storage, syncStatus: sync);
  }
}

class DownloadLessonUseCase {
  final OfflineRepository repository;

  DownloadLessonUseCase(this.repository);

  Stream<DownloadTask> call({
    required int lessonId,
    required int courseId,
    required String title,
    required String contentUrl,
  }) {
    return repository.downloadLesson(
      lessonId: lessonId,
      courseId: courseId,
      title: title,
      contentUrl: contentUrl,
    );
  }
}

class PauseDownloadUseCase {
  final OfflineRepository repository;

  PauseDownloadUseCase(this.repository);

  Future<Either<Failure, void>> call(int lessonId) {
    return repository.pauseDownload(lessonId);
  }
}

class ResumeDownloadUseCase {
  final OfflineRepository repository;

  ResumeDownloadUseCase(this.repository);

  Future<Either<Failure, void>> call(int lessonId) {
    return repository.resumeDownload(lessonId);
  }
}

class CancelDownloadUseCase {
  final OfflineRepository repository;

  CancelDownloadUseCase(this.repository);

  Future<Either<Failure, void>> call(int lessonId) {
    return repository.cancelDownload(lessonId);
  }
}

class DeleteOfflineCourseUseCase {
  final OfflineRepository repository;

  DeleteOfflineCourseUseCase(this.repository);

  Future<Either<Failure, void>> call(int courseId) {
    return repository.deleteOfflineCourse(courseId);
  }
}

class SyncPendingUseCase {
  final OfflineRepository repository;

  SyncPendingUseCase(this.repository);

  Future<Either<Failure, SyncStatus>> call() {
    return repository.syncPendingActions();
  }
}

class CacheQuizUseCase {
  final OfflineRepository repository;

  CacheQuizUseCase(this.repository);

  Future<Either<Failure, void>> call(int quizId, Map<String, dynamic> data) {
    return repository.cacheQuiz(quizId, data);
  }
}

class GetCachedQuizUseCase {
  final OfflineRepository repository;

  GetCachedQuizUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(int quizId) {
    return repository.getCachedQuiz(quizId);
  }
}
