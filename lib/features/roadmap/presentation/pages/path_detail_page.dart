import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/api/api_client.dart';
import '../../data/learning_paths_data.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/theme/app_colors.dart';

class PathDetailPage extends StatefulWidget {
  final LearningPath path;

  const PathDetailPage({super.key, required this.path});

  @override
  State<PathDetailPage> createState() => _PathDetailPageState();
}

class _PathDetailPageState extends State<PathDetailPage> {
  Map<String, CourseProgress> courseProgressByTitle = {};
  int? expandedMilestoneIndex;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealProgress();
  }

  Future<void> _loadRealProgress() async {
    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState is AuthSuccess ? authState.user?.id : null;

      final api = GetIt.instance<ApiClient>();
      final queryParam = userId != null ? '?userId=$userId' : '';
      final data =
          await api.get('/roadmap-progress$queryParam') as Map<String, dynamic>;
      final courses = data['courses'] as List;

      setState(() {
        for (final course in courses) {
          final title = course['title'] as String;
          courseProgressByTitle[title] = CourseProgress(
            courseId: course['id'] as int,
            totalLessons: course['totalLessons'] as int,
            completedLessons: course['completedLessons'] as int,
            isCompleted: course['isCompleted'] as bool,
          );
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  CourseProgress? _getProgressForMilestone(LearningMilestone milestone) {
    return courseProgressByTitle[milestone.title];
  }

  @override
  Widget build(BuildContext context) {
    final startColor = _hexToColor(widget.path.gradientStart);
    final endColor = _hexToColor(widget.path.gradientEnd);
    int completedCount = 0;
    int totalCount = 0;

    for (final milestone in widget.path.milestones) {
      final progress = _getProgressForMilestone(milestone);
      if (progress != null) {
        completedCount += progress.completedLessons;
        totalCount += progress.totalLessons;
      } else {
        totalCount += milestone.steps.length;
      }
    }

    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(
            startColor,
            endColor,
            progress,
            completedCount,
            totalCount,
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMilestoneCard(
                    index,
                    widget.path.milestones[index],
                    startColor,
                  ),
                  childCount: widget.path.milestones.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
    Color startColor,
    Color endColor,
    double progress,
    int completed,
    int total,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: startColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [startColor, endColor],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.path.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.path.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.white.withAlpha(76),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$completed/$total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(
    int index,
    LearningMilestone milestone,
    Color accentColor,
  ) {
    final isExpanded = expandedMilestoneIndex == index;
    final progress = _getProgressForMilestone(milestone);
    final hasCourse = progress != null;

    final completedInMilestone = progress?.completedLessons ?? 0;
    final totalInMilestone = progress?.totalLessons ?? milestone.steps.length;
    final allCompleted = progress?.isCompleted ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(16),
        border: allCompleted
            ? Border.all(color: AppColors.success.withAlpha(128), width: 2)
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                expandedMilestoneIndex = isExpanded ? null : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: allCompleted
                          ? Colors.green.withAlpha(51)
                          : accentColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: allCompleted
                          ? Icon(Icons.check, color: AppColors.success)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                milestone.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (hasCourse)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withAlpha(51),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_circle_outline,
                                      color: accentColor,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Khóa học',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedInMilestone/$totalInMilestone hoàn thành',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildStepsList(index, milestone, accentColor),
        ],
      ),
    );
  }

  Widget _buildStepsList(
    int milestoneIndex,
    LearningMilestone milestone,
    Color accentColor,
  ) {
    final progress = _getProgressForMilestone(milestone);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          if (progress != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCourse(progress.courseId),
                icon: Icon(Icons.play_arrow),
                label: const Text('Vào khóa học'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ...milestone.steps.take(5).map((step) {
            return Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Icon(
                  Icons.circle_outlined,
                  color: accentColor,
                  size: 20,
                ),
                title: Text(
                  step.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                trailing: _buildStepTypeBadge(step.type),
              ),
            );
          }),

          if (milestone.steps.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showAllLessonsDialog(milestone, accentColor);
                      },
                      icon: Icon(Icons.list, size: 18),
                      label: Text(
                        '+ ${milestone.steps.length - 5} bài học khác',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[400],
                        side: BorderSide(color: Colors.grey[600]!),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _navigateToCourse(progress.courseId),
                      icon: Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Vào học'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: BorderSide(color: accentColor),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAllLessonsDialog(LearningMilestone milestone, Color accentColor) {
    final progress = _getProgressForMilestone(milestone);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      milestone.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${milestone.steps.length} bài học',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (progress != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToCourse(progress.courseId);
                    },
                    icon: Icon(Icons.play_arrow),
                    label: const Text('Vào khóa học để học chi tiết'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: milestone.steps.length,
                itemBuilder: (context, index) {
                  final step = milestone.steps[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        step.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      trailing: _buildStepTypeBadge(step.type),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCourse(int courseId) {
    context.push('/courses/$courseId').then((_) => _loadRealProgress());
  }

  Widget _buildStepTypeBadge(String type) {
    Color bgColor;
    Color textColor;
    String label;

    switch (type) {
      case 'lesson':
        bgColor = AppColors.info.withAlpha(51);
        textColor = AppColors.info;
        label = 'Bài học';
        break;
      case 'project':
        bgColor = AppColors.warning.withAlpha(51);
        textColor = AppColors.warning;
        label = 'Dự án';
        break;
      case 'quiz':
        bgColor = Colors.purple.withAlpha(51);
        textColor = Colors.purple;
        label = 'Quiz';
        break;
      default:
        bgColor = Colors.grey.withAlpha(51);
        textColor = Colors.grey;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class CourseProgress {
  final int courseId;
  final int totalLessons;
  final int completedLessons;
  final bool isCompleted;

  CourseProgress({
    required this.courseId,
    required this.totalLessons,
    required this.completedLessons,
    required this.isCompleted,
  });
}
