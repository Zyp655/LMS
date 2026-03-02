import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/route/app_route.dart';
import '../bloc/admin_bloc.dart';
import '../tabs/academic_tab.dart';
import '../tabs/course_tab.dart';
import '../tabs/analytics_tab.dart';
import '../tabs/tools_tab.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _semesters = [];
  List<Map<String, dynamic>> _academicCourses = [];
  List<Map<String, dynamic>> _courseClasses = [];

  Map<String, dynamic> _analytics = {};
  bool _isLoadingAnalytics = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAcademicData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 1:
        break;
      case 2:
        if (_analytics.isEmpty && !_isLoadingAnalytics) _loadAnalytics();
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _loadAcademicData() {
    context.read<AdminBloc>().add(LoadAcademicData());
  }

  void _loadAnalytics() {
    setState(() => _isLoadingAnalytics = true);
    context.read<AdminBloc>().add(LoadAnalytics());
  }

  void _seedRoadmap() {
    setState(() => _isLoading = true);
    context.read<AdminBloc>().add(SeedRoadmap());
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('token');
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? cs.onError : cs.onInverseSurface,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isError ? cs.error : null,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AcademicDataLoaded) {
          setState(() {
            _departments = state.departments;
            _semesters = state.semesters;
            _academicCourses = state.academicCourses;
            _courseClasses = state.courseClasses;
          });
        } else if (state is AnalyticsLoaded) {
          setState(() {
            _analytics = state.analytics;
            _isLoadingAnalytics = false;
          });
        } else if (state is AdminActionSuccess) {
          setState(() => _isLoading = false);
          _snack(state.message);
          _loadAcademicData();
        } else if (state is AdminError) {
          setState(() {
            _isLoading = false;
            _isLoadingAnalytics = false;
          });
          _snack(state.message, isError: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Quản Trị Hệ Thống',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Đăng xuất',
              onPressed: _logout,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            isScrollable: false,
            tabs: const [
              Tab(
                icon: Icon(Icons.school_rounded, size: 20),
                text: 'Học thuật',
              ),
              Tab(
                icon: Icon(Icons.menu_book_rounded, size: 20),
                text: 'Môn học',
              ),
              Tab(
                icon: Icon(Icons.analytics_rounded, size: 20),
                text: 'Thống kê',
              ),
              Tab(
                icon: Icon(Icons.build_circle_rounded, size: 20),
                text: 'Công cụ',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            AcademicTab(
              departments: _departments,
              semesters: _semesters,
              academicCourses: _academicCourses,
              courseClasses: _courseClasses,
              onRefresh: () async => _loadAcademicData(),
            ),
            const CourseTab(),
            AnalyticsTab(
              analytics: _analytics,
              isLoading: _isLoadingAnalytics,
              onRefresh: () async => _loadAnalytics(),
            ),
            ToolsTab(isLoading: _isLoading, onSeedRoadmap: _seedRoadmap),
          ],
        ),
      ),
    );
  }
}
