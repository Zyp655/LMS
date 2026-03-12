import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/route/app_route.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../../../features/user/presentation/pages/profile_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'teacher_subject_list_page.dart';
import 'teacher_students_page.dart';
import 'teacher_course_stats_page.dart';
import 'teacher_tasks_page.dart';
import '../bloc/teacher_bloc.dart';
import '../../../../core/theme/app_colors.dart';

class TeacherDashboardPage extends StatefulWidget {
  final int teacherId;

  const TeacherDashboardPage({super.key, required this.teacherId});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _loading = true;

  int _pendingSubmissions = 0;
  int _academicClassCount = 0;
  int _academicStudentCount = 0;
  List<Map<String, dynamic>> _academicClasses = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadAllData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([_loadPendingSubmissions(), _loadAcademicClasses()]);
    if (mounted) {
      setState(() => _loading = false);
      _animController.forward();
    }
  }

  Future<void> _loadAcademicClasses() async {
    try {
      final api = sl<ApiClient>();
      final res = await api.get(
        '/teacher/my-classes?teacherId=${widget.teacherId}',
      );
      final classes = List<Map<String, dynamic>>.from(res is List ? res : []);
      int students = 0;
      for (final c in classes) {
        students += (c['studentCount'] as int? ?? 0);
      }
      if (mounted) {
        setState(() {
          _academicClasses = classes;
          _academicClassCount = classes.length;
          _academicStudentCount = students;
        });
      }
    } catch (e) {
      debugPrint('[_loadAcademicClasses] $e');
    }
  }

  Future<void> _loadPendingSubmissions() async {
    try {
      final api = sl<ApiClient>();
      final res = await api.get(
        '/teacher/assignments?teacherId=${widget.teacherId}',
      );
      final assignments = List<Map<String, dynamic>>.from(
        res is List ? res : (res['assignments'] ?? []),
      );
      int pending = 0;
      for (final a in assignments) {
        pending += (a['pendingCount'] as int? ?? 0);
      }
      if (mounted) setState(() => _pendingSubmissions = pending);
    } catch (e) {
      debugPrint('[_loadPendingSubmissions] $e');
    }
  }

  String get _teacherName {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess && authState.user?.fullName != null) {
      return authState.user!.fullName!;
    }
    return 'Giảng viên';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      _buildDashboard(),
      const TeacherSubjectListPage(),
      TeacherStudentsPage(teacherId: widget.teacherId),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  Icons.dashboard_outlined,
                  Icons.dashboard_rounded,
                  'Dashboard',
                  0,
                ),
                _navItem(
                  Icons.menu_book_outlined,
                  Icons.menu_book_rounded,
                  'Môn học',
                  1,
                ),
                _navItem(
                  Icons.people_outline_rounded,
                  Icons.people_rounded,
                  'Sinh viên',
                  2,
                ),
                _navItem(
                  Icons.settings_outlined,
                  Icons.settings_rounded,
                  'Cài đặt',
                  3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _selectedIndex == index;
    final color = isActive
        ? AppColors.primary
        : AppColors.textSecondary(context);
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _loading = true);
        _animController.reset();
        await _loadAllData();
      },
      color: Colors.white,
      backgroundColor: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildGradientHeader(isDark),
          SliverToBoxAdapter(child: _buildStatsSection(isDark)),
          if (!_loading && _pendingSubmissions > 0)
            SliverToBoxAdapter(child: _buildPendingAlert(isDark)),
          SliverToBoxAdapter(child: _buildQuickActions(isDark)),
          SliverToBoxAdapter(child: _buildMyCoursesSection(isDark)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(bool isDark) {
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _teacherName.isNotEmpty
                        ? _teacherName[0].toUpperCase()
                        : 'G',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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
                      'Chào buổi sáng,',
                      style: TextStyle(color: subColor, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _teacherName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => context.push(AppRoutes.notifications),
                  icon: Stack(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      if (_pendingSubmissions > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardColor, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isDark) {
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
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
                child: Row(
                  children: [
                    _buildStatItem(
                      Icons.school_rounded,
                      'Môn giảng dạy',
                      '$_academicClassCount',
                      textColor,
                      subColor,
                    ),
                    _buildStatDivider(isDark),
                    _buildStatItem(
                      Icons.people_rounded,
                      'Sinh viên',
                      '$_academicStudentCount',
                      textColor,
                      subColor,
                    ),
                    _buildStatDivider(isDark),
                    _buildStatItem(
                      Icons.class_rounded,
                      'Lớp học',
                      '$_academicClassCount',
                      textColor,
                      subColor,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color subColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: subColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 40,
      color: isDark ? Colors.grey[700] : Colors.grey[200],
    );
  }

  Widget _buildPendingAlert(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.warning.withAlpha(isDark ? 30 : 20),
                AppColors.warning.withAlpha(isDark ? 15 : 8),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.warning.withAlpha(isDark ? 50 : 35),
            ),
          ),
          child: InkWell(
            onTap: () {
              final bloc = context.read<TeacherBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: bloc,
                    child: const TeacherTasksPage(),
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(isDark ? 50 : 30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_late_rounded,
                    color: AppColors.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bài chờ chấm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_pendingSubmissions bài nộp đang chờ chấm điểm',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = AppColors.textPrimary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hành động nhanh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStitchActionItem(
                  icon: Icons.people_rounded,
                  label: 'Quản lý Sinh\nviên',
                  isDark: isDark,
                  cardColor: cardColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TeacherStudentsPage(teacherId: widget.teacherId),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildStitchActionItem(
                  icon: Icons.assignment_rounded,
                  label: 'Bài tập',
                  isDark: isDark,
                  cardColor: cardColor,
                  onTap: () {
                    final bloc = context.read<TeacherBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: bloc,
                          child: const TeacherTasksPage(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildStitchActionItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Thống kê',
                  isDark: isDark,
                  cardColor: cardColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TeacherCourseStatsPage(teacherId: widget.teacherId),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildStitchActionItem(
                  icon: Icons.chat_rounded,
                  label: 'Chat',
                  isDark: isDark,
                  cardColor: cardColor,
                  onTap: () => context.push(AppRoutes.conversations),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchActionItem({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyCoursesSection(bool isDark) {
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Môn học của tôi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              _buildCourseList(cardColor, textColor, subColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(
    Color cardColor,
    Color textColor,
    Color subColor,
    bool isDark,
  ) {
    if (_academicClasses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Chưa có môn nào',
            style: TextStyle(color: subColor, fontSize: 14),
          ),
        ),
      );
    }
    final displayClasses = _academicClasses.take(3).toList();
    return Column(
      children: displayClasses.map((cls) {
        final courseName = cls['courseName'] ?? '';
        final courseCode = cls['courseCode'] ?? '';
        final studentCount = cls['studentCount'] ?? 0;
        final classCode = cls['classCode'] ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$courseName – $courseCode',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 14, color: subColor),
                        const SizedBox(width: 4),
                        Text(
                          '$studentCount',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.class_rounded, size: 14, color: subColor),
                        const SizedBox(width: 4),
                        Text(
                          classCode,
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subColor, size: 22),
            ],
          ),
        );
      }).toList(),
    );
  }
}
