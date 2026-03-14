import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../schedule/presentation/pages/schedule_page.dart';
import '../../../user/presentation/pages/profile_page.dart';
import '../../../course/presentation/pages/course_catalog_page.dart';
import '../../../course/presentation/pages/my_courses_page.dart';
import '../../../course/presentation/bloc/my_courses_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

import '../../../../injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../teaching/presentation/pages/attendance_dashboard_page.dart';

class MainWrapperPage extends StatefulWidget {
  const MainWrapperPage({super.key});

  @override
  State<MainWrapperPage> createState() => _MainWrapperPageState();
}

class _MainWrapperPageState extends State<MainWrapperPage> {
  int _currentIndex = 0;

  int get _userId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) return authState.user?.id ?? 0;
    return 0;
  }

  List<Widget> get _pages => [
    BlocProvider(
      create: (_) => sl<MyCoursesBloc>(),
      child: MyCoursesPage(userId: _userId),
    ),
    BlocProvider(
      create: (_) => sl<MyCoursesBloc>(),
      child: const CourseCatalogPage(),
    ),
    const SchedulePage(),
    const AttendanceDashboardPage(),
    const ProfilePage(),
  ];



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
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
                _buildNavItem(
                  0,
                  Icons.home_outlined,
                  Icons.home_rounded,
                  'Trang chủ',
                ),
                _buildNavItem(
                  1,
                  Icons.menu_book_outlined,
                  Icons.menu_book_rounded,
                  'Khóa học',
                ),
                _buildNavItem(
                  2,
                  Icons.calendar_today_outlined,
                  Icons.calendar_today_rounded,
                  'Lịch học',
                ),
                _buildNavItem(
                  3,
                  Icons.fact_check_outlined,
                  Icons.fact_check_rounded,
                  'Chuyên cần',
                ),
                _buildNavItem(
                  4,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Cá nhân',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? Colors.grey[500]! : Colors.grey[400]!;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
