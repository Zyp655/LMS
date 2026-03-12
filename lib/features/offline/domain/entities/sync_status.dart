import 'package:equatable/equatable.dart';

enum SyncState { idle, syncing, completed, error }

class SyncStatus extends Equatable {
  final SyncState state;
  final int pendingActions;
  final int completedActions;
  final String? lastError;
  final DateTime? lastSyncAt;

  const SyncStatus({
    this.state = SyncState.idle,
    this.pendingActions = 0,
    this.completedActions = 0,
    this.lastError,
    this.lastSyncAt,
  });

  bool get hasPending => pendingActions > 0;
  bool get isSyncing => state == SyncState.syncing;

  SyncStatus copyWith({
    SyncState? state,
    int? pendingActions,
    int? completedActions,
    String? lastError,
    DateTime? lastSyncAt,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      pendingActions: pendingActions ?? this.pendingActions,
      completedActions: completedActions ?? this.completedActions,
      lastError: lastError ?? this.lastError,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  List<Object?> get props => [
    state,
    pendingActions,
    completedActions,
    lastError,
    lastSyncAt,
  ];
}
