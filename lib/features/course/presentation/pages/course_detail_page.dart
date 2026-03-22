import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/lesson_entity.dart';
import '../bloc/course_detail_bloc.dart';
import '../bloc/course_detail_event.dart';
import '../bloc/course_detail_state.dart';
import '../../../../injection_container.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/route/app_route.dart';
import '../widgets/study_plan_setup_dialog.dart';
import '../widgets/course_hero_header.dart';
import '../widgets/course_curriculum_tab.dart';
import '../widgets/course_assignments_tab.dart';
import '../widgets/course_reviews_tab.dart';
import '../widgets/course_students_tab.dart';
import '../../../schedule/presentation/bloc/schedule_bloc.dart';
import '../../../schedule/presentation/bloc/schedule_event.dart';
import '../../../../core/theme/app_colors.dart';

class CourseDetailPage extends StatelessWidget {
  final int courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final userId = sl<SharedPreferences>().getInt('current_user_id');

    return BlocProvider(
      create: (context) =>
          sl<CourseDetailBloc>()
            ..add(LoadCourseDetailEvent(courseId, userId: userId)),
      child: CourseDetailView(userId: userId),
    );
  }
}

class CourseDetailView extends StatefulWidget {
  final int? userId;

  const CourseDetailView({super.key, this.userId});

  @override
  State<CourseDetailView> createState() => _CourseDetailViewState();
}

class _CourseDetailViewState extends State<CourseDetailView>
    with TickerProviderStateMixin {
  TabController? _tabController;
  bool _isEnrolled = false;

  String _instructorName = '';
  int? _instructorId;
  bool _creatingChat = false;

  @override
  void initState() {
    super.initState();
    _initTabController(false);
  }

  void _initTabController(bool enrolled) {
    final old = _tabController;
    _tabController = null;
    old?.dispose();
    _isEnrolled = enrolled;
    _tabController = TabController(length: enrolled ? 1 : 4, vsync: this);
  }

  Future<void> _fetchInstructorFromClass(int courseId) async {
    try {
      final api = sl<ApiClient>();
      final res = await api.get(
        '/academic/courses/$courseId?userId=${widget.userId ?? 0}',
      );
      final classes = res['classes'] as List? ?? [];
      final enrollment = res['enrollment'] as Map<String, dynamic>?;

      if (classes.isNotEmpty) {
        Map<String, dynamic>? matchedClass;
        if (enrollment != null) {
          final enrolledClassCode = enrollment['classCode'] as String?;
          if (enrolledClassCode != null) {
            matchedClass = classes
                .cast<Map<String, dynamic>>()
                .where((c) => c['classCode'] == enrolledClassCode)
                .firstOrNull;
          }
        }
        matchedClass ??= classes.first as Map<String, dynamic>;

        final teacherName = matchedClass['teacherName'] as String? ?? '';
        final teacherId = matchedClass['teacherId'] as int?;
        if (mounted && teacherName.isNotEmpty) {
          setState(() {
            _instructorName = teacherName;
            _instructorId = teacherId;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[_fetchInstructorFromClass] $e');
    }
    if (mounted) setState(() => _instructorName = 'Giảng viên');
  }

  Future<void> _openChatWithInstructor(int instructorId) async {
    if (_creatingChat) return;
    setState(() => _creatingChat = true);
    try {
      final api = sl<ApiClient>();
      final userId = widget.userId ?? 0;
      final res = await api.post('/chat', {
        'user1Id': userId,
        'user2Id': instructorId,
      });
      final conversationId = res['id'] as int;
      if (mounted) {
        context.push(
          AppRoutes.chatRoom,
          extra: {
            'conversationId': conversationId,
            'participantName': _instructorName.isNotEmpty
                ? _instructorName
                : 'Giảng viên',
            'isTeacher': true,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể mở chat: $e')));
      }
    } finally {
      if (mounted) setState(() => _creatingChat = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: BlocConsumer<CourseDetailBloc, CourseDetailState>(
        listener: (context, state) {
          if (state is CourseDetailLoaded) {
            final enrolled = state.enrollment != null;
            if (enrolled != _isEnrolled) {
              setState(() => _initTabController(enrolled));
            }
            _fetchInstructorFromClass(state.course.id);
            if (state.actionError != null) {
              showDialog(
                context: context,
                barrierColor: Colors.black.withValues(alpha: 0.7),
                builder: (context) =>
                    _buildActionErrorDialog(context, state.actionError!),
              );
            } else if (state.isJustEnrolled) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Đăng ký môn học thành công!'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => StudyPlanSetupDialog(
                  courseId: state.course.id,
                  onSaved: () {
                    sl<ScheduleBloc>().add(LoadSchedules());
                  },
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is CourseDetailLoading || state is CourseDetailInitial) {
            return _buildLoadingState();
          } else if (state is CourseDetailLoaded) {
            return _buildContent(context, state);
          } else if (state is CourseDetailError) {
            return _buildErrorState(state.message);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildActionErrorDialog(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.info_outline, size: 32, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            const Text(
              "Thông báo",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Đã hiểu",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(expandedHeight: 280, pinned: true),
        SliverToBoxAdapter(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 24, width: 200, color: Colors.white),
                  const SizedBox(height: 16),
                  Container(height: 60, color: Colors.white),
                  const SizedBox(height: 24),
                  Container(height: 200, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.error.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 24),
          Text(message, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CourseDetailLoaded state) {
    final isEnrolled = state.enrollment != null;
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            CourseHeroHeader.buildAppBar(context, state.course),
            CourseHeroHeader(
              course: state.course,
              state: state,
              instructorName: _instructorName,
              creatingChat: _creatingChat,
              onChatTap: _instructorId != null
                  ? () => _openChatWithInstructor(_instructorId!)
                  : null,
            ),
            SliverToBoxAdapter(child: _buildTabBar()),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: TabBarView(
                  controller: _tabController!,
                  children: isEnrolled
                      ? [
                          CourseCurriculumTab(
                            modules: state.modules,
                            courseId: state.course.id,
                            userId: widget.userId,
                          ),
                        ]
                      : [
                          CourseCurriculumTab(
                            modules: state.modules,
                            courseId: state.course.id,
                            userId: widget.userId,
                            isTeacher: true,
                          ),
                          CourseStudentsTab(courseId: state.course.id),
                          CourseAssignmentsTab(courseId: state.course.id),
                          CourseReviewsTab(state: state),
                        ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        _buildBottomCTA(context, state),
      ],
    );
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: isDark ? Colors.white : Colors.black87,
        unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[500],
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        isScrollable: !_isEnrolled,
        labelPadding: const EdgeInsets.symmetric(horizontal: 20),
        tabs: _isEnrolled
            ? const [
                Tab(text: 'Nội dung'),
              ]
            : const [
                Tab(text: 'Nội dung'),
                Tab(text: 'Sinh viên'),
                Tab(text: 'Bài tập'),
                Tab(text: 'Đánh giá'),
              ],
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context, CourseDetailLoaded state) {
    final isEnrolled = state.enrollment != null;

    LessonEntity? nextLesson;
    int completedCount = 0;
    int totalLessons = 0;

    for (final module in state.modules) {
      if (module.lessons != null) {
        for (final lesson in module.lessons!) {
          totalLessons++;
          if (lesson.isCompleted) {
            completedCount++;
          } else if (nextLesson == null) {
            nextLesson = lesson;
          }
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = totalLessons > 0 ? completedCount / totalLessons : 0.0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: isEnrolled
              ? _buildEnrolledCTA(
                  context,
                  state,
                  nextLesson,
                  completedCount,
                  totalLessons,
                  progress,
                  isDark,
                )
              : _buildNonEnrolledCTA(context, state),
        ),
      ),
    ).animate().slideY(begin: 1, delay: 300.ms);
  }

  Widget _buildEnrolledCTA(
    BuildContext context,
    CourseDetailLoaded state,
    LessonEntity? nextLesson,
    int completedCount,
    int totalLessons,
    double progress,
    bool isDark,
  ) {
    final isCompleted = completedCount == totalLessons && totalLessons > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (totalLessons > 0) ...[
          Row(
            children: [
              Text(
                'Tiến độ khóa học',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              color: isCompleted ? AppColors.success : AppColors.primary,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (nextLesson != null) {
                final allLessons = <LessonEntity>[];
                for (final m in state.modules) {
                  if (m.lessons != null) allLessons.addAll(m.lessons!);
                }
                final idx = allLessons.indexWhere((l) => l.id == nextLesson.id);
                context
                    .push(
                      AppRoutes.lessonPlayer,
                      extra: {
                        'lesson': nextLesson,
                        'userId': widget.userId,
                        'previousLesson': idx > 0 ? allLessons[idx - 1] : null,
                        'nextLesson': idx < allLessons.length - 1
                            ? allLessons[idx + 1]
                            : null,
                        'allModules': state.modules,
                      },
                    )
                    .then((_) {
                      if (mounted) {
                        context.read<CourseDetailBloc>().add(
                          LoadCourseDetailEvent(
                            state.course.id,
                            userId: widget.userId,
                          ),
                        );
                      }
                    });
              } else {
                context.push(AppRoutes.myCourses);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted
                  ? AppColors.success
                  : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isCompleted
                      ? 'Đã hoàn thành'
                      : (completedCount == 0 ? 'Bắt đầu học' : 'Tiếp tục học'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_rounded,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNonEnrolledCTA(BuildContext context, CourseDetailLoaded state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<CourseDetailBloc>().add(
            EnrollInCourseEvent(
              userId: widget.userId ?? 0,
              courseId: state.course.id,
            ),
          );
        },
        icon: const Icon(Icons.school_rounded, size: 20),
        label: const Text(
          'Đăng ký môn học',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
