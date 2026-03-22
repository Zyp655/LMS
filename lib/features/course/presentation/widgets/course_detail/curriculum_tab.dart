import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/route/app_route.dart';
import '../../../../../core/services/content_analyzer_service.dart';
import '../../../domain/entities/module_entity.dart';
import '../../../domain/entities/lesson_entity.dart';
import '../../bloc/course_detail_bloc.dart';
import '../../bloc/course_detail_event.dart';
import '../../pages/course_submissions_page.dart';
import '../../pages/module_quiz_page.dart';

class CurriculumTab extends StatefulWidget {
  final List<ModuleEntity> modules;
  final int courseId;
  final int? userId;

  const CurriculumTab({
    super.key,
    required this.modules,
    required this.courseId,
    this.userId,
  });

  @override
  State<CurriculumTab> createState() => _CurriculumTabState();
}

class _CurriculumTabState extends State<CurriculumTab> {
  int? _expandedIndex;
  final Map<int, Map<String, dynamic>?> _moduleQuizzes = {};
  final Set<int> _loadingQuizModules = {};

  void _loadQuizForModule(int moduleId) async {
    if (_loadingQuizModules.contains(moduleId) ||
        _moduleQuizzes.containsKey(moduleId)) {
      return;
    }
    _loadingQuizModules.add(moduleId);

    try {
      final result = await ContentAnalyzerService().getSavedQuiz(
        moduleId: moduleId,
      );
      if (mounted) {
        setState(() {
          _moduleQuizzes[moduleId] = result;
          _loadingQuizModules.remove(moduleId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingQuizModules.remove(moduleId));
      }
    }
  }

  Future<Map<String, dynamic>?> _getQuizResult(int moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'quiz_result_$moduleId';
    final resultJson = prefs.getString(key);
    if (resultJson != null) {
      return jsonDecode(resultJson) as Map<String, dynamic>;
    }
    return null;
  }

  Map<String, LessonEntity?> _findAdjacentLessons(
    List<ModuleEntity> modules,
    LessonEntity currentLesson,
  ) {
    LessonEntity? previousLesson;
    LessonEntity? nextLesson;

    final allLessons = <LessonEntity>[];
    for (final module in modules) {
      if (module.lessons != null) {
        allLessons.addAll(module.lessons!);
      }
    }

    final currentIndex = allLessons.indexWhere((l) => l.id == currentLesson.id);

    if (currentIndex != -1) {
      if (currentIndex > 0) {
        previousLesson = allLessons[currentIndex - 1];
      }
      if (currentIndex < allLessons.length - 1) {
        nextLesson = allLessons[currentIndex + 1];
      }
    }

    return {'previous': previousLesson, 'next': nextLesson};
  }

  @override
  Widget build(BuildContext context) {
    if (widget.modules.isEmpty) {
      return const Center(child: Text('Nội dung đang được cập nhật...'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.modules.length,
      itemBuilder: (context, index) {
        final module = widget.modules[index];
        final isModuleLocked = !module.isUnlocked;

        if (isModuleLocked) {
          final unlockStr = module.unlockDate != null
              ? '${module.unlockDate!.day}/${module.unlockDate!.month}/${module.unlockDate!.year}'
              : '';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Center(child: Icon(Icons.lock, color: Colors.white, size: 20)),
              ),
              title: Text(
                module.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              subtitle: Text(
                '🔒 Mở khóa vào $unlockStr',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Chưa mở',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Chương này sẽ mở khóa vào ngày $unlockStr'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: ValueKey('module_${module.id}_${_expandedIndex == index}'),
              initiallyExpanded: _expandedIndex == index,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedIndex = expanded ? index : null;
                });
              },
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                module.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                '${module.lessons?.length ?? 0} bài học',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              children: [
                ...?module.lessons?.map(
                  (lesson) =>
                      _buildLessonItem(lesson, widget.modules, widget.courseId),
                ),
                Builder(
                  builder: (context) {
                    if (!_moduleQuizzes.containsKey(module.id) &&
                        !_loadingQuizModules.contains(module.id)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _loadQuizForModule(module.id);
                      });
                    }

                    final quizData = _moduleQuizzes[module.id];
                    final hasQuiz =
                        quizData != null &&
                        quizData['quiz'] != null &&
                        quizData['questions'] != null &&
                        (quizData['questions'] as List).isNotEmpty;

                    if (hasQuiz) {
                      final quiz = quizData['quiz'] as Map<String, dynamic>;
                      final questions = quizData['questions'] as List;

                      final lessons = module.lessons ?? [];
                      final completedLessons =
                          lessons.where((l) => l.isCompleted).length;
                      final allLessonsCompleted =
                          lessons.isNotEmpty &&
                          completedLessons == lessons.length;

                      return _buildQuizLessonItem(
                        module.id,
                        quiz['topic'] ?? 'Bài kiểm tra',
                        questions.length,
                        isLocked: !allLessonsCompleted,
                        completedLessons: completedLessons,
                        totalLessons: lessons.length,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
      },
    );
  }

  Widget _buildLessonItem(
    LessonEntity lesson,
    List<ModuleEntity> allModules,
    int courseId,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          lesson.isCompleted
              ? Icons.check_circle
              : (lesson.type == LessonType.video
                    ? Icons.play_circle_fill
                    : Icons.article),
          color: lesson.isCompleted ? AppColors.success : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        lesson.title,
        style: TextStyle(
          fontSize: 14,
          color: lesson.isCompleted ? Colors.grey[600] : Colors.black,
          decoration: lesson.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${lesson.durationMinutes}m',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!lesson.isCompleted)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Icon(Icons.check, color: Colors.grey[400], size: 18),
            )
          else
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 18,
              ),
            ),
        ],
      ),
      onTap: () {
        final adjacent = _findAdjacentLessons(allModules, lesson);
        context.push(
          AppRoutes.lessonPlayer,
          extra: {
            'lesson': lesson,
            'userId': widget.userId,
            'previousLesson': adjacent['previous'],
            'nextLesson': adjacent['next'],
            'allModules': allModules,
          },
        ).then((_) {
          if (mounted) {
            context.read<CourseDetailBloc>().add(
              LoadCourseDetailEvent(courseId, userId: widget.userId),
            );
          }
        });
      },
      onLongPress: lesson.type == LessonType.assignment
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseSubmissionsPage(
                    assignmentId: lesson.id,
                    assignmentTitle: lesson.title,
                  ),
                ),
              );
            }
          : null,
    );
  }

  Widget _buildQuizLessonItem(
    int moduleId,
    String title,
    int questionCount, {
    bool isLocked = false,
    int completedLessons = 0,
    int totalLessons = 0,
  }) {
    if (isLocked) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[200]!, Colors.grey[100]!],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.lock, color: Colors.white, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          subtitle: Text(
            '🔒 Hoàn thành $completedLessons/$totalLessons bài để mở khóa',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Khóa',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Hoàn thành tất cả ${totalLessons - completedLessons} bài học còn lại để mở khóa quiz!',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getQuizResult(moduleId),
      builder: (context, snapshot) {
        final result = snapshot.data;
        final isCompleted = result != null;
        final score = result?['score'] as int? ?? 0;
        final total = result?['total'] as int? ?? questionCount;
        final percentage = result?['percentage'] as int? ?? 0;
        final isPassing = percentage >= 70;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCompleted
                  ? (isPassing
                        ? [AppColors.success.withValues(alpha: 0.1), const Color(0xFFC8E6C9)]
                        : [AppColors.warning.withValues(alpha: 0.1), AppColors.warningLight])
                  : [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.warningLight,
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted
                  ? (isPassing
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.warning.withValues(alpha: 0.3))
                  : AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCompleted
                    ? (isPassing ? AppColors.success : AppColors.warning)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCompleted
                    ? (isPassing ? Icons.check_circle : Icons.refresh)
                    : Icons.quiz,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isPassing ? AppColors.success : AppColors.warning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$score/$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              isCompleted
                  ? (isPassing
                        ? '✅ Đã hoàn thành • $percentage%'
                        : '⚠️ Cần cải thiện • $percentage%')
                  : '$questionCount câu hỏi trắc nghiệm',
              style: TextStyle(
                color: isCompleted
                    ? (isPassing ? Colors.green[700] : Colors.orange[700])
                    : Colors.grey[600],
                fontSize: 12,
                fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? (isPassing
                          ? AppColors.successLight.withValues(alpha: 0.3)
                          : AppColors.primary)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                border: isCompleted && isPassing
                    ? Border.all(color: AppColors.success)
                    : null,
              ),
              child: Text(
                isCompleted ? (isPassing ? 'Xem lại' : 'Làm lại') : 'Làm bài',
                style: TextStyle(
                  color: isCompleted && isPassing
                      ? AppColors.successDark
                      : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ModuleQuizPage(moduleId: moduleId, moduleTitle: title),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        );
      },
    );
  }
}
