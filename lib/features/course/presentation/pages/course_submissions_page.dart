import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../bloc/submission_bloc.dart';
import '../../../../injection_container.dart' as di;
import 'submission_grading_page.dart';
import '../../../../core/theme/app_colors.dart';

class CourseSubmissionsPage extends StatelessWidget {
  final int assignmentId;
  final String assignmentTitle;

  const CourseSubmissionsPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          di.sl<SubmissionBloc>()..add(LoadAllSubmissionsEvent(assignmentId)),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Danh sách bài nộp'),
              Text(
                assignmentTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        body: BlocBuilder<SubmissionBloc, SubmissionState>(
          builder: (context, state) {
            if (state is SubmissionLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SubmissionError) {
              return Center(child: Text(state.message));
            } else if (state is AllSubmissionsLoaded) {
              if (state.submissions.isEmpty) {
                return const Center(child: Text('Chưa có bài nộp nào.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.submissions.length,
                itemBuilder: (context, index) {
                  final submission = state.submissions[index];
                  final isGraded = submission.grade != null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isGraded
                            ? Colors.green
                            : Colors.orange,
                        child: Icon(
                          isGraded ? Icons.check : Icons.access_time,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        submission.studentName ??
                            'Học viên #${submission.studentId}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nộp: ${timeago.format(submission.submittedAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (isGraded)
                            Text(
                              'Điểm: ${submission.grade}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          if (submission.linkUrl != null)
                            Text(
                              'Link: ${submission.linkUrl}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.info,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubmissionGradingPage(
                              submissionId: submission.id,
                              studentName:
                                  submission.studentName ??
                                  'Student #${submission.studentId}',
                              textContent: submission.textContent,
                              linkUrl: submission.linkUrl,
                            ),
                          ),
                        );
                        if (result == true) {
                          context.read<SubmissionBloc>().add(
                            LoadAllSubmissionsEvent(assignmentId),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
