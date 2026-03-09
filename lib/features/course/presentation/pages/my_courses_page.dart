import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../domain/entities/course_class_entity.dart';
import '../bloc/my_courses_bloc.dart';
import '../bloc/my_courses_event.dart';
import '../bloc/my_courses_state.dart';
import '../widgets/semester_selector_widget.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class MyCoursesPage extends StatelessWidget {
  final int userId;

  const MyCoursesPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<MyCoursesBloc>()..add(LoadMyAcademicCoursesEvent(userId: userId)),
      child: MyCoursesView(userId: userId),
    );
  }
}

class MyCoursesView extends StatefulWidget {
  final int userId;

  const MyCoursesView({super.key, required this.userId});

  @override
  State<MyCoursesView> createState() => _MyCoursesViewState();
}

class _MyCoursesViewState extends State<MyCoursesView> {
  int? _selectedSemesterId;
  List<Map<String, dynamic>> _todaySchedule = [];
  bool _scheduleLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodaySchedule();
  }

  void _loadCourses() {
    context.read<MyCoursesBloc>().add(
      LoadMyAcademicCoursesEvent(
        userId: widget.userId,
        semesterId: _selectedSemesterId,
      ),
    );
  }

  Future<void> _loadTodaySchedule() async {
    try {
      final api = sl<ApiClient>();
      final res = await api.get('/student/schedule?userId=${widget.userId}');
      final list = List<Map<String, dynamic>>.from(res is List ? res : []);
      final now = DateTime.now();
      final today = list.where((s) {
        final day = s['dayOfWeek'] as int? ?? 0;
        return day == now.weekday;
      }).toList();
      if (mounted)
        setState(() {
          _todaySchedule = today;
          _scheduleLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _scheduleLoading = false);
    }
  }

  String get _userName {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess && authState.user?.fullName != null) {
      return authState.user!.fullName!;
    }
    return 'Bạn';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            _loadCourses();
            await _loadTodaySchedule();
          },
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildGreetingHeader(isDark, textColor, subColor),
              ),

              SliverToBoxAdapter(child: _buildSearchBar(isDark, cardColor)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: SemesterSelectorWidget(
                    selectedSemesterId: _selectedSemesterId,
                    onSemesterChanged: (id) {
                      setState(() => _selectedSemesterId = id);
                      _loadCourses();
                    },
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: BlocBuilder<MyCoursesBloc, MyCoursesState>(
                  builder: (context, state) {
                    if (state is MyCoursesLoading ||
                        state is MyCoursesInitial) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    } else if (state is MyCoursesError) {
                      return _buildErrorState(state.message);
                    } else if (state is MyAcademicCoursesLoaded) {
                      final inProgress = state.courseClasses
                          .where((e) => !e.isCompleted && e.isEnrolled)
                          .toList();
                      final completed = state.courseClasses
                          .where((e) => e.isCompleted)
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (inProgress.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Môn học đang học',
                              '${inProgress.length} môn',
                              textColor,
                              subColor,
                            ),
                            _buildHorizontalCourseCards(
                              inProgress,
                              isDark,
                              cardColor,
                            ),
                          ],

                          if (completed.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Đã hoàn thành',
                              '${completed.length} môn',
                              textColor,
                              subColor,
                            ),
                            _buildHorizontalCourseCards(
                              completed,
                              isDark,
                              cardColor,
                            ),
                          ],

                          if (inProgress.isEmpty && completed.isEmpty)
                            _buildEmptyState(),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: _buildTodaySchedule(
                  isDark,
                  cardColor,
                  textColor,
                  subColor,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(bool isDark, Color textColor, Color subColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng trở lại,',
                  style: TextStyle(fontSize: 13, color: subColor),
                ),
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard
                  : AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: AppColors.primary,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildSearchBar(bool isDark, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {},
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Text(
                'Tìm kiếm khóa học, tài liệu...',
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildSectionHeader(
    String title,
    String trailing,
    Color textColor,
    Color subColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 13,
              color: subColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCourseCards(
    List<CourseClassEntity> courses,
    bool isDark,
    Color cardColor,
  ) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return _buildDashboardCourseCard(course, isDark, cardColor)
              .animate()
              .fadeIn(delay: Duration(milliseconds: 80 * index))
              .slideX(begin: 0.15);
        },
      ),
    );
  }

  Widget _buildDashboardCourseCard(
    CourseClassEntity course,
    bool isDark,
    Color cardColor,
  ) {
    final progress = course.progressPercent / 100;
    final isCompleted = course.isCompleted;

    final hue = (course.courseName.hashCode % 360).abs().toDouble();
    final gradientColors = [
      HSLColor.fromAHSL(1, hue, 0.5, isDark ? 0.3 : 0.45).toColor(),
      HSLColor.fromAHSL(
        1,
        (hue + 30) % 360,
        0.6,
        isDark ? 0.2 : 0.35,
      ).toColor(),
    ];

    return GestureDetector(
      onTap: () => context.push('/courses/${course.courseId}'),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 12,
                    bottom: 10,
                    child: Icon(
                      Icons.code_rounded,
                      size: 36,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.classCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.courseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'GV: ${course.teacherName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Tiến độ',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isCompleted
                            ? '✓ Hoàn thành'
                            : '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearPercentIndicator(
                    padding: EdgeInsets.zero,
                    lineHeight: 6,
                    percent: progress.clamp(0.0, 1.0),
                    barRadius: const Radius.circular(4),
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    progressColor: isCompleted
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySchedule(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subColor,
  ) {
    final now = DateTime.now();
    final dayNames = [
      '',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'CN',
    ];
    final dayStr = dayNames[now.weekday];
    final dateStr = '$dayStr, ${now.day} Tháng ${now.month}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lịch học hôm nay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: subColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_scheduleLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_todaySchedule.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 40,
                    color: AppColors.success.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Không có lịch học hôm nay',
                    style: TextStyle(
                      color: subColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_todaySchedule.length, (i) {
              final s = _todaySchedule[i];
              final startTime = s['startTime'] ?? '';
              final endTime = s['endTime'] ?? '';
              final subject = s['subject'] ?? s['courseName'] ?? '';
              final room = s['room'] ?? '';
              final classCode = s['classCode'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            startTime,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          Text(
                            endTime.isNotEmpty ? endTime : '',
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              width: 2,
                            ),
                          ),
                        ),
                        if (i < _todaySchedule.length - 1)
                          Container(
                            width: 2,
                            height: 50,
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.1 : 0.05,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (room.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    room,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subColor,
                                    ),
                                  ),
                                ],
                              ),
                            if (classCode.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                classCode,
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * i));
            }),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 52,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có lớp học phần nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy khám phá và đăng ký môn học mới',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
