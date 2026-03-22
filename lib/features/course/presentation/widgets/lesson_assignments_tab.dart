import 'package:flutter/material.dart';
import '../../../../injection_container.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../teaching/domain/entities/assignment_entity.dart';
import '../../../teaching/presentation/pages/submit_assignment_page.dart';

class LessonAssignmentsTab extends StatefulWidget {
  final int moduleId;
  final int? userId;

  const LessonAssignmentsTab({
    super.key,
    required this.moduleId,
    this.userId,
  });

  @override
  State<LessonAssignmentsTab> createState() => _LessonAssignmentsTabState();
}

class _LessonAssignmentsTabState extends State<LessonAssignmentsTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _assignments = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = sl<ApiClient>();
      final data = await api.get('/student/assignments?userId=${widget.userId}');
      final all = (data as List?)?.cast<Map<String, dynamic>>() ?? [];
      final filtered = all.where((a) => a['moduleId'] == widget.moduleId).toList();
      if (mounted) {
        setState(() {
          _assignments = filtered;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Chưa có bài tập cho chương này',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final subtextColor = isDark ? Colors.grey[400]! : AppColors.textSecondaryLight;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final a = _assignments[index];
        return _buildCard(a, isDark, textColor, subtextColor);
      },
    );
  }

  Widget _buildCard(
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
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_outline : Icons.assignment_outlined,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
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
                    if (dueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Hạn: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                        style: TextStyle(color: subtextColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
