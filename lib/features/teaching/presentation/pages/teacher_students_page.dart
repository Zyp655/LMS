import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../../core/api/api_constants.dart';

import '../widgets/custom_search_bar.dart';
import '../widgets/filter_chip_group.dart';
import '../widgets/notification_dialog_widget.dart';

import 'teacher_students/widgets/student_progress_card.dart';
import 'teacher_students/widgets/student_detail_sheet.dart';
import 'teacher_students/widgets/insights_tab.dart';
import '../../../../core/theme/app_colors.dart';

class TeacherStudentsPage extends StatefulWidget {
  final int teacherId;
  final int? initialCourseId;

  const TeacherStudentsPage({
    super.key,
    required this.teacherId,
    this.initialCourseId,
  });

  @override
  State<TeacherStudentsPage> createState() => _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends State<TeacherStudentsPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _courses = [];
  List<dynamic> _students = [];
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _insightsData;

  int? _selectedCourseId;
  String? _selectedStatus;
  String? _selectedProgress;
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  String _searchQuery = '';
  int _riskThreshold = 3;

  bool _isLoading = true;
  bool _isLoadingInsights = false;
  bool _isMultiSelectMode = false;
  late TabController _tabController;
  Set<int> _selectedStudentIds = {};
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedCourseId = widget.initialCourseId;
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/courses'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final courses = (data['courses'] as List).cast<Map<String, dynamic>>();
        if (mounted) {
          setState(() {
            _courses = courses
                .where((c) => c['instructorId'] == widget.teacherId)
                .toList();
            if (_selectedCourseId != null) {
              _loadStudents();
              _loadInsights();
            } else if (_courses.isNotEmpty) {
              _selectedCourseId = _courses.first['id'];
              _loadStudents();
              _loadInsights();
            } else {
              _isLoading = false;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedCourseId == null) return;
    setState(() => _isLoading = true);

    try {
      final queryParams = <String, String>{};
      if (_selectedStatus != null) queryParams['status'] = _selectedStatus!;
      if (_selectedProgress != null)
        queryParams['progress'] = _selectedProgress!;
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;
      queryParams['sortBy'] = _sortBy;
      queryParams['sortOrder'] = _sortOrder;
      queryParams['threshold'] = _riskThreshold.toString();

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/courses/$_selectedCourseId/students',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _students = data['students'] ?? [];
            _stats = data['stats'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInsights() async {
    if (_selectedCourseId == null) return;
    setState(() => _isLoadingInsights = true);

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/courses/$_selectedCourseId/analytics/insights',
        ),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _insightsData = jsonDecode(response.body);
            _isLoadingInsights = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingInsights = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingInsights = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(
          context,
        ).copyWith(overscroll: false, physics: const ClampingScrollPhysics()),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(isDark, innerBoxIsScrolled),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              Column(
                children: [
                  _buildFilters(isDark),
                  Expanded(child: _buildStudentList(isDark)),
                ],
              ),
              InsightsTab(
                isLoading: _isLoadingInsights,
                insightsData: _insightsData,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isMultiSelectMode && _selectedStudentIds.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                'Gửi thông báo (${_selectedStudentIds.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: _sendBatchNotification,
            )
          : null,
    );
  }

  Widget _buildSliverAppBar(bool isDark, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      surfaceTintColor: Colors.transparent,
      forceElevated: innerBoxIsScrolled,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: false,
      actions: [
        if (_isMultiSelectMode)
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => setState(() {
              _isMultiSelectMode = false;
              _selectedStudentIds.clear();
            }),
          )
        else ...[
          IconButton(
            icon: Icon(Icons.tune_rounded, size: 22, color: Colors.white),
            onPressed: _showConfigDialog,
            tooltip: 'Cấu hình',
          ),
          IconButton(
            icon: Icon(Icons.download_rounded, size: 22, color: Colors.white),
            onPressed: _exportData,
            tooltip: 'Xuất dữ liệu',
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF00B894).withAlpha(40),
                      const Color(0xFF00CEC9).withAlpha(20),
                      AppColors.darkSurface,
                    ]
                  : [
                      const Color(0xFF00B894),
                      const Color(0xFF00CEC9),
                      const Color(0xFF55EFC4),
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 8, 20, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _isMultiSelectMode
                        ? 'Đã chọn: ${_selectedStudentIds.length}'
                        : 'Quản lý Sinh viên',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (!_isMultiSelectMode) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${_students.length} sinh viên đang theo dõi',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : Colors.white.withAlpha(200),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.border(context), width: 0.5),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.primary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelColor: AppColors.textSecondary(context),
            tabs: const [
              Tab(
                text: 'Danh sách',
                icon: Icon(Icons.list_alt_rounded, size: 18),
              ),
              Tab(
                text: 'Insights',
                icon: Icon(Icons.insights_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfigDialog() {
    final isDark = AppColors.isDark(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardColor(context),
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
                Icons.tune_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Cấu hình cảnh báo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ngưỡng cảnh báo vắng mặt:',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _riskThreshold,
              dropdownColor: AppColors.surface(context),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceVariant
                    : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 3, child: Text('> 3 ngày (Mặc định)')),
                DropdownMenuItem(value: 5, child: Text('> 5 ngày')),
                DropdownMenuItem(value: 7, child: Text('> 7 ngày')),
                DropdownMenuItem(value: 14, child: Text('> 14 ngày')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _riskThreshold = value);
                  Navigator.pop(context);
                  _loadStudents();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    final surfaceColor = isDark
        ? AppColors.darkSurfaceVariant
        : Colors.grey.shade50;
    final borderColor = AppColors.border(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Tìm kiếm theo tên, email...',
            fillColor: surfaceColor,
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _loadStudents();
            },
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
              _loadStudents();
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _selectedCourseId,
                    dropdownColor: AppColors.surface(context),
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 13,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary(context),
                      size: 20,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Khóa học',
                      labelStyle: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _courses.map<DropdownMenuItem<int>>((course) {
                      return DropdownMenuItem(
                        value: course['id'] as int,
                        child: Text(
                          course['title'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCourseId = value);
                      _loadStudents();
                      _loadInsights();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    dropdownColor: AppColors.surface(context),
                    isExpanded: true,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 13,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary(context),
                      size: 20,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Sắp xếp',
                      labelStyle: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'name',
                        child: Text('Tên', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'progress',
                        child: Text('Tiến độ', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'quizScore',
                        child: Text('Điểm', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'risk',
                        child: Text('Ưu tiên', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _sortBy = value!);
                      _loadStudents();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(
                      () => _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc',
                    );
                    _loadStudents();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      _sortOrder == 'asc'
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              'TRẠNG THÁI',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          FilterChipGroup<String?>(
            options: [
              FilterOption(label: 'Tất cả', value: null),
              FilterOption(label: 'Cần chú ý', value: 'at_risk'),
              FilterOption(label: 'Chưa học', value: 'not_started'),
              FilterOption(label: 'Đang học', value: 'in_progress'),
              FilterOption(label: 'Hoàn thành', value: 'completed'),
            ],
            selectedValue: _selectedStatus,
            onSelected: (value) {
              setState(() => _selectedStatus = value);
              _loadStudents();
            },
          ),
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              'TIẾN ĐỘ',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          FilterChipGroup<String?>(
            options: [
              FilterOption(label: 'Tất cả', value: null),
              FilterOption(label: '0-30%', value: 'low'),
              FilterOption(label: '31-70%', value: 'medium'),
              FilterOption(label: '71-100%', value: 'high'),
            ],
            selectedValue: _selectedProgress,
            onSelected: (value) {
              setState(() => _selectedProgress = value);
              _loadStudents();
            },
            selectedColor: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(bool isDark) {
    if (_isLoading) {
      return _buildShimmerLoading(isDark);
    }

    if (_courses.isEmpty) {
      return _buildEmptyState(
        Icons.school_outlined,
        'Bạn chưa có khóa học nào',
        'Liên hệ quản trị viên để được gán khóa học',
        isDark,
      );
    }

    if (_students.isEmpty) {
      return _buildEmptyState(
        Icons.people_outline,
        'Chưa có sinh viên nào',
        'Sinh viên sẽ xuất hiện sau khi enrollment',
        isDark,
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: AppColors.primary,
      onRefresh: _loadStudents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          final userId = student['userId'] as int;
          return StudentProgressCard(
            student: student,
            isSelected: _selectedStudentIds.contains(userId),
            isSelectionMode: _isMultiSelectMode,
            onTap: () => _showStudentDetails(student),
            onSelectChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedStudentIds.add(userId);
                } else {
                  _selectedStudentIds.remove(userId);
                  if (_selectedStudentIds.isEmpty) _isMultiSelectMode = false;
                }
              });
            },
            onNudge: () => _showAINudgeDialog(student),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Center(
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
                    const Color(0xFF00B894).withAlpha(15),
                    const Color(0xFF00A383).withAlpha(10),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: const Color(0xFF00B894).withAlpha(180),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 0.7),
          duration: Duration(milliseconds: 800 + (index * 100)),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Opacity(opacity: value, child: _buildShimmerCard(isDark));
          },
          onEnd: () {},
        );
      },
    );
  }

  Widget _buildShimmerCard(bool isDark) {
    final shimmerBase = isDark
        ? Colors.white.withAlpha(10)
        : Colors.grey.shade200;
    final shimmerHighlight = isDark
        ? Colors.white.withAlpha(20)
        : Colors.grey.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: shimmerBase,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 160,
                  decoration: BoxDecoration(
                    color: shimmerHighlight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: shimmerBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 10,
                      width: 50,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 24,
            width: 60,
            decoration: BoxDecoration(
              color: shimmerBase,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(dynamic student) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StudentDetailSheet(
          student: student,
          formatTime: _formatTime,
          onSendNotification: () => _sendNotificationToStudent(student),
          onViewHistory: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Đang tải lịch sử hoạt động...'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAINudgeDialog(dynamic student) async {
    final userId = student['userId'];
    final name = student['fullName'] ?? 'bạn';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardColor(context),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AI đang soạn tin nhắn...',
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConstants.baseUrl}/courses/$_selectedCourseId/students/nudge',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = data['message'] as String;

        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => NotificationDialogWidget(
              studentNames: [name],
              initialMessage: aiMessage,
              isAiGenerated: true,
              onSend: (title, message) async {
                await http.put(
                  Uri.parse(
                    '${ApiConstants.baseUrl}/courses/$_selectedCourseId/students/nudge',
                  ),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'userId': userId}),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã gửi nhắc nhở AI thành công!'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  _loadStudents();
                }
              },
            ),
          );
        }
      } else {
        throw Exception('Failed to generate nudge');
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _sendNotificationToStudent(dynamic student) {
    showDialog(
      context: context,
      builder: (_) => NotificationDialogWidget(
        studentNames: [student['fullName'] ?? 'Unknown'],
        onSend: (title, message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã gửi thông báo cho ${student['fullName']}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
    );
  }

  void _sendBatchNotification() {
    final selectedNames = _students
        .where((s) => _selectedStudentIds.contains(s['userId']))
        .map((s) => s['fullName'] as String? ?? 'Unknown')
        .toList();

    showDialog(
      context: context,
      builder: (_) => NotificationDialogWidget(
        studentNames: selectedNames,
        onSend: (title, message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã gửi thông báo cho ${_selectedStudentIds.length} sinh viên',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          setState(() {
            _isMultiSelectMode = false;
            _selectedStudentIds.clear();
          });
        },
      ),
    );
  }

  void _exportData() {
    final isDark = AppColors.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Xuất dữ liệu sinh viên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _exportOption(
                  icon: Icons.table_chart_rounded,
                  color: const Color(0xFF00B894),
                  title: 'Xuất Excel (.xlsx)',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Đang xuất file Excel...'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _exportOption(
                  icon: Icons.description_rounded,
                  color: AppColors.info,
                  title: 'Xuất CSV (.csv)',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Đang xuất file CSV...'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _exportOption({
    required IconData icon,
    required Color color,
    required String title,
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
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
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

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }
}
