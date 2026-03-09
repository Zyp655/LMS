import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../../../teaching/presentation/bloc/student_bloc.dart';
import '../../../teaching/presentation/bloc/student_event.dart';
import '../../../teaching/presentation/bloc/student_state.dart';
import '../../../teaching/presentation/pages/submit_assignment_page.dart';
import '../../../teaching/domain/entities/assignment_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/theme/app_colors.dart';

class CourseAssignmentsTab extends StatelessWidget {
  final int courseId;

  const CourseAssignmentsTab({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<StudentBloc>();
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthSuccess && authState.user != null) {
          bloc.add(GetStudentAssignmentsEvent(authState.user!.id));
        }
        return bloc;
      },
      child: BlocBuilder<StudentBloc, StudentState>(
        builder: (context, state) {
          if (state is StudentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StudentError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Không thể tải bài tập',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is StudentAssignmentsLoaded) {
            final assignments = state.assignments;

            if (assignments.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có bài tập nào',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                final isLate =
                    DateTime.now().isAfter(assignment.dueDate) &&
                    !assignment.isCompleted;
                final statusColor = assignment.isCompleted
                    ? Colors.green
                    : isLate
                    ? Colors.red
                    : Colors.orange;
                final statusText = assignment.isCompleted
                    ? 'Đã nộp'
                    : isLate
                    ? 'Trễ hạn'
                    : 'Chưa nộp';

                final isDark = Theme.of(context).brightness == Brightness.dark;
                final cardColor = isDark
                    ? AppColors.darkSurface
                    : Colors.white;
                final textColor = isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight;
                final subtextColor = isDark
                    ? Colors.grey[400]!
                    : AppColors.textSecondaryLight;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubmitAssignmentPage(
                            assignment: AssignmentEntity(
                              id: assignment.id,
                              classId: assignment.classId,
                              title: assignment.title,
                              description: assignment.description,
                              dueDate: assignment.dueDate,
                              rewardPoints: assignment.rewardPoints,
                              createdAt: assignment.createdAt,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  assignment.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
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
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: subtextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(assignment.dueDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isLate ? Colors.red : subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
