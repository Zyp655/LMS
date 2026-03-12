import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';

class LessonStudentAccessPage extends StatefulWidget {
  final int classId;
  final int lessonId;
  final String lessonTitle;

  const LessonStudentAccessPage({
    super.key,
    required this.classId,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<LessonStudentAccessPage> createState() =>
      _LessonStudentAccessPageState();
}

enum _FilterMode { all, viewed, late, absent }

class _LessonStudentAccessPageState extends State<LessonStudentAccessPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _students = [];
  int _viewed = 0;
  int _late = 0;
  int _absent = 0;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _FilterMode _filter = _FilterMode.all;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = sl<ApiClient>();
      final res = await api.get(
        '/teacher/class-students?classId=${widget.classId}&lessonId=${widget.lessonId}',
      );
      if (mounted) {
        setState(() {
          _students =
              List<Map<String, dynamic>>.from(res['students'] ?? []);
          _viewed = res['viewed'] as int? ?? 0;
          _late = res['late'] as int? ?? 0;
          _absent = res['absent'] as int? ?? 0;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Lỗi tải dữ liệu: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    return _students.where((s) {
      if (_searchQuery.isNotEmpty) {
        final name = (s['fullName'] ?? '').toString().toLowerCase();
        final sid = (s['studentId'] ?? '').toString().toLowerCase();
        final email = (s['email'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery) &&
            !sid.contains(_searchQuery) &&
            !email.contains(_searchQuery)) {
          return false;
        }
      }
      if (_filter != _FilterMode.all) {
        final status = s['status'] ?? '';
        switch (_filter) {
          case _FilterMode.viewed:
            return status == 'viewed';
          case _FilterMode.late:
            return status == 'late';
          case _FilterMode.absent:
            return status == 'absent';
          default:
            break;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final filtered = _filteredStudents;
    final total = _students.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _buildSummaryChip(
                'ðŸŸ¢ $_viewed',
                'Đã xem',
                AppColors.success,
                _filter == _FilterMode.viewed,
                () => setState(() => _filter = _filter == _FilterMode.viewed
                    ? _FilterMode.all
                    : _FilterMode.viewed),
              ),
              const SizedBox(width: 8),
              _buildSummaryChip(
                'ðŸŸ¡ $_late',
                'Muộn',
                AppColors.warning,
                _filter == _FilterMode.late,
                () => setState(() => _filter = _filter == _FilterMode.late
                    ? _FilterMode.all
                    : _FilterMode.late),
              ),
              const SizedBox(width: 8),
              _buildSummaryChip(
                'ðŸ”´ $_absent',
                'Vắng',
                AppColors.error,
                _filter == _FilterMode.absent,
                () => setState(() => _filter = _filter == _FilterMode.absent
                    ? _FilterMode.all
                    : _FilterMode.absent),
              ),
              const Spacer(),
              Text(
                '$total SV',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, MSSV...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.search,
                  color: AppColors.textSecondary(context)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => _searchCtrl.clear(),
                    )
                  : null,
              filled: true,
              fillColor:
                  isDark ? AppColors.darkSurface : Colors.grey.shade100,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        if (_searchQuery.isNotEmpty || _filter != _FilterMode.all)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hiển thị ${filtered.length}/$total',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 12,
                ),
              ),
            ),
          ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_off_outlined,
                          size: 48,
                          color: AppColors.textSecondary(context)),
                      const SizedBox(height: 12),
                      Text(
                        'Không có sinh viên phù hợp',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildStudentCard(filtered[index], isDark),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryChip(
    String count,
    String label,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Text(
          count,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, bool isDark) {
    final name = student['fullName'] ?? '';
    final studentId = student['studentId'] ?? '';
    final status = student['status'] ?? 'absent';
    final lastAccess = student['lastAccessAt'];
    final isCompleted = student['isCompleted'] as bool? ?? false;
    final watchedPos = student['lastWatchedPosition'] as int? ?? 0;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'viewed':
        statusColor = AppColors.success;
        statusLabel = isCompleted ? 'Hoàn thành' : 'Đã xem';
        statusIcon = isCompleted ? Icons.check_circle : Icons.visibility;
        break;
      case 'late':
        statusColor = AppColors.warning;
        statusLabel = 'Muộn';
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = AppColors.error;
        statusLabel = 'Vắng';
        statusIcon = Icons.cancel_outlined;
    }

    String timeLabel = '';
    if (lastAccess != null) {
      try {
        final dt = DateTime.parse(lastAccess);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeLabel = '${diff.inMinutes}p trước';
        } else if (diff.inHours < 24) {
          timeLabel = '${diff.inHours}h trước';
        } else {
          timeLabel = DateFormat('dd/MM HH:mm').format(dt);
        }
      } catch (e) { debugPrint('[_formatTime] $e'); }
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    studentId.isNotEmpty ? studentId : 'Chưa có MSSV',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  if (timeLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '⏰ $timeLabel${watchedPos > 0 ? " • ${_formatPosition(watchedPos)}" : ""}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPosition(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m${s.toString().padLeft(2, '0')}s';
  }
}
