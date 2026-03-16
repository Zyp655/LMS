import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../bloc/admin_bloc.dart';
import 'class_tile.dart';

class CourseClassCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isExpanded;
  final VoidCallback onToggle;

  const CourseClassCard({
    super.key,
    required this.course,
    required this.isExpanded,
    required this.onToggle,
  });

  static ({IconData icon, Color color}) _getSubjectIcon(
    String name,
    String code,
  ) {
    final lower = name.toLowerCase();
    final codeLower = code.toLowerCase();
    if (lower.contains('lập trình') ||
        lower.contains('programming') ||
        codeLower.contains('web')) {
      return (icon: Icons.code_rounded, color: const Color(0xFF0984E3));
    }
    if (lower.contains('dữ liệu') ||
        lower.contains('database') ||
        lower.contains('csdl')) {
      return (icon: Icons.storage_rounded, color: const Color(0xFF6C5CE7));
    }
    if (lower.contains('trí tuệ') ||
        lower.contains('ai') ||
        lower.contains('machine')) {
      return (icon: Icons.psychology_rounded, color: const Color(0xFFE17055));
    }
    if (lower.contains('mạng') || lower.contains('network')) {
      return (icon: Icons.lan_rounded, color: const Color(0xFF00B894));
    }
    if (lower.contains('cấu trúc') ||
        lower.contains('giải thuật') ||
        lower.contains('algorithm')) {
      return (icon: Icons.account_tree_rounded, color: const Color(0xFFFDAA5E));
    }
    if (lower.contains('toán') || lower.contains('math')) {
      return (icon: Icons.functions_rounded, color: const Color(0xFF636E72));
    }
    if (lower.contains('kinh tế') ||
        lower.contains('quản trị') ||
        lower.contains('kinh doanh')) {
      return (icon: Icons.trending_up_rounded, color: const Color(0xFF00CEC9));
    }
    return (icon: Icons.menu_book_rounded, color: const Color(0xFF0984E3));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = course['name'] as String? ?? '';
    final code = course['code'] as String? ?? '';
    final credits = course['credits'] as int? ?? 0;
    final deptName = course['departmentName'] as String? ?? '';
    final classes = List<Map<String, dynamic>>.from(
      course['assignedTeachers'] ?? [],
    );
    final subjectStyle = _getSubjectIcon(name, code);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? cs.outlineVariant.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: subjectStyle.color.withValues(
                        alpha: isDark ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      subjectStyle.icon,
                      color: subjectStyle.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _badge(
                              code,
                              AppColors.info,
                              AppColors.info.withValues(alpha: 0.12),
                            ),
                            const SizedBox(width: 6),
                            _badge(
                              '$credits TC',
                              AppColors.success,
                              AppColors.success.withValues(alpha: 0.12),
                            ),
                            const SizedBox(width: 6),
                            _badge(
                              '${classes.length} lớp',
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ],
                        ),
                        if (deptName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            deptName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Danh sách lớp',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showCreateClassDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm lớp'),
                  ),
                ],
              ),
            ),
            if (classes.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Chưa có lớp nào. Bấm "Thêm lớp" để tạo.'),
                    ],
                  ),
                ),
              )
            else
              ...classes.map(
                (cc) => ClassTile(
                  classData: cc,
                  courseId: course['id'] as int,
                  courseName: name,
                ),
              ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  void _showCreateClassDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    final courseId = course['id'] as int;
    final courseCode = course['code'] as String? ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<AdminBloc>(),
          child: _CreateClassDialogContent(
            courseId: courseId,
            courseCode: courseCode,
            codeCtrl: codeCtrl,
          ),
        );
      },
    );
  }
}

class _CreateClassDialogContent extends StatefulWidget {
  final int courseId;
  final String courseCode;
  final TextEditingController codeCtrl;

  const _CreateClassDialogContent({
    required this.courseId,
    required this.courseCode,
    required this.codeCtrl,
  });

  @override
  State<_CreateClassDialogContent> createState() =>
      _CreateClassDialogContentState();
}

class _CreateClassDialogContentState extends State<_CreateClassDialogContent> {
  List<Map<String, dynamic>> _previewStudents = [];
  int _previewCount = 0;
  bool _isLoadingPreview = false;
  bool _isCreating = false;
  bool _showStudentList = false;
  Timer? _debounce;
  DateTime? _selectedDate;
  String? _errorMessage;
  bool _hasCodeError = false;
  bool _isDuplicate = false;

  @override
  void initState() {
    super.initState();
    widget.codeCtrl.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.codeCtrl.removeListener(_onCodeChanged);
    super.dispose();
  }

  void _onCodeChanged() {
    _debounce?.cancel();
    final code = widget.codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() {
        _previewStudents = [];
        _previewCount = 0;
        _isLoadingPreview = false;
      });
      return;
    }
    setState(() => _isLoadingPreview = true);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchPreview(code);
      _checkDuplicate(code);
    });
  }

  Future<void> _checkDuplicate(String classCode) async {
    try {
      final api = sl<ApiClient>();
      final res = await api.get(
        '/admin/check-class-code?classCode=${Uri.encodeComponent(classCode)}&academicCourseId=${widget.courseId}',
      );
      if (!mounted) return;
      final exists = (res as Map<String, dynamic>)['exists'] as bool? ?? false;
      setState(() {
        _isDuplicate = exists;
        _hasCodeError = exists;
        if (exists) {
          _errorMessage = 'Mã lớp "$classCode" đã tồn tại cho môn học này.';
        } else if (_errorMessage != null &&
            _errorMessage!.contains('đã tồn tại')) {
          _errorMessage = null;
        }
      });
    } catch (_) {}
  }

  Future<void> _fetchPreview(String classCode) async {
    try {
      final api = sl<ApiClient>();
      final res = await api.get(
        '/admin/preview-students?classCode=${Uri.encodeComponent(classCode)}',
      );
      if (!mounted) return;
      final data = res as Map<String, dynamic>;
      setState(() {
        _previewCount = data['count'] as int? ?? 0;
        _previewStudents = List<Map<String, dynamic>>.from(
          data['students'] ?? [],
        );
        _isLoadingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewCount = 0;
        _previewStudents = [];
        _isLoadingPreview = false;
      });
    }
  }

  void _createClass() {
    if (widget.codeCtrl.text.trim().isEmpty) return;
    int? dayOfWeek;
    String? startDate;
    if (_selectedDate != null) {
      final d = _selectedDate!;
      dayOfWeek = d.weekday == 7 ? 8 : d.weekday + 1;
      startDate = d.toIso8601String();
    }
    setState(() => _isCreating = true);
    context.read<AdminBloc>().add(
      CreateCourseClassEvent(
        academicCourseId: widget.courseId,
        classCode: widget.codeCtrl.text.trim(),
        dayOfWeek: dayOfWeek,
        startDate: startDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminActionSuccess) {
          Navigator.pop(context);
        } else if (state is AdminError) {
          setState(() {
            _isCreating = false;
            _errorMessage = state.message;
            if (state.message.contains('đã tồn tại') ||
                state.message.contains('trùng') ||
                state.message.contains('Mã lớp')) {
              _hasCodeError = true;
            }
          });
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Thêm lớp - ${widget.courseCode}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: widget.codeCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên lớp *',
                  hintText: 'VD: CNTT 01',
                  prefixIcon: const Icon(Icons.class_rounded, size: 20),
                  errorText: _hasCodeError ? _errorMessage : null,
                  errorMaxLines: 2,
                  enabledBorder: _hasCodeError
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        )
                      : null,
                  focusedBorder: _hasCodeError
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.error,
                            width: 2,
                          ),
                        )
                      : null,
                  suffixIcon: _isDuplicate
                      ? Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                          size: 20,
                        )
                      : null,
                ),
                onChanged: (_) {
                  if (_hasCodeError) {
                    setState(() {
                      _hasCodeError = false;
                      _errorMessage = null;
                      _isDuplicate = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ngày học',
                    prefixIcon: const Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _selectedDate != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setState(() => _selectedDate = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                        : 'Chọn ngày',
                    style: TextStyle(
                      color: _selectedDate != null ? null : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null && !_hasCodeError)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildPreviewSection(theme),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: (_isCreating || _isDuplicate) ? null : _createClass,
            icon: _isCreating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add, size: 18),
            label: Text(_isCreating ? 'Đang tạo...' : 'Tạo lớp'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(ThemeData theme) {
    final code = widget.codeCtrl.text.trim();
    if (code.isEmpty) return const SizedBox.shrink();

    if (_isLoadingPreview) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Đang tìm sinh viên...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      );
    }

    final hasStudents = _previewCount > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasStudents
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasStudents
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: hasStudents
                ? () => setState(() => _showStudentList = !_showStudentList)
                : null,
            child: Row(
              children: [
                Icon(
                  hasStudents ? Icons.people_rounded : Icons.person_off_rounded,
                  size: 20,
                  color: hasStudents ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasStudents
                        ? '$_previewCount sinh viên sẽ được tự động ghi danh'
                        : 'Không tìm thấy sinh viên phù hợp',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasStudents
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
                if (hasStudents)
                  Icon(
                    _showStudentList ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.success,
                  ),
              ],
            ),
          ),
          if (_showStudentList && _previewStudents.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...(_previewStudents
                .take(10)
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: Text(
                            (s['fullName'] as String? ?? '?')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['fullName'] as String? ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${s['studentId'] ?? ''} • ${s['email'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            if (_previewStudents.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... và ${_previewStudents.length - 10} sinh viên khác',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
