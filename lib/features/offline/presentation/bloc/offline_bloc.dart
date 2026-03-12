import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/encryption_service.dart';
import '../../data/services/sync_service.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/usecases/offline_usecases.dart';
import 'offline_event.dart';
import 'offline_state.dart';

export 'offline_event.dart';
export 'offline_state.dart';

class OfflineBloc extends Bloc<OfflineEvent, OfflineState> {
  final GetOfflineStatusUseCase getOfflineStatus;
  final DownloadLessonUseCase downloadLesson;
  final PauseDownloadUseCase pauseDownload;
  final ResumeDownloadUseCase resumeDownload;
  final CancelDownloadUseCase cancelDownload;
  final DeleteOfflineCourseUseCase deleteOfflineCourse;
  final SyncPendingUseCase syncPending;
  final ConnectivityService connectivityService;
  final SyncService syncService;
  final EncryptionService encryptionService;
  StreamSubscription<bool>? _connectivitySub;

  OfflineBloc({
    required this.getOfflineStatus,
    required this.downloadLesson,
    required this.pauseDownload,
    required this.resumeDownload,
    required this.cancelDownload,
    required this.deleteOfflineCourse,
    required this.syncPending,
    required this.connectivityService,
    required this.syncService,
    required this.encryptionService,
  }) : super(OfflineInitial()) {
    on<LoadOfflineStatus>(_onLoadStatus);
    on<DownloadLesson>(_onDownloadLesson);
    on<PauseDownload>(_onPause);
    on<ResumeDownload>(_onResume);
    on<CancelDownload>(_onCancel);
    on<DeleteOfflineCourse>(_onDeleteCourse);
    on<SyncPending>(_onSync);
    on<CheckConnectivity>(_onCheckConnectivity);
    on<ConnectivityChanged>(_onConnectivityChanged);

    _connectivitySub = connectivityService.onConnectivityChanged.listen(
      (isOnline) => add(ConnectivityChanged(isOnline)),
    );

    syncService.startPeriodicSync();
  }

  Future<void> _onLoadStatus(
    LoadOfflineStatus event,
    Emitter<OfflineState> emit,
  ) async {
    emit(OfflineLoading());

    await encryptionService.cleanupTempFiles();

    final result = await getOfflineStatus();

    emit(
      OfflineStatusLoaded(
        downloads: result.downloads,
        storageInfo: result.storageInfo,
        syncStatus: result.syncStatus,
      ),
    );
  }

  Future<void> _onDownloadLesson(
    DownloadLesson event,
    Emitter<OfflineState> emit,
  ) async {
    await emit.forEach<DownloadTask>(
      downloadLesson(
        lessonId: event.lessonId,
        courseId: event.courseId,
        title: event.title,
        contentUrl: event.contentUrl,
      ),
      onData: (task) => DownloadProgressUpdate(task),
      onError: (error, _) => OfflineError(error.toString()),
    );
  }

  Future<void> _onPause(PauseDownload event, Emitter<OfflineState> emit) async {
    await pauseDownload(event.lessonId);
  }

  Future<void> _onResume(
    ResumeDownload event,
    Emitter<OfflineState> emit,
  ) async {
    await resumeDownload(event.lessonId);
  }

  Future<void> _onCancel(
    CancelDownload event,
    Emitter<OfflineState> emit,
  ) async {
    await cancelDownload(event.lessonId);
    add(LoadOfflineStatus());
  }

  Future<void> _onDeleteCourse(
    DeleteOfflineCourse event,
    Emitter<OfflineState> emit,
  ) async {
    await deleteOfflineCourse(event.courseId);
    add(LoadOfflineStatus());
  }

  Future<void> _onSync(SyncPending event, Emitter<OfflineState> emit) async {
    await syncPending();
    add(LoadOfflineStatus());
  }

  Future<void> _onCheckConnectivity(
    CheckConnectivity event,
    Emitter<OfflineState> emit,
  ) async {
    final isOnline = await connectivityService.isOnline;
    add(ConnectivityChanged(isOnline));
  }

  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<OfflineState> emit,
  ) {
    final current = state;
    if (current is OfflineStatusLoaded) {
      emit(
        OfflineStatusLoaded(
          downloads: current.downloads,
          storageInfo: current.storageInfo,
          syncStatus: current.syncStatus,
          isOnline: event.isOnline,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    syncService.dispose();
    return super.close();
  }
}
