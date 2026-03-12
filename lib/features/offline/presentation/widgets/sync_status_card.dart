import 'package:flutter/material.dart';
import '../../domain/entities/sync_status.dart';
import '../../../../core/theme/app_colors.dart';

class SyncStatusCard extends StatelessWidget {
  final SyncStatus syncStatus;
  final bool isDark;
  final VoidCallback? onSync;

  const SyncStatusCard({
    super.key,
    required this.syncStatus,
    required this.isDark,
    this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (syncStatus.isSyncing)
                const _SpinningSyncIcon()
              else
                Icon(Icons.sync, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔄 Sync Queue (${syncStatus.pendingActions} pending)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    if (syncStatus.lastSyncAt != null)
                      Text(
                        'Lần sync cuối: ${_formatTimeAgo(syncStatus.lastSyncAt!)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              if (!syncStatus.isSyncing && syncStatus.hasPending)
                TextButton(
                  onPressed: onSync,
                  child: const Text(
                    'Sync',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (syncStatus.lastError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      syncStatus.lastError!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }
}

class _SpinningSyncIcon extends StatefulWidget {
  const _SpinningSyncIcon();

  @override
  State<_SpinningSyncIcon> createState() => _SpinningSyncIconState();
}

class _SpinningSyncIconState extends State<_SpinningSyncIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.sync, color: AppColors.secondary, size: 20),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
