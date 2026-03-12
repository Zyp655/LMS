import 'dart:async';
import 'dart:math';
import '../../../../core/api/api_client.dart';
import '../datasources/offline_local_datasource.dart';
import 'connectivity_service.dart';

class SyncService {
  final OfflineLocalDataSource localDataSource;
  final ApiClient apiClient;
  final ConnectivityService connectivityService;

  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService({
    required this.localDataSource,
    required this.apiClient,
    required this.connectivityService,
  });

  void startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => syncAll());
    connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline) syncAll();
    });
  }

  Future<SyncResult> syncAll() async {
    if (_isSyncing) return SyncResult(synced: 0, failed: 0, pending: 0);

    final isOnline = await connectivityService.isOnline;
    if (!isOnline) {
      final pending = await localDataSource.getPendingSyncActions();
      return SyncResult(synced: 0, failed: 0, pending: pending.length);
    }

    _isSyncing = true;
    int synced = 0;
    int failed = 0;

    try {
      final actions = await localDataSource.getPendingSyncActions();

      for (final action in actions) {
        try {
          await _resolveAndSync(action);
          await localDataSource.markActionSynced(action['id'] as int);
          synced++;
        } catch (e) {
          final retryCount = (action['retry_count'] as int? ?? 0) + 1;
          await localDataSource.updateRetryCount(
            action['id'] as int,
            retryCount,
            e.toString(),
          );
          failed++;
        }
      }

      final remaining = await localDataSource.getPendingSyncActions();
      return SyncResult(
        synced: synced,
        failed: failed,
        pending: remaining.length,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _resolveAndSync(Map<String, dynamic> action) async {
    final type = action['action_type'] as String;
    final payload = action['payload_json'] as Map<String, dynamic>;

    switch (type) {
      case 'lesson_progress':
        final serverData = await apiClient.get(
          '/course/lesson-progress?userId=${payload['userId']}&lessonId=${payload['lessonId']}',
        );
        final serverProgress =
            (serverData['progress'] as num?)?.toDouble() ?? 0.0;
        final localProgress = (payload['progress'] as num?)?.toDouble() ?? 0.0;
        final resolvedProgress = max(serverProgress, localProgress);

        final serverPosition = serverData['lastWatchedPosition'] as int? ?? 0;
        final localPosition = payload['lastWatchedPosition'] as int? ?? 0;
        final resolvedPosition = max(serverPosition, localPosition);

        await apiClient.post('/course/update-lesson-progress', {
          ...payload,
          'progress': resolvedProgress,
          'lastWatchedPosition': resolvedPosition,
        });
        break;

      case 'quiz_result':
        await apiClient.post('/quiz/submit', payload);
        break;

      case 'comment':
        await apiClient.post('/comments', payload);
        break;

      default:
        await apiClient.post('/sync/$type', payload);
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}

class SyncResult {
  final int synced;
  final int failed;
  final int pending;

  const SyncResult({
    required this.synced,
    required this.failed,
    required this.pending,
  });
}
