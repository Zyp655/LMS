import 'package:equatable/equatable.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/entities/storage_info.dart';

abstract class OfflineState extends Equatable {
  const OfflineState();
  @override
  List<Object?> get props => [];
}

class OfflineInitial extends OfflineState {}

class OfflineLoading extends OfflineState {}

class OfflineStatusLoaded extends OfflineState {
  final List<DownloadTask> downloads;
  final StorageInfo storageInfo;
  final SyncStatus syncStatus;
  final bool isOnline;

  const OfflineStatusLoaded({
    required this.downloads,
    required this.storageInfo,
    required this.syncStatus,
    this.isOnline = true,
  });

  @override
  List<Object?> get props => [downloads, storageInfo, syncStatus, isOnline];
}

class DownloadProgressUpdate extends OfflineState {
  final DownloadTask task;
  const DownloadProgressUpdate(this.task);
  @override
  List<Object?> get props => [task];
}

class OfflineError extends OfflineState {
  final String message;
  const OfflineError(this.message);
  @override
  List<Object?> get props => [message];
}
