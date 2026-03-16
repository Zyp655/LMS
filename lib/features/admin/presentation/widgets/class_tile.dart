import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../bloc/admin_bloc.dart';
import 'assign_teacher_dialog.dart';

class ClassTile extends StatelessWidget {
  final Map<String, dynamic> classData;
  final int courseId;
  final String courseName;

  const ClassTile({
    super.key,
    required this.classData,
    required this.courseId,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ccId = classData['courseClassId'] as int? ?? 0;
    final classCode = classData['classCode'] as String? ?? '';
    final teacherName = classData['teacherName'] as String?;
    final teacherId = classData['teacherId'] as int?;
    final dayOfWeek = classData['dayOfWeek'] as int?;
    final hasTeacher =
        teacherId != null && teacherName != null && teacherName != 'Unknown';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasTeacher
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (hasTeacher ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasTeacher ? Icons.check_circle : Icons.pending,
                color: hasTeacher ? AppColors.success : AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classCode,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (dayOfWeek != null)
                    Text(
                      'Thứ $dayOfWeek',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  const SizedBox(height: 2),
                  if (hasTeacher)
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            teacherName,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              _confirmUnassign(context, teacherName, ccId),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Chưa phân công GV',
                      style: TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () =>
                  _showEditDialog(context, ccId, classCode),
              icon: Icon(Icons.edit_outlined, color: AppColors.info),
              tooltip: 'Sửa lớp',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () => _showAssignDialog(context, ccId, classCode),
              icon: Icon(
                hasTeacher ? Icons.swap_horiz : Icons.person_add,
                color: AppColors.primary,
              ),
              tooltip: hasTeacher ? 'Đổi GV' : 'Phân công GV',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () => _confirmDelete(context, ccId, classCode),
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Xóa lớp',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    int ccId,
    String currentCode,
  ) {
    final codeCtrl = TextEditingController(text: currentCode);
    final bloc = context.read<AdminBloc>();

    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: _EditClassDialog(
          courseClassId: ccId,
          courseId: courseId,
          codeCtrl: codeCtrl,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int ccId, String classCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lớp'),
        content: Text(
          'Bạn có chắc muốn xóa lớp "$classCode"?\nTất cả ghi danh của lớp này sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminBloc>().add(
                DeleteCourseClassEvent(courseClassId: ccId),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa lớp'),
          ),
        ],
      ),
    );
  }

  void _confirmUnassign(BuildContext context, String teacherName, int ccId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bỏ phân công'),
        content: Text('Bỏ phân công "$teacherName" khỏi lớp này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminBloc>().add(
                UnassignCourseTeacherEvent(courseClassId: ccId),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Bỏ phân công'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, int ccId, String classCode) {
    final bloc = context.read<AdminBloc>();
    bloc.add(LoadUsers(role: 1));

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return BlocProvider.value(
          value: bloc,
          child: AssignTeacherDialog(
            courseClassId: ccId,
            classCode: classCode,
            courseName: courseName,
          ),
        );
      },
    );
  }
}

class _EditClassDialog extends StatefulWidget {
  final int courseClassId;
  final int courseId;
  final TextEditingController codeCtrl;

  const _EditClassDialog({
    required this.courseClassId,
    required this.courseId,
    required this.codeCtrl,
  });

  @override
  State<_EditClassDialog> createState() => _EditClassDialogState();
}

class _EditClassDialogState extends State<_EditClassDialog> {
  bool _isSaving = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminActionSuccess) {
          Navigator.pop(context);
        } else if (state is AdminError) {
          setState(() {
            _isSaving = false;
            _errorMessage = state.message;
          });
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sửa lớp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: widget.codeCtrl,
              decoration: InputDecoration(
                labelText: 'Tên lớp *',
                prefixIcon: const Icon(Icons.class_rounded, size: 20),
                errorText: _errorMessage,
                errorMaxLines: 2,
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(_isSaving ? 'Đang lưu...' : 'Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final newCode = widget.codeCtrl.text.trim();
    if (newCode.isEmpty) {
      setState(() => _errorMessage = 'Tên lớp không được trống');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final api = sl<ApiClient>();
      await api.put('/academic/classes', {
        'id': widget.courseClassId,
        'classCode': newCode,
      });
      if (!mounted) return;
      context.read<AdminBloc>().add(LoadAcademicCoursesWithTeachers());
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cập nhật lớp thành công'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Lỗi: $e';
      });
    }
  }
}
