import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'teacher_course_editor_page.dart';
import 'lesson_attendance_list_page.dart';

class TeacherSubjectListPage extends StatefulWidget {
  const TeacherSubjectListPage({super.key});

  @override
  State<TeacherSubjectListPage> createState() => _TeacherSubjectListPageState();
}

enum _SortMode { name, code }

class _TeacherSubjectListPageState extends State<TeacherSubjectListPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _classes = [];

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.name;

  int get _teacherId => sl<SharedPreferences>().getInt('current_user_id') ?? 1;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredClasses {
    var list = _classes.where((cls) {
      if (_searchQuery.isEmpty) return true;
      final name = (cls['courseName'] ?? '').toString().toLowerCase();
      final code = (cls['courseCode'] ?? '').toString().toLowerCase();
      final classCode = (cls['classCode'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) ||
          code.contains(_searchQuery) ||
          classCode.contains(_searchQuery);
    }).toList();

    list.sort((a, b) {
      if (_sortMode == _SortMode.name) {
        return (a['courseName'] ?? '').toString().compareTo(
          (b['courseName'] ?? '').toString(),
        );
      } else {
        return (a['courseCode'] ?? '').toString().compareTo(
          (b['courseCode'] ?? '').toString(),
        );
      }
    });
    return list;
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = sl<ApiClient>();
      final res = await api.get('/teacher/my-classes?teacherId=$_teacherId');
      final list = List<Map<String, dynamic>>.from(res is List ? res : []);
      if (mounted) setState(() => _classes = list);
    } catch (e) {
      if (mounted) setState(() => _error = 'Lỗi tải danh sách: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: RefreshIndicator(
        onRefresh: _loadClasses,
        color: Colors.white,
        backgroundColor: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(isDark),
            if (!_loading && _error == null && _classes.isNotEmpty)
              SliverToBoxAdapter(child: _buildSearchBar(isDark)),
            _buildBody(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withAlpha(isDark ? 40 : 15),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Môn Học Được Phân Công',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_loading && _error == null && _classes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_classes.length} môn',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
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

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(10)
                      : Colors.grey.shade200,
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, mã môn...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary(context),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(10)
                    : Colors.grey.shade200,
              ),
            ),
            child: PopupMenuButton<_SortMode>(
              onSelected: (mode) => setState(() => _sortMode = mode),
              icon: Icon(
                Icons.sort_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              tooltip: 'Sắp xếp',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              itemBuilder: (_) => [
                _sortMenuItem(
                  _SortMode.name,
                  Icons.sort_by_alpha,
                  'Theo tên A-Z',
                ),
                _sortMenuItem(_SortMode.code, Icons.tag, 'Theo mã môn'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_SortMode> _sortMenuItem(
    _SortMode mode,
    IconData icon,
    String label,
  ) {
    final isActive = _sortMode == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isActive ? AppColors.primary : null),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primary : null,
              fontWeight: isActive ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
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
                    Icons.wifi_off_rounded,
                    size: 40,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Không thể tải dữ liệu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _loadClasses,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_classes.isEmpty) {
      return SliverFillRemaining(
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
                    Icons.school_outlined,
                    size: 56,
                    color: AppColors.primary.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Chưa có môn học',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Liên hệ quản trị viên để được gán môn',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _filteredClasses;

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.textSecondary(context),
              ),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy môn học phù hợp',
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (_searchQuery.isNotEmpty && index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Tìm thấy ${filtered.length}/${_classes.length} môn',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ),
                _buildClassCard(filtered[index], isDark),
              ],
            );
          }
          return _buildClassCard(filtered[index], isDark);
        }, childCount: filtered.length),
      ),
    );
  }

  static const _courseColors = [
    [Color(0xFF1ABC9C), Color(0xFF16A085)],
    [Color(0xFF3498DB), Color(0xFF2980B9)],
    [Color(0xFF9B59B6), Color(0xFF8E44AD)],
    [Color(0xFFE67E22), Color(0xFFD35400)],
    [Color(0xFFE74C3C), Color(0xFFC0392B)],
    [Color(0xFF2ECC71), Color(0xFF27AE60)],
  ];

  List<Color> _getGradient(int index) {
    return _courseColors[index % _courseColors.length];
  }

  void _showClassOptions(Map<String, dynamic> cls) {
    final classId = cls['id'] as int?;
    final courseId = cls['academicCourseId'] as int?;
    final classCode = cls['classCode'] ?? '';
    final courseName = cls['courseName'] ?? '';
    if (classId == null) return;

    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(ctx),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              courseName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              classCode,
                              style: TextStyle(
                                color: AppColors.textSecondary(ctx),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _optionTile(
                    icon: Icons.menu_book_rounded,
                    color: AppColors.primary,
                    title: 'Quản lý nội dung',
                    subtitle: 'Video, tài liệu, bài tập',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeacherCourseEditorPage(courseId: courseId!),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _optionTile(
                    icon: Icons.people_rounded,
                    color: const Color(0xFF00B894),
                    title: 'Sinh viên & Tiến độ',
                    subtitle: 'Xem tiến độ học tập SV',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonAttendanceListPage(
                            classId: classId,
                            courseId: courseId ?? 0,
                            className: '$courseName ($classCode)',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _optionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
                color: AppColors.textSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> cls, bool isDark) {
    final courseName = cls['courseName'] ?? '';
    final courseCode = cls['courseCode'] ?? '';
    final classCode = cls['classCode'] ?? '';
    final credits = cls['credits'] ?? 3;
    final semester = cls['semester'] ?? '';
    final studentCount = cls['studentCount'] ?? 0;
    final index = _classes.indexOf(cls);
    final gradient = _getGradient(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withAlpha(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showClassOptions(cls),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withAlpha(isDark ? 30 : 50),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      courseCode.isNotEmpty
                          ? courseCode
                                .substring(
                                  0,
                                  courseCode.length > 2 ? 2 : courseCode.length,
                                )
                                .toUpperCase()
                          : 'MH',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                        courseName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _chip(courseCode, gradient[0], isDark),
                          _chip(classCode, const Color(0xFF6C5CE7), isDark),
                          _chip('$credits TC', const Color(0xFFE67E22), isDark),
                        ],
                      ),
                      if (semester.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: AppColors.textSecondary(context),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                semester,
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                Column(
                  children: [
                    if (studentCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF00B894,
                          ).withAlpha(isDark ? 30 : 15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 14,
                              color: const Color(0xFF00B894),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$studentCount',
                              style: const TextStyle(
                                color: Color(0xFF00B894),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary(context),
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color, bool isDark) {
    if (text.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 30 : 15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
