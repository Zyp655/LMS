import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/lesson_entity.dart';
import '../bloc/ai_assistant_bloc.dart';
import '../widgets/ai_chat_sheet.dart';
import '../widgets/ai_summary_sheet.dart';
import '../pages/module_quiz_page.dart';
import '../../../../core/theme/app_colors.dart';

class LessonOverviewTab extends StatelessWidget {
  final LessonEntity lesson;
  final VideoPlayerController? videoController;
  final bool isVideoInitialized;
  final int? userId;

  const LessonOverviewTab({
    super.key,
    required this.lesson,
    this.videoController,
    this.isVideoInitialized = false,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String durationText = '${lesson.durationMinutes} phút';
    if (isVideoInitialized &&
        videoController != null &&
        videoController!.value.isInitialized) {
      final duration = videoController!.value.duration;
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      durationText = '$minutes phút $seconds giây';
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          lesson.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(cs, Icons.access_time, durationText),
            const SizedBox(width: 12),
            _buildInfoChip(
              cs,
              lesson.type == LessonType.text
                  ? Icons.description_rounded
                  : Icons.remove_red_eye_outlined,
              lesson.type == LessonType.text ? 'Tài liệu' : 'Video',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildActionCard(
          context,
          cs,
          'Bài kiểm tra chương',
          'Làm bài kiểm tra do giáo viên tạo',
          Icons.quiz,
          AppColors.accent,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ModuleQuizPage(
                  moduleId: lesson.moduleId,
                  moduleTitle: lesson.title,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildAiButton(
                cs,
                icon: Icons.smart_toy_rounded,
                label: 'Hỏi AI',
                color: AppColors.accent,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BlocProvider.value(
                      value: context.read<AiAssistantBloc>(),
                      child: AiChatSheet(
                        lessonTitle: lesson.title,
                        textContent: lesson.textContent ?? '',
                        contentUrl: lesson.contentUrl,
                        lessonId: lesson.id,
                        userId: userId,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAiButton(
                cs,
                icon: Icons.auto_awesome_rounded,
                label: 'Tóm tắt',
                color: AppColors.secondary,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BlocProvider.value(
                      value: context.read<AiAssistantBloc>(),
                      child: AiSummarySheet(
                        lessonTitle: lesson.title,
                        textContent: lesson.textContent ?? '',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Text(
          'Nội dung bài học',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lesson.textContent ?? 'Chưa có nội dung văn bản.',
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildInfoChip(ColorScheme cs, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    ColorScheme cs,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    ).animate().scale();
  }

  Widget _buildAiButton(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
