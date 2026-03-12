import 'package:flutter/material.dart';
import '../../domain/entities/download_task.dart';
import '../../../../core/theme/app_colors.dart';

class DownloadItemCard extends StatelessWidget {
  final DownloadTask task;
  final bool isDark;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const DownloadItemCard({
    super.key,
    required this.task,
    required this.isDark,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, statusColor) = _statusVisuals(task.status);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: statusColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.fileSizeFormatted,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              if (task.status == DownloadStatus.downloading) ...[
                Text(
                  '${task.progressPercent.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11, color: statusColor),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.pause_circle_outline,
                  color: AppColors.warning,
                  onTap: onPause,
                ),
              ],
              if (task.status == DownloadStatus.paused)
                _buildActionButton(
                  icon: Icons.play_circle_outline,
                  color: AppColors.primary,
                  onTap: onResume,
                ),
              if (task.status == DownloadStatus.downloading ||
                  task.status == DownloadStatus.paused)
                _buildActionButton(
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  onTap: onCancel,
                ),
            ],
          ),
          if (task.status == DownloadStatus.downloading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: task.progressPercent / 100,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                  minHeight: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  static (IconData, Color) _statusVisuals(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.completed => (Icons.check_circle, const Color(0xFF39D353)),
      DownloadStatus.downloading => (
        Icons.downloading,
        AppColors.secondary,
      ),
      DownloadStatus.paused => (Icons.pause_circle, Colors.orange),
      DownloadStatus.failed => (Icons.error, AppColors.error),
      DownloadStatus.pending => (Icons.download, Colors.grey),
    };
  }
}
