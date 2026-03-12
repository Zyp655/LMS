import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/download_task.dart';
import '../bloc/offline_bloc.dart';
import '../../../../core/theme/app_colors.dart';

class DownloadLessonButton extends StatelessWidget {
  final int lessonId;
  final int courseId;
  final String title;
  final String contentUrl;

  const DownloadLessonButton({
    super.key,
    required this.lessonId,
    required this.courseId,
    required this.title,
    required this.contentUrl,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfflineBloc, OfflineState>(
      builder: (context, state) {
        DownloadTask? task;

        if (state is OfflineStatusLoaded) {
          final matches = state.downloads
              .where((d) => d.lessonId == lessonId)
              .toList();
          if (matches.isNotEmpty) task = matches.first;
        }
        if (state is DownloadProgressUpdate &&
            state.task.lessonId == lessonId) {
          task = state.task;
        }

        if (task == null) {
          return _buildButton(
            context,
            icon: Icons.download_for_offline_outlined,
            label: 'Tải offline',
            color: AppColors.primary,
            onTap: () => context.read<OfflineBloc>().add(
              DownloadLesson(
                lessonId: lessonId,
                courseId: courseId,
                title: title,
                contentUrl: contentUrl,
              ),
            ),
          );
        }

        return switch (task.status) {
          DownloadStatus.pending => _buildButton(
            context,
            icon: Icons.hourglass_top,
            label: 'Đang chờ...',
            color: Colors.grey,
          ),
          DownloadStatus.downloading => _buildProgressButton(
            context,
            task: task,
          ),
          DownloadStatus.paused => _buildButton(
            context,
            icon: Icons.play_circle_outline,
            label: 'Tiếp tục',
            color: AppColors.warning,
            onTap: () =>
                context.read<OfflineBloc>().add(ResumeDownload(lessonId)),
          ),
          DownloadStatus.completed => _buildButton(
            context,
            icon: Icons.check_circle,
            label: 'Đã tải',
            color: const Color(0xFF39D353),
          ),
          DownloadStatus.failed => _buildButton(
            context,
            icon: Icons.refresh,
            label: 'Thử lại',
            color: AppColors.error,
            onTap: () => context.read<OfflineBloc>().add(
              DownloadLesson(
                lessonId: lessonId,
                courseId: courseId,
                title: title,
                contentUrl: contentUrl,
              ),
            ),
          ),
        };
      },
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressButton(
    BuildContext context, {
    required DownloadTask task,
  }) {
    return InkWell(
      onTap: () => context.read<OfflineBloc>().add(PauseDownload(lessonId)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.secondary.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                value: task.progressPercent / 100,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${task.progressPercent.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
