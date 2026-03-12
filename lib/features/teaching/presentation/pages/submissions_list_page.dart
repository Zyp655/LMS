import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/assignment_entity.dart';
import '../widgets/grade_submission_dialog.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import '../bloc/teacher_state.dart';
import '../../../../core/theme/app_colors.dart';

class SubmissionsListPage extends StatefulWidget {
  final AssignmentEntity assignment;

  const SubmissionsListPage({Key? key, required this.assignment})
    : super(key: key);

  @override
  State<SubmissionsListPage> createState() => _SubmissionsListPageState();
}

class _SubmissionsListPageState extends State<SubmissionsListPage> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  void _loadSubmissions() {
    if (widget.assignment.id != null) {
      context.read<TeacherBloc>().add(GetSubmissions(widget.assignment.id!));
    }
  }

  Future<void> _gradeSubmission(
    int submissionId,
    double grade,
    String? feedback,
  ) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess || authState.user == null) return;

    context.read<TeacherBloc>().add(
      GradeSubmission(
        submissionId: submissionId,
        grade: grade,
        feedback: feedback,
        teacherId: authState.user!.id,
      ),
    );
  }

  List<dynamic> _filterSubmissions(List<dynamic> submissions) {
    if (_filter == 'all') return submissions;
    if (_filter == 'graded') {
      return submissions.where((s) => s['status'] == 'graded').toList();
    }
    if (_filter == 'submitted') {
      return submissions.where((s) => s['status'] == 'submitted').toList();
    }
    return submissions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Sách Bài Nộp'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSubmissions,
          ),
        ],
      ),
      body: BlocConsumer<TeacherBloc, TeacherState>(
        listener: (context, state) {
          if (state is TeacherError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is SubmissionGradedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                    content: Text('Chấm bài thành công'),
                backgroundColor: AppColors.success,
              ),
            );
            _loadSubmissions();
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppColors.info.withValues(alpha: 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.assignment.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hạn nộp: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.assignment.dueDate)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

              if (state is SubmissionsLoaded)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'all',
                        'Tất cả (${state.submissions.length})',
                        Icons.all_inbox,
                      ),
                      _buildFilterChip(
                        'submitted',
                        'Đã nộp (${state.submissions.where((s) => s['status'] == 'submitted').length})',
                        Icons.upload,
                      ),
                      _buildFilterChip(
                        'graded',
                        'Đã chấm (${state.submissions.where((s) => s['status'] == 'graded').length})',
                        Icons.grade,
                      ),
                    ],
                  ),
                ),

              Expanded(child: _buildContent(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(TeacherState state) {
    if (state is TeacherLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is SubmissionsLoaded) {
      final filtered = _filterSubmissions(state.submissions);

      if (filtered.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Chưa có bài nộp nào',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: filtered.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final submission = filtered[index];
          return _buildSubmissionCard(submission);
        },
      );
    }

    return const Center(child: Text('Vui lòng tải lại danh sách'));
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    final isGraded = submission['status'] == 'graded';
    final isLate = submission['isLate'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isGraded ? Colors.green : Colors.orange,
          child: Icon(
            isGraded ? Icons.check : Icons.pending,
            color: Colors.white,
          ),
        ),
        title: Text(
          submission['studentName'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(submission['studentEmail'] ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat(
                    'dd/MM HH:mm',
                  ).format(DateTime.parse(submission['submittedAt'])),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (isLate) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Trễ',
                      style: TextStyle(fontSize: 10, color: AppColors.error),
                    ),
                  ),
                ],
              ],
            ),
            if (isGraded)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      'Điểm: ${submission['grade']}/${submission['maxGrade'] ?? 10}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => GradeSubmissionDialog(
                studentName: submission['studentName'] ?? 'Unknown',
                submissionId: submission['id'],
                onGrade: (grade, feedback) async {
                  await _gradeSubmission(submission['id'], grade, feedback);
                },
              ),
            );
          },
          icon: Icon(isGraded ? Icons.edit : Icons.grade),
          label: Text(isGraded ? 'Sửa' : 'Chấm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isGraded ? Colors.orange : Colors.blue,
          ),
        ),
        onTap: () {
          _showSubmissionDetail(submission);
        },
      ),
    );
  }

  void _showSubmissionDetail(Map<String, dynamic> submission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(submission['studentName'] ?? 'Chi tiết bài nộp'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (submission['linkUrl'] != null) ...[
                const Text(
                  'Link:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText(submission['linkUrl']),
                const SizedBox(height: 8),
              ],
              if (submission['fileName'] != null) ...[
                const Text(
                  'File:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(submission['fileName']),
                const SizedBox(height: 8),
              ],
              if (submission['textContent'] != null) ...[
                const Text(
                  'Nội dung:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(submission['textContent']),
                const SizedBox(height: 8),
              ],
              if (submission['feedback'] != null) ...[
                const Divider(),
                const Text(
                  'Nhận xét:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(submission['feedback']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          if (selected) setState(() => _filter = value);
        },
      ),
    );
  }
}
