import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/course/domain/entities/module_entity.dart';
import '../../../../features/course/domain/entities/lesson_entity.dart';
import '../../../../features/course/presentation/bloc/course_detail_bloc.dart';
import '../../../../features/course/presentation/bloc/course_detail_event.dart';
import '../../../../features/course/presentation/bloc/course_detail_state.dart';
import '../../../../injection_container.dart';
import '../../../../core/api/api_client.dart';
import '../widgets/dialogs/module_dialogs.dart';
import '../widgets/dialogs/add_lesson_dialog.dart';
import '../widgets/dialogs/edit_lesson_dialog.dart';
import '../widgets/dialogs/video_preview_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'teacher_ai_quiz_page.dart';

class TeacherCourseEditorPage extends StatelessWidget {
  final int courseId;

  const TeacherCourseEditorPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CourseDetailBloc>()..add(LoadCourseDetailEvent(courseId)),
      child: const TeacherCourseEditorView(),
    );
  }
}

class TeacherCourseEditorView extends StatefulWidget {
  const TeacherCourseEditorView({super.key});

  @override
  State<TeacherCourseEditorView> createState() =>
      _TeacherCourseEditorViewState();
}

class _TeacherCourseEditorViewState extends State<TeacherCourseEditorView> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: BlocConsumer<CourseDetailBloc, CourseDetailState>(
        listener: (context, state) {
          if (state is CourseDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(isDark, state),
              if (state is CourseDetailLoading || state is CourseDetailInitial)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (state is CourseDetailLoaded)
                ..._buildModuleList(state, isDark)
              else if (state is CourseDetailError)
                SliverFillRemaining(
                  child: _buildErrorState(state.message, isDark),
                ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(isDark),
    );
  }

  Widget _buildAppBar(bool isDark, CourseDetailState state) {
    String title = 'Chỉnh sửa nội dung';
    int moduleCount = 0;
    if (state is CourseDetailLoaded) {
      title = state.course.name;
      moduleCount = state.modules.length;
    }

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withAlpha(isDark ? 30 : 12),
                isDark ? AppColors.darkSurface : Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$moduleCount chương',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(bool isDark) {
    return FloatingActionButton.extended(
      heroTag: 'add_module',
      onPressed: () => ModuleDialogs.showAddModule(context),
      label: const Text(
        'Thêm chương',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      icon: const Icon(Icons.add_rounded),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Lỗi: $message',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildModuleList(CourseDetailLoaded state, bool isDark) {
    if (state.modules.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withAlpha(15),
                          AppColors.primaryDark.withAlpha(10),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_stories_outlined,
                      size: 56,
                      color: AppColors.primary.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chưa có nội dung',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bấm nút "Thêm chương" để bắt đầu',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final module = state.modules[index];
            return _ModuleTimelineItem(
              module: module,
              index: index,
              totalCount: state.modules.length,
              courseId: state.course.id,
            );
          }, childCount: state.modules.length),
        ),
      ),
    ];
  }
}

class _ModuleTimelineItem extends StatelessWidget {
  final ModuleEntity module;
  final int index;
  final int totalCount;
  final int courseId;

  const _ModuleTimelineItem({
    required this.module,
    required this.index,
    required this.totalCount,
    required this.courseId,
  });

  static const _timelineColors = [
    [Color(0xFF14B8A6), Color(0xFF0D9488)],
    [Color(0xFF3498DB), Color(0xFF2980B9)],
    [Color(0xFF9B59B6), Color(0xFF8E44AD)],
    [Color(0xFFE67E22), Color(0xFFD35400)],
    [Color(0xFFE74C3C), Color(0xFFC0392B)],
    [Color(0xFF2ECC71), Color(0xFF27AE60)],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = index == totalCount - 1;
    final isFirst = index == 0;
    final gradient = _timelineColors[index % _timelineColors.length];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 2,
                height: 14,
                color: isFirst
                    ? Colors.transparent
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withAlpha(isDark ? 40 : 60),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (!isLast)
                Positioned(
                  left: -46,
                  top: 46,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _ModuleCard(
                  module: module,
                  accentColor: gradient[0],
                  courseId: courseId,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final ModuleEntity module;
  final Color accentColor;
  final int courseId;

  const _ModuleCard({
    required this.module,
    required this.accentColor,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withAlpha(100)],
                ),
              ),
            ),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        module.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    Material(
                      color: isDark
                          ? Colors.white.withAlpha(10)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () =>
                            ModuleDialogs.showUpdateModule(context, module),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: isDark
                          ? Colors.white.withAlpha(10)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => _showDeleteModuleConfirmation(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(isDark ? 30 : 15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${module.lessons?.length ?? 0} bài học',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                children: [
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: AppColors.border(context),
                  ),
                  const SizedBox(height: 6),

                  if (module.lessons != null)
                    ...module.lessons!.map(
                      (lesson) => _LessonItem(
                        lesson: lesson,
                        accentColor: accentColor,
                        courseId: courseId,
                      ),
                    ),

                  _AddLessonButton(moduleId: module.id),

                  const SizedBox(height: 12),

                  _AssignmentSection(module: module, courseId: courseId),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteModuleConfirmation(BuildContext mainContext) {
    final isDark = Theme.of(mainContext).brightness == Brightness.dark;
    showDialog(
      context: mainContext,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Xóa chương'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn xóa chương "${module.title}"?',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tất cả bài học và quiz trong chương sẽ bị xóa vĩnh viễn.',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary(mainContext)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              BlocProvider.of<CourseDetailBloc>(mainContext).add(
                DeleteModuleEvent(
                  courseId: courseId,
                  moduleId: module.id,
                ),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(mainContext).showSnackBar(
                SnackBar(
                  content: const Text('Đã xóa chương thành công!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _LessonItem extends StatelessWidget {
  final LessonEntity lesson;
  final Color accentColor;
  final int courseId;
  const _LessonItem({
    required this.lesson,
    required this.accentColor,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVideo = lesson.type == LessonType.video;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isVideo
                ? const Color(0xFF3498DB).withAlpha(isDark ? 30 : 15)
                : const Color(0xFF9B59B6).withAlpha(isDark ? 30 : 15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isVideo ? Icons.play_circle_rounded : Icons.article_rounded,
            color: isVideo ? const Color(0xFF3498DB) : const Color(0xFF9B59B6),
            size: 20,
          ),
        ),
        title: Text(
          lesson.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          isVideo ? 'Video' : 'Tài liệu',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary(context),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              EditLessonDialog.show(context, lesson);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, lesson);
            } else if (value == 'quiz_ai') {
              _openAiQuiz(context, lesson);
            }
          },
          icon: Icon(
            Icons.more_vert_rounded,
            size: 20,
            color: AppColors.textSecondary(context),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ],
              ),
            ),
            if (lesson.type == LessonType.text)
              const PopupMenuItem(
                value: 'quiz_ai',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Tạo Quiz AI', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          if (isVideo && lesson.contentUrl != null) {
            showDialog(
              context: context,
              builder: (context) =>
                  VideoPreviewDialog(videoUrl: lesson.contentUrl!),
            );
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext mainContext, LessonEntity lesson) {
    final isDark = Theme.of(mainContext).brightness == Brightness.dark;
    showDialog(
      context: mainContext,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Xác nhận xóa'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa bài học "${lesson.title}"?',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary(mainContext)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              BlocProvider.of<CourseDetailBloc>(mainContext).add(
                DeleteLessonEvent(
                  courseId:
                      (BlocProvider.of<CourseDetailBloc>(mainContext).state
                              as CourseDetailLoaded)
                          .course
                          .id,
                  moduleId: lesson.moduleId,
                  lessonId: lesson.id,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openAiQuiz(BuildContext context, LessonEntity lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherAiQuizPage(
          courseId: courseId,
          initialContent: lesson.textContent,
        ),
      ),
    );
  }
}

class _AddLessonButton extends StatelessWidget {
  final int moduleId;
  const _AddLessonButton({required this.moduleId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => AddLessonDialog.show(context, moduleId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Thêm bài học mới',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentSection extends StatefulWidget {
  final ModuleEntity module;
  final int courseId;

  const _AssignmentSection({required this.module, required this.courseId});

  @override
  State<_AssignmentSection> createState() => _AssignmentSectionState();
}

class _AssignmentSectionState extends State<_AssignmentSection> {
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    try {
      final api = sl<ApiClient>();
      final data = await api.get(
        '/teacher/assignments?moduleId=${widget.module.id}',
      );
      debugPrint('[_loadAssignments] moduleId=${widget.module.id} response=$data');
      if (mounted) {
        setState(() {
          _assignments = List<Map<String, dynamic>>.from(
            data['assignments'] ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[_loadAssignments] error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAssignment(dynamic id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài tập'),
        content: const Text('Bạn có chắc chắn muốn xóa bài tập này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final api = sl<ApiClient>();
      await api.delete('/teacher/assignments/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa bài tập!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadAssignments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa bài tập: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateAssignmentDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.assignment_add,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Tạo bài tập mới'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề bài tập *',
                    hintText: 'VD: Bài tập thực hành Chương 1',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceVariant
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Nội dung yêu cầu',
                    hintText: 'Nhập yêu cầu bài tập...',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceVariant
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 23, minute: 59),
                      );
                      setDialogState(() {
                        selectedDueDate = DateTime(
                          picked.year, picked.month, picked.day,
                          time?.hour ?? 23, time?.minute ?? 59,
                        );
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hạn nộp',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${selectedDueDate.day}/${selectedDueDate.month}/${selectedDueDate.year} – ${selectedDueDate.hour.toString().padLeft(2, '0')}:${selectedDueDate.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_rounded, size: 16, color: AppColors.textSecondary(context)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Hủy',
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tiêu đề')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _createAssignment(
                  titleController.text.trim(),
                  descController.text.trim(),
                  selectedDueDate,
                );
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tạo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAssignment(String title, String description, DateTime dueDate) async {
    try {
      final courseId =
          (BlocProvider.of<CourseDetailBloc>(context).state
                  as CourseDetailLoaded)
              .course
              .id;

      final api = sl<ApiClient>();
      final authState = context.read<AuthBloc>().state;
      final teacherId = (authState is AuthSuccess && authState.user != null)
          ? authState.user!.id
          : 1;
      final response = await api.post('/teacher/create_assignment', {
        'classId': courseId,
        'teacherId': teacherId,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'moduleId': widget.module.id,
      });
      debugPrint('[_createAssignment] response=$response');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo bài tập thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadAssignments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo bài tập: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A2E1A), const Color(0xFF16381E)]
              : [const Color(0xFFF0FFF4), const Color(0xFFE6FFED)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4A2A) : const Color(0xFFC6F6D5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Bài tập',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              if (_assignments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_assignments.length}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_assignments.isEmpty)
            Text(
              'Chưa có bài tập nào cho chương này',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary(context),
              ),
            )
          else
            ..._assignments.map(
              (a) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(8)
                      : Colors.white.withAlpha(180),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a['title'] ?? 'Bài tập',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _deleteAssignment(a['id']),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showCreateAssignmentDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Tạo bài tập', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B894),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherAiQuizPage(
                          courseId: widget.courseId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Tạo Quiz AI', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
