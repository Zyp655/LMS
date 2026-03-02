import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/admin_bloc.dart';
import '../widgets/course_class_card.dart';

class CourseTab extends StatefulWidget {
  const CourseTab({super.key});

  @override
  State<CourseTab> createState() => _CourseTabState();
}

class _CourseTabState extends State<CourseTab> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = false;
  int? _expandedCourseId;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() {
    context.read<AdminBloc>().add(LoadAcademicCoursesWithTeachers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AcademicCoursesWithTeachersLoaded) {
          setState(() {
            _courses = state.courses;
            _isLoading = false;
          });
        } else if (state is AdminLoading && _courses.isEmpty) {
          setState(() => _isLoading = true);
        } else if (state is AdminActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          _loadCourses();
        } else if (state is AssignNeedConfirm) {
          _showReplaceConfirmDialog(context, state);
        } else if (state is AdminError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm môn học...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadCourses,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  void _showReplaceConfirmDialog(BuildContext ctx, AssignNeedConfirm state) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        icon: Icon(Icons.swap_horiz, color: AppColors.warning, size: 36),
        title: const Text('Xác nhận thay thế'),
        content: Text(state.message),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ctx.read<AdminBloc>().add(
                AssignCourseTeacherEvent(
                  courseClassId: state.courseClassId,
                  teacherId: state.newTeacherId,
                  force: true,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Thay thế'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _courses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    var courses = _courses;
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      courses = courses.where((c) {
        final name = (c['name'] as String? ?? '').toLowerCase();
        final code = (c['code'] as String? ?? '').toLowerCase();
        return name.contains(query) || code.contains(query);
      }).toList();
    }

    if (courses.isEmpty && _courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              size: 48,
              color: AppColors.textSecondary(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn refresh để tải danh sách',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        final courseId = course['id'] as int;
        final isExpanded = _expandedCourseId == courseId;
        return CourseClassCard(
          course: course,
          isExpanded: isExpanded,
          onToggle: () {
            setState(() {
              _expandedCourseId = isExpanded ? null : courseId;
            });
          },
        );
      },
    );
  }
}
