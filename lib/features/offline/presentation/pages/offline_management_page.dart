import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/offline_bloc.dart';
import '../widgets/storage_card.dart';
import '../widgets/download_item_card.dart';
import '../widgets/sync_status_card.dart';
import '../../../../core/theme/app_colors.dart';

class OfflineManagementPage extends StatefulWidget {
  const OfflineManagementPage({super.key});

  @override
  State<OfflineManagementPage> createState() => _OfflineManagementPageState();
}

class _OfflineManagementPageState extends State<OfflineManagementPage> {
  @override
  void initState() {
    super.initState();
    context.read<OfflineBloc>().add(LoadOfflineStatus());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          '📱 Offline Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => context.read<OfflineBloc>().add(SyncPending()),
            icon: Icon(Icons.sync, size: 18),
            label: const Text('Sync'),
          ),
        ],
      ),
      body: BlocBuilder<OfflineBloc, OfflineState>(
        buildWhen: (prev, curr) =>
            prev.runtimeType != curr.runtimeType || prev != curr,
        builder: (context, state) {
          if (state is OfflineLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is OfflineStatusLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<OfflineBloc>().add(LoadOfflineStatus());
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!state.isOnline) _buildOfflineBanner(),
                  const SizedBox(height: 12),
                  StorageCard(
                    storageInfo: state.storageInfo,
                    isDark: isDark,
                    onDeleteCourse: (courseId) => context
                        .read<OfflineBloc>()
                        .add(DeleteOfflineCourse(courseId)),
                  ),
                  const SizedBox(height: 16),
                  if (state.syncStatus.hasPending) ...[
                    SyncStatusCard(
                      syncStatus: state.syncStatus,
                      isDark: isDark,
                      onSync: () =>
                          context.read<OfflineBloc>().add(SyncPending()),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Nội dung đã tải',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state.downloads.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    ...state.downloads.map(
                      (d) => DownloadItemCard(
                        task: d,
                        isDark: isDark,
                        onPause: () => context.read<OfflineBloc>().add(
                          PauseDownload(d.lessonId),
                        ),
                        onResume: () => context.read<OfflineBloc>().add(
                          ResumeDownload(d.lessonId),
                        ),
                        onCancel: () => context.read<OfflineBloc>().add(
                          CancelDownload(d.lessonId),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.error, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚡ Bạn đang offline — Đang chờ kết nối',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.cloud_download_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có nội dung offline',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            'Tải khóa học để học offline',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
