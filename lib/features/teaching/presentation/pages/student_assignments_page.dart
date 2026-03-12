import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/assignment_entity.dart';
import '../bloc/student_bloc.dart';
import '../bloc/student_event.dart';
import '../bloc/student_state.dart';
import '../../../../core/services/notification_service.dart';
import 'submit_assignment_page.dart';
import '../../../../core/theme/app_colors.dart';

class StudentAssignmentsPage extends StatelessWidget {
  const StudentAssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<StudentBloc>(),
      child: const StudentAssignmentsView(),
    );
  }
}

class StudentAssignmentsView extends StatefulWidget {
  const StudentAssignmentsView({super.key});

  @override
  State<StudentAssignmentsView> createState() => _StudentAssignmentsViewState();
}

class _StudentAssignmentsViewState extends State<StudentAssignmentsView> {
  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  void _loadAssignments() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess && authState.user != null) {
      context.read<StudentBloc>().add(
        GetStudentAssignmentsEvent(authState.user!.id),
      );
    }
  }

  Color _getStatusColor(bool isCompleted, bool isLate) {
    if (isCompleted) return Colors.green;
    if (isLate) return Colors.red;
    return Colors.orange;
  }

  String _getStatusText(bool isCompleted, bool isLate) {
    if (isCompleted) return 'Đã nộp';
    if (isLate) return 'Trễ hạn';
    return 'Chưa nộp';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài Tập Của Tôi'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAssignments,
          ),
        ],
      ),
      body: BlocConsumer<StudentBloc, StudentState>(
        listenWhen: (previous, current) =>
            current is SubmissionSuccess || current is StudentAssignmentsLoaded,
        listener: (context, state) {
          if (state is SubmissionSuccess) {
            _loadAssignments();
          } else if (state is StudentAssignmentsLoaded) {
            for (final assignment in state.assignments) {
              if (!assignment.isCompleted) {
                NotificationService().scheduleAssignmentNotification(
                  id: assignment.id,
                  title: assignment.title,
                  dueDate: assignment.dueDate,
                );
              } else {
                NotificationService().cancel(assignment.id + 200000);
                NotificationService().cancel(assignment.id + 300000);
              }
            }
          }
        },
        builder: (context, state) {
          if (state is StudentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StudentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAssignments,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is StudentAssignmentsLoaded) {
            final assignments = state.assignments;

            if (assignments.isEmpty) {
              return const Center(child: Text('Không có bài tập nào.'));
            }

            return RefreshIndicator(
              onRefresh: () async => _loadAssignments(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  final isLate =
                      DateTime.now().isAfter(assignment.dueDate) &&
                      !assignment.isCompleted;
                  final statusColor = _getStatusColor(
                    assignment.isCompleted,
                    isLate,
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () async {
                        final entity = AssignmentEntity(
                          id: assignment.id,
                          classId: assignment.classId,
                          title: assignment.title,
                          description: assignment.description,
                          dueDate: assignment.dueDate,
                          rewardPoints: assignment.rewardPoints,
                          createdAt: assignment.createdAt,
                        );

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SubmitAssignmentPage(assignment: entity),
                          ),
                        );

                        if (result == true) {
                          _loadAssignments();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    assignment.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    _getStatusText(
                                      assignment.isCompleted,
                                      isLate,
                                    ),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (assignment.className != null)
                              Text(
                                'Lớp: ${assignment.className}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Hạn nộp: ${DateFormat('dd/MM/yyyy HH:mm').format(assignment.dueDate)}',
                                  style: TextStyle(
                                    color: isLate ? Colors.red : Colors.grey,
                                    fontWeight: isLate ? FontWeight.bold : null,
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
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
