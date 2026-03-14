import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/common/animated_widgets.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import '../bloc/teacher_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/create_task_dialog.dart';
import '../widgets/edit_task_dialog.dart';

import '../../../../injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';

class TeacherTasksPage extends StatefulWidget {
  const TeacherTasksPage({super.key});

  @override
  State<TeacherTasksPage> createState() => _TeacherTasksPageState();
}

class _TeacherTasksPageState extends State<TeacherTasksPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess && authState.user != null) {
      context.read<TeacherBloc>().add(LoadAssignments(authState.user!.id));
    }
  }

  void _showDeleteConfirmation(BuildContext context, int assignmentId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Xóa Bài Tập"),
        content: const Text("Bạn có chắc chắn muốn xóa bài tập này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          FilledButton(
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthSuccess && authState.user != null) {
                context.read<TeacherBloc>().add(
                  DeleteAssignmentRequested(assignmentId, authState.user!.id),
                );
              }
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text("Quản lý bài tập")),
          body: BlocConsumer<TeacherBloc, TeacherState>(
            listener: (context, state) {
              if (state is TeacherError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              } else if (state is AssignmentCreatedSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Tạo bài tập thành công!")),
                );
              } else if (state is AssignmentUpdatedSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Cập nhật bài tập thành công!")),
                );
              } else if (state is AssignmentDeletedSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Xóa bài tập thành công!")),
                );
              }
            },
            builder: (context, state) {
              if (state is TeacherLoading ||
                  state is AssignmentCreatedSuccess ||
                  state is AssignmentUpdatedSuccess ||
                  state is AssignmentDeletedSuccess) {
                return ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) =>
                      const ShimmerCard(height: 140),
                );
              } else if (state is AssignmentsLoaded) {
                if (state.assignments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PulseWidget(
                          child: Icon(
                            Icons.assignment,
                            size: 80,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInWidget(
                          delay: const Duration(milliseconds: 300),
                          child: Text(
                            "Chưa có bài tập nào.",
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return AnimationLimiter(
                  child: ListView.builder(
                    itemCount: state.assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = state.assignments[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(
                                  assignment.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (assignment.description != null)
                                      Text(assignment.description!),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Hạn nộp: ${DateFormat('dd/MM/yyyy HH:mm').format(assignment.dueDate)}",
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: AppColors.primary,
                                      ),
                                      onPressed: () {
                                        final assignmentBloc = context
                                            .read<TeacherBloc>();
                                        final dialogBloc = di.sl<TeacherBloc>();
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => BlocProvider(
                                            create: (_) => dialogBloc,
                                            child: EditTaskDialog(
                                              assignment: assignment,
                                              assignmentBloc: assignmentBloc,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: AppColors.error,
                                      ),
                                      onPressed: () {
                                        _showDeleteConfirmation(
                                          context,
                                          assignment.id!,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              } else if (state is TeacherError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Lỗi: ${state.message}"),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthSuccess &&
                              authState.user != null) {
                            context.read<TeacherBloc>().add(
                              LoadAssignments(authState.user!.id),
                            );
                          }
                        },
                        child: const Text("Thử lại"),
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: Text("Đang tải dữ liệu..."));
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final assignmentBloc = context.read<TeacherBloc>();
              final dialogBloc = di.sl<TeacherBloc>();
              showDialog(
                context: context,
                builder: (ctx) => BlocProvider(
                  create: (_) => dialogBloc,
                  child: CreateTaskDialog(assignmentBloc: assignmentBloc),
                ),
              );
            },
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
