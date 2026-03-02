import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/admin_bloc.dart';
import 'class_tile.dart';

class CourseClassCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isExpanded;
  final VoidCallback onToggle;

  const CourseClassCard({
    super.key,
    required this.course,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = course['name'] as String? ?? '';
    final code = course['code'] as String? ?? '';
    final credits = course['credits'] as int? ?? 0;
    final deptName = course['departmentName'] as String? ?? '';
    final classes = List<Map<String, dynamic>>.from(
      course['assignedTeachers'] ?? [],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _badge(
                              code,
                              AppColors.info,
                              AppColors.info.withValues(alpha: 0.12),
                            ),
                            const SizedBox(width: 6),
                            _badge(
                              '$credits TC',
                              AppColors.success,
                              AppColors.success.withValues(alpha: 0.12),
                            ),
                            const SizedBox(width: 6),
                            _badge(
                              '${classes.length} lớp',
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ],
                        ),
                        if (deptName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            deptName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Danh sách lớp',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showCreateClassDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm lớp'),
                  ),
                ],
              ),
            ),
            if (classes.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Chưa có lớp nào. Bấm "Thêm lớp" để tạo.'),
                    ],
                  ),
                ),
              )
            else
              ...classes.map(
                (cc) => ClassTile(
                  classData: cc,
                  courseId: course['id'] as int,
                  courseName: name,
                ),
              ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  void _showCreateClassDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    final scheduleCtrl = TextEditingController();
    final courseId = course['id'] as int;
    final courseCode = course['code'] as String? ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Thêm lớp - $courseCode'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên lớp *',
                    hintText: 'VD: CNTT-01',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scheduleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lịch học',
                    hintText: 'VD: T2 7:30-9:00',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (codeCtrl.text.trim().isEmpty) return;
                context.read<AdminBloc>().add(
                  CreateCourseClassEvent(
                    academicCourseId: courseId,
                    classCode: codeCtrl.text.trim(),
                    schedule: scheduleCtrl.text.trim().isNotEmpty
                        ? scheduleCtrl.text.trim()
                        : null,
                  ),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Tạo lớp'),
            ),
          ],
        );
      },
    );
  }
}
