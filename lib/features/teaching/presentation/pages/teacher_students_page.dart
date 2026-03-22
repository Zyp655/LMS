import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/api/api_client.dart';
import '../../../../injection_container.dart';

import '../widgets/custom_search_bar.dart';
import '../widgets/filter_chip_group.dart';
import '../widgets/notification_dialog_widget.dart';

import 'teacher_students/widgets/student_progress_card.dart';
import 'teacher_students/widgets/student_detail_sheet.dart';
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

class _TeacherStudentsPageState extends State<TeacherStudentsPage> {
  List<dynamic> _courses = [];
  List<dynamic> _students = [];
  Map<String, dynamic>? _stats;

  int? _selectedCourseId;
  String? _selectedStatus;
  String? _selectedProgress;
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  String _searchQuery = '';
  int _riskThreshold = 3;
  int? _selectedWarningLevel;
  int? _minRiskScore;

  bool _isLoading = true;
  bool _isMultiSelectMode = false;
  Set<int> _selectedStudentIds = {};
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.initialCourseId;
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final api = sl<ApiClient>();
      final data = await api.get(
        '/teacher/my-classes?teacherId=${widget.teacherId}',
      );
      final courses = List<Map<String, dynamic>>.from(data is List ? data : []);
      if (mounted) {
        setState(() {
          _courses = courses;
          if (_selectedCourseId != null) {
            _loadStudents();
          } else if (_courses.isNotEmpty) {
            _selectedCourseId = _courses.first['academicCourseId'] as int?;
            _loadStudents();
          } else {
            _isLoading = false;
          }
        });
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
      if (_selectedWarningLevel != null)
        queryParams['warningLevel'] = _selectedWarningLevel.toString();
      if (_minRiskScore != null)
        queryParams['minRiskScore'] = _minRiskScore.toString();

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final path = '/courses/$_selectedCourseId/students'
          '${queryString.isNotEmpty ? '?$queryString' : ''}';

      final api = sl<ApiClient>();
      final data = await api.get(path);
      if (mounted) {
        setState(() {
          _students = data['students'] ?? [];
          _stats = data['stats'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          body: Column(
            children: [
              _buildFilters(isDark),
              Expanded(child: _buildStudentList(isDark)),
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
      backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFF00B894),
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
    );
  }

  void _showConfigDialog() {
    final isDark = AppColors.isDark(context);
    int tempThreshold = _riskThreshold;
    int tempMinRisk = _minRiskScore ?? 0;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
              const Text('Cấu hình'),
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
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: tempThreshold,
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
                onChanged: (v) {
                  if (v != null) setDialogState(() => tempThreshold = v);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Ngưỡng điểm rủi ro tối thiểu:',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: tempMinRisk.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: AppColors.error,
                      label: tempMinRisk == 0 ? 'Tắt' : '≥ $tempMinRisk',
                      onChanged: (v) {
                        setDialogState(() => tempMinRisk = v.round());
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      tempMinRisk == 0 ? 'Tắt' : '$tempMinRisk',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Hủy',
                  style: TextStyle(color: AppColors.textSecondary(context))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                setState(() {
                  _riskThreshold = tempThreshold;
                  _minRiskScore = tempMinRisk > 0 ? tempMinRisk : null;
                });
                Navigator.pop(ctx);
                _loadStudents();
              },
              child:
                  const Text('Áp dụng', style: TextStyle(color: Colors.white)),
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
                      labelText: 'Môn học',
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
                        value: course['academicCourseId'] as int,
                        child: Text(
                          course['courseName'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCourseId = value);
                      _loadStudents();
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
                        value: 'riskScore',
                        child: Text('Rủi ro', overflow: TextOverflow.ellipsis),
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
              'MỨC CẢNH BÁO',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          FilterChipGroup<int?>(
            options: [
              FilterOption(label: 'Tất cả', value: null),
              FilterOption(label: 'Mức 1', value: 1),
              FilterOption(label: 'Mức 2', value: 2),
              FilterOption(label: 'Mức 3', value: 3),
            ],
            selectedValue: _selectedWarningLevel,
            onSelected: (value) {
              setState(() => _selectedWarningLevel = value);
              _loadStudents();
            },
            selectedColor: AppColors.error,
          ),
          if (_minRiskScore != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text(
                    'Điểm rủi ro ≥ $_minRiskScore',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => _minRiskScore = null);
                      _loadStudents();
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
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
        'Bạn chưa có môn học nào',
        'Liên hệ quản trị viên để được gán môn học',
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
          onViewHistory: () => _showActivityHistory(student),
        ),
      ),
    );
  }

  void _showActivityHistory(dynamic student) async {
    final userId = student['userId'] as int;
    final name = student['fullName'] ?? 'Sinh viên';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActivityHistorySheet(
        courseId: _selectedCourseId!,
        userId: userId,
        studentName: name,
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
      final api = sl<ApiClient>();
      final data = await api.post(
        '/courses/$_selectedCourseId/students/nudge',
        {'userId': userId},
      );

      if (mounted) Navigator.pop(context);

      if (data != null) {
        final aiMessage = data['message'] as String;

        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => NotificationDialogWidget(
              studentNames: [name],
              initialMessage: aiMessage,
              isAiGenerated: true,
              onSend: (title, message) async {
                await sl<ApiClient>().put(
                  '/courses/$_selectedCourseId/students/nudge',
                  {'userId': userId},
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

  Future<void> _performExcelExport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đang tạo file Excel...'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );

      final excel = xl.Excel.createExcel();
      final sheet = excel['Danh sách SV'];
      excel.delete('Sheet1');

      final headers = [
        'STT', 'Họ tên', 'Email', 'Tiến độ (%)',
        'Điểm Quiz TB', 'Điểm rủi ro', 'Mức cảnh báo',
        'Tỷ lệ vắng (%)', 'Số buổi vắng', 'Tỷ lệ trễ BT (%)',
        'Số BT trễ/chưa nộp', 'Tổng BT', 'Bài đã học',
        'Tổng bài', 'Trạng thái',
      ];

      final headerStyle = xl.CellStyle(
        bold: true,
        backgroundColorHex: xl.ExcelColor.fromHexString('#2D3436'),
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: xl.HorizontalAlign.Center,
      );

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = xl.TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      for (var i = 0; i < _students.length; i++) {
        final s = _students[i];
        final wl = s['warningLevel'] ?? 1;
        final warningText = wl == 3 ? 'Mức 3 (Cao)' : wl == 2 ? 'Mức 2 (TB)' : 'Mức 1 (Thấp)';
        final statusText = s['status'] == 'completed'
            ? 'Hoàn thành'
            : s['status'] == 'in_progress'
                ? 'Đang học'
                : 'Chưa học';

        final row = [
          xl.IntCellValue(i + 1),
          xl.TextCellValue(s['fullName'] ?? ''),
          xl.TextCellValue(s['email'] ?? ''),
          xl.IntCellValue(s['progressPercent'] ?? 0),
          s['quizAverage'] != null
              ? xl.DoubleCellValue((s['quizAverage'] as num).toDouble())
              : xl.TextCellValue('--') as xl.CellValue,
          xl.DoubleCellValue((s['riskScore'] as num?)?.toDouble() ?? 0),
          xl.TextCellValue(warningText),
          xl.DoubleCellValue((s['absenceRate'] as num?)?.toDouble() ?? 0),
          xl.IntCellValue(s['absenceCount'] ?? 0),
          xl.DoubleCellValue((s['lateRate'] as num?)?.toDouble() ?? 0),
          xl.IntCellValue(s['lateCount'] ?? 0),
          xl.IntCellValue(s['totalAssignments'] ?? 0),
          xl.IntCellValue(s['completedLessons'] ?? 0),
          xl.IntCellValue(s['totalLessons'] ?? 0),
          xl.TextCellValue(statusText),
        ];

        for (var j = 0; j < row.length; j++) {
          final cell = sheet.cell(
            xl.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
          );
          cell.value = row[j];

          if (wl == 3) {
            cell.cellStyle = xl.CellStyle(
              backgroundColorHex: xl.ExcelColor.fromHexString('#FFEAEA'),
            );
          } else if (wl == 2) {
            cell.cellStyle = xl.CellStyle(
              backgroundColorHex: xl.ExcelColor.fromHexString('#FFF3E0'),
            );
          }
        }
      }

      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, i <= 2 ? 20 : 14);
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filePath = '${dir.path}/SV_rui_ro_$timestamp.xlsx';
      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Không thể tạo file');

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: 'Danh sách sinh viên rủi ro',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Xuất Excel thành công!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất Excel: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
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
                const SizedBox(height: 4),
                Text(
                  '${_students.length} sinh viên',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 13,
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
                    _performExcelExport();
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

class _ActivityHistorySheet extends StatefulWidget {
  final int courseId;
  final int userId;
  final String studentName;

  const _ActivityHistorySheet({
    required this.courseId,
    required this.userId,
    required this.studentName,
  });

  @override
  State<_ActivityHistorySheet> createState() => _ActivityHistorySheetState();
}

class _ActivityHistorySheetState extends State<_ActivityHistorySheet> {
  bool _loading = true;
  List<dynamic> _lessonProgress = [];
  List<dynamic> _activityLog = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final api = sl<ApiClient>();
      final data = await api.get(
        '/courses/${widget.courseId}/students/${widget.userId}/activity',
      );
      if (mounted) {
        setState(() {
          _lessonProgress = data['lessonProgress'] ?? [];
          _activityLog = data['activityLog'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'lesson_start':
        return '▶️ Bắt đầu bài học';
      case 'lesson_complete':
        return '✅ Hoàn thành bài học';
      case 'video_watch':
        return '🎬 Xem video';
      case 'quiz_attempt':
        return '📝 Làm quiz';
      case 'quiz_complete':
        return '🏆 Hoàn thành quiz';
      case 'assignment_submit':
        return '📎 Nộp bài tập';
      case 'login':
        return '🔐 Đăng nhập';
      default:
        return '📌 $action';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final subtextColor = isDark ? Colors.grey[400]! : AppColors.textSecondaryLight;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lịch sử hoạt động',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.studentName,
                  style: TextStyle(color: subtextColor, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: AppColors.primary,
                          unselectedLabelColor: subtextColor,
                          indicatorColor: AppColors.primary,
                          tabs: [
                            Tab(text: 'Bài học (${_lessonProgress.length})'),
                            Tab(text: 'Hoạt động (${_activityLog.length})'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildLessonTab(isDark, textColor, subtextColor),
                              _buildActivityTab(isDark, textColor, subtextColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTab(bool isDark, Color textColor, Color subtextColor) {
    if (_lessonProgress.isEmpty) {
      return Center(
        child: Text('Chưa có dữ liệu bài học', style: TextStyle(color: subtextColor)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _lessonProgress.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final lp = _lessonProgress[index];
        final isCompleted = lp['isCompleted'] == true;
        final type = lp['lessonType'] ?? 'video';
        final typeIcon = type == 'video' ? Icons.play_circle_outline : Icons.article_outlined;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(typeIcon, color: subtextColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lp['lessonTitle'] ?? 'Bài học',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    if (lp['completedAt'] != null)
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(
                          DateTime.parse(lp['completedAt']),
                        ),
                        style: TextStyle(color: subtextColor, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? AppColors.success : Colors.grey,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityTab(bool isDark, Color textColor, Color subtextColor) {
    if (_activityLog.isEmpty) {
      return Center(
        child: Text('Chưa có hoạt động nào', style: TextStyle(color: subtextColor)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _activityLog.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final log = _activityLog[index];
        final action = log['action'] as String? ?? '';
        final timestamp = log['timestamp'] as String?;
        final formattedTime = timestamp != null
            ? DateFormat('dd/MM HH:mm').format(DateTime.parse(timestamp))
            : '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _actionLabel(action),
                  style: TextStyle(color: textColor, fontSize: 13),
                ),
              ),
              Text(
                formattedTime,
                style: TextStyle(color: subtextColor, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
