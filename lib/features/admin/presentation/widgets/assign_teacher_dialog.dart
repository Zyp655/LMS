import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/admin_bloc.dart';

class AssignTeacherDialog extends StatelessWidget {
  final int courseClassId;
  final String classCode;
  final String courseName;

  const AssignTeacherDialog({
    super.key,
    required this.courseClassId,
    required this.classCode,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phân công GV - Lớp $classCode',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Môn: $courseName',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: BlocBuilder<AdminBloc, AdminState>(
                  buildWhen: (prev, curr) =>
                      curr is UsersLoaded || curr is AdminLoading,
                  builder: (context, state) {
                    if (state is AdminLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is UsersLoaded) {
                      final teachers = state.users;
                      if (teachers.isEmpty) {
                        return const Center(child: Text('Không có giảng viên'));
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: teachers.length,
                        itemBuilder: (context, index) {
                          final t = teachers[index];
                          final tId = t['id'] as int;
                          final tName =
                              t['fullName'] as String? ??
                              t['email'] as String? ??
                              '';
                          final tEmail = t['email'] as String? ?? '';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.15,
                              ),
                              child: Text(
                                tName.isNotEmpty ? tName[0].toUpperCase() : 'G',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              tName,
                              style: theme.textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              tEmail,
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                context.read<AdminBloc>().add(
                                  AssignCourseTeacherEvent(
                                    courseClassId: courseClassId,
                                    teacherId: tId,
                                  ),
                                );
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.add_circle,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
