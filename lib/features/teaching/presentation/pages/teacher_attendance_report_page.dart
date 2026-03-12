import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';

class TeacherAttendanceReportPage extends StatefulWidget {
  final int classId;
  final String className;

  const TeacherAttendanceReportPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TeacherAttendanceReportPage> createState() =>
      _TeacherAttendanceReportPageState();
}

class _TeacherAttendanceReportPageState
    extends State<TeacherAttendanceReportPage> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final api = sl<ApiClient>();
      final resp = await api.get(
        '/teaching/attendance?classId=${widget.classId}',
      );
      final list = resp['students'] as List<dynamic>? ?? [];
      setState(() {
        _students = list.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _students = [];
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _students;
    return _students
        .where(
          (s) => (s['fullName'] as String? ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  int get _presentCount =>
      _students.where((s) => s['status'] == 'present').length;
  int get _pendingCount =>
      _students.where((s) => s['status'] == 'pending').length;
  int get _absentCount =>
      _students.where((s) => s['status'] == 'absent').length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = AppColors.isDark(context);
    final total = _students.length;
    final attendanceRate = total > 0 ? (_presentCount / total * 100) : 0.0;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: cs.onSurface),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Báo cáo chuyên cần',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.class_, size: 18, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.className,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.expand_more,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              SliverToBoxAdapter(
                child: _buildCircularProgress(attendanceRate, isDark),
              ),
              SliverToBoxAdapter(child: _buildStatsGrid(isDark, total)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Danh sách sinh viên',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sinh viên...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildStudentRow(_filtered[i], isDark),
                  childCount: _filtered.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _loading
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Xuất báo cáo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCircularProgress(double rate, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 10,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${rate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    'Tỷ lệ chuyên cần',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard('Tổng SV', total, Colors.white70, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Có mặt',
                  _presentCount,
                  AppColors.success,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Đang học',
                  _pendingCount,
                  AppColors.warning,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Vắng', _absentCount, AppColors.error, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(Map<String, dynamic> student, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    final name = student['fullName'] as String? ?? 'N/A';
    final status = student['status'] as String? ?? 'not_accessed';
    final watchPct = (student['watchPercentage'] as num?)?.toDouble() ?? 0;
    final quizDone = student['quizCompleted'] as bool? ?? false;
    final absences = student['currentAbsences'] as int? ?? 0;
    final maxAbs = student['maxAbsences'] as int? ?? 6;
    final reason = student['absenceReason'] as String?;

    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .take(2)
        .join();

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'present':
        statusColor = AppColors.success;
        statusLabel = 'Có mặt';
      case 'pending':
        statusColor = AppColors.warning;
        statusLabel = 'Đang học';
      case 'absent':
        statusColor = AppColors.error;
        statusLabel = 'Vắng';
      default:
        statusColor = cs.onSurfaceVariant;
        statusLabel = 'Chưa truy cập';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkCardGradient : null,
          color: isDark ? null : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Watch: ${watchPct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Quiz: ${quizDone ? '✓' : '✗'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: quizDone
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$absences/$maxAbs buổi vắng',
                  style: TextStyle(
                    fontSize: 11,
                    color: absences >= maxAbs - 1
                        ? AppColors.error
                        : cs.onSurfaceVariant,
                    fontWeight: absences >= maxAbs - 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (reason != null && status == 'absent') ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reason,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
