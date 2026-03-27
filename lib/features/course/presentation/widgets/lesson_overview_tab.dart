import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/lesson_entity.dart';
import '../bloc/ai_assistant_bloc.dart';
import '../widgets/ai_chat_sheet.dart';
import '../widgets/ai_concept_map_sheet.dart';
import '../../../../core/api/api_client.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../teaching/domain/entities/assignment_entity.dart';
import '../../../teaching/presentation/pages/submit_assignment_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

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

        _ModuleAssignmentsSection(moduleId: lesson.moduleId, userId: userId),

        const SizedBox(height: 12),

        _buildAiButton(
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

        const SizedBox(height: 8),

        _buildAiButton(
          cs,
          icon: Icons.account_tree_rounded,
          label: 'Concept Map',
          color: AppColors.primary,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => BlocProvider.value(
                value: context.read<AiAssistantBloc>(),
                child: AiConceptMapSheet(
                  lessonTitle: lesson.title,
                  textContent: lesson.textContent ?? '',
                ),
              ),
            );
          },
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

class _ModuleAssignmentsSection extends StatefulWidget {
  final int moduleId;
  final int? userId;

  const _ModuleAssignmentsSection({required this.moduleId, this.userId});

  @override
  State<_ModuleAssignmentsSection> createState() => _ModuleAssignmentsSectionState();
}

class _ModuleAssignmentsSectionState extends State<_ModuleAssignmentsSection> {
  List<Map<String, dynamic>> _assignments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = sl<ApiClient>();
      final userId = widget.userId ?? _getUserId();
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }
      final data = await api.get('/student/assignments?userId=$userId');
      final all = (data as List?)?.cast<Map<String, dynamic>>() ?? [];
      final filtered = all.where((a) => a['moduleId'] == widget.moduleId).toList();
      if (mounted) {
        setState(() {
          _assignments = filtered;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _getUserId() {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSuccess && authState.user != null) {
        return authState.user!.id;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_assignments.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final subtextColor = isDark ? Colors.grey[400]! : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Bài tập chương (${_assignments.length})',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._assignments.map((a) => _buildAssignmentItem(a, isDark, textColor, subtextColor)),
      ],
    );
  }

  Widget _buildAssignmentItem(
    Map<String, dynamic> a,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    final title = a['title'] as String? ?? 'Bài tập';
    final dueDate = a['dueDate'] != null ? DateTime.tryParse(a['dueDate']) : null;
    final isCompleted = a['submissionStatus'] == 'submitted' || a['submissionStatus'] == 'graded';
    final isLate = dueDate != null && DateTime.now().isAfter(dueDate) && !isCompleted;
    final isGraded = a['submissionStatus'] == 'graded' && a['grade'] != null;

    final statusColor = isGraded
        ? AppColors.success
        : isCompleted
            ? Colors.blue
            : isLate
                ? AppColors.error
                : Colors.orange;
    final statusText = isGraded
        ? 'Điểm: ${a['grade']}'
        : isCompleted
            ? 'Đã nộp'
            : isLate
                ? 'Trễ hạn'
                : 'Chưa nộp';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => SubmitAssignmentPage(
                assignment: AssignmentEntity(
                  id: a['assignmentId'] as int,
                  classId: a['classId'] as int? ?? 0,
                  title: title,
                  description: a['description'] as String? ?? '',
                  dueDate: dueDate ?? DateTime.now(),
                  rewardPoints: a['rewardPoints'] as int? ?? 0,
                  createdAt: DateTime.now(),
                ),
              ),
            ),
          );
          if (result == true) _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_outline : Icons.assignment_outlined,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (dueDate != null)
                      Text(
                        'Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(dueDate)}',
                        style: TextStyle(
                          color: isLate ? AppColors.error : subtextColor,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

