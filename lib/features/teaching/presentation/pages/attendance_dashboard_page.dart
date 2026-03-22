import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class AttendanceDashboardPage extends StatefulWidget {
  const AttendanceDashboardPage({super.key});

  @override
  State<AttendanceDashboardPage> createState() =>
      _AttendanceDashboardPageState();
}

class _AttendanceDashboardPageState extends State<AttendanceDashboardPage> {
  List<Map<String, dynamic>> _subjects = [];
  bool _loading = true;
  String? _error;

  int _totalAbsences = 0;
  int _totalCredits = 0;
  int _subjectsWithScores = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  int get _userId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) return authState.user?.id ?? 0;
    return 0;
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = sl<ApiClient>();

      final enrollResp = await api.get('/student/my-courses?userId=$_userId&status=enrolled');
      final enrollments = List<Map<String, dynamic>>.from(enrollResp['enrollments'] ?? []);

      List<Map<String, dynamic>> scheduleList = [];
      try {
        final schedResp = await api.get('/schedule');
        scheduleList = List<Map<String, dynamic>>.from(schedResp as List);
      } catch (_) {}

      final scheduleMap = <String, Map<String, dynamic>>{};
      for (final s in scheduleList) {
        final name = s['subject'] as String? ?? '';
        if (name.isNotEmpty && !scheduleMap.containsKey(name)) {
          scheduleMap[name] = s;
        }
      }

      final subjects = <Map<String, dynamic>>[];
      for (final e in enrollments) {
        final course = e['course'] as Map<String, dynamic>? ?? {};
        final courseClass = e['courseClass'] as Map<String, dynamic>? ?? {};
        final name = course['name'] as String? ?? '';
        final code = course['code'] as String? ?? '';
        final credits = course['credits'] as int? ?? 0;
        final classCode = courseClass['classCode'] as String? ?? '';

        final sched = scheduleMap[name];
        final absences = e['currentAbsences'] as int? ?? sched?['currentAbsences'] as int? ?? 0;
        final totalSessions = e['totalSessions'] as int? ?? 0;
        final maxAbs = totalSessions > 0
            ? totalSessions
            : e['maxAbsences'] as int? ?? sched?['maxAbsences'] as int? ?? (credits * 3);
        final midterm = (sched?['midtermScore'] as num?)?.toDouble();
        final finalS = (sched?['finalScore'] as num?)?.toDouble();
        final overall = (sched?['overallScore'] as num?)?.toDouble();

        subjects.add({
          'subject': name,
          'code': code,
          'credits': credits,
          'classCode': classCode,
          'currentAbsences': absences,
          'maxAbsences': maxAbs,
          'midtermScore': midterm,
          'finalScore': finalS,
          'overallScore': overall,
          'teacherName': e['teacherName'] ?? '',
          'departmentName': course['departmentName'] ?? '',
          'courseType': course['courseType'] ?? '',
        });
      }

      subjects.sort((a, b) => (a['subject'] as String).compareTo(b['subject'] as String));

      int totalAbs = 0;
      int totalCred = 0;
      int withScores = 0;
      for (final s in subjects) {
        totalAbs += (s['currentAbsences'] as int? ?? 0);
        totalCred += (s['credits'] as int? ?? 0);
        if (s['overallScore'] != null) withScores++;
      }

      setState(() {
        _subjects = subjects;
        _totalAbsences = totalAbs;
        _totalCredits = totalCred;
        _subjectsWithScores = withScores;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError(cs)
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader(cs)),
                        SliverToBoxAdapter(child: _buildSummary(cs, isDark)),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                            child: Text(
                              'Danh sách môn học (${_subjects.length})',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                        if (_subjects.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.school_outlined,
                                        size: 48,
                                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                                    const SizedBox(height: 12),
                                    Text('Chưa có môn học nào',
                                        style: TextStyle(color: cs.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _buildSubjectCard(_subjects[i], cs, isDark),
                              childCount: _subjects.length,
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _loadData, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Text(
        'Chuyên cần & Điểm thi',
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildSummary(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _summaryItem(Icons.menu_book_rounded, '${_subjects.length}', 'Môn học'),
            _summaryDivider(),
            _summaryItem(Icons.school_rounded, '$_totalCredits', 'Tín chỉ'),
            _summaryDivider(),
            _summaryItem(Icons.event_busy_rounded, '$_totalAbsences', 'Buổi nghỉ'),
            _summaryDivider(),
            _summaryItem(Icons.assessment_rounded, '$_subjectsWithScores', 'Có điểm'),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2));
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, ColorScheme cs, bool isDark) {
    final name = subject['subject'] as String;
    final code = subject['code'] as String? ?? '';
    final credits = subject['credits'] as int? ?? 0;
    final absences = subject['currentAbsences'] as int? ?? 0;
    final maxAbs = subject['maxAbsences'] as int? ?? 6;
    final midterm = subject['midtermScore'] as double?;
    final finalS = subject['finalScore'] as double?;
    final overall = subject['overallScore'] as double?;
    final classCode = subject['classCode'] as String? ?? '';
    final courseType = subject['courseType'] as String? ?? '';
    final absRatio = maxAbs > 0 ? absences / maxAbs : 0.0;

    Color absColor;
    if (absRatio >= 0.8) {
      absColor = AppColors.error;
    } else if (absRatio >= 0.5) {
      absColor = AppColors.warning;
    } else {
      absColor = const Color(0xFF10B981);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0).withValues(alpha: isDark ? 0.15 : 0.5),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${credits}TC',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2563EB),
                        ),
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
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            if (classCode.isNotEmpty)
                              Text(
                                classCode,
                                style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                            if (classCode.isNotEmpty && code.isNotEmpty)
                              Text(' • ', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                            if (code.isNotEmpty)
                              Text(
                                code,
                                style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (courseType.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: courseType == 'required'
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        courseType == 'required' ? 'BB' : 'TC',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: courseType == 'required'
                              ? const Color(0xFF10B981)
                              : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _absenceChip(absences, maxAbs, absColor, isDark),
                  const SizedBox(width: 8),
                  if (midterm != null) ...[
                    _scoreChip('GK', midterm, isDark),
                    const SizedBox(width: 8),
                  ],
                  if (finalS != null) ...[
                    _scoreChip('CK', finalS, isDark),
                    const SizedBox(width: 8),
                  ],
                  if (overall != null)
                    _scoreChip('TK', overall, isDark, highlight: true),
                ],
              ),
              if (maxAbs > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: absRatio.clamp(0.0, 1.0),
                    backgroundColor: cs.onSurfaceVariant.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(absColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _absenceChip(int absences, int maxAbs, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'Nghỉ $absences/$maxAbs',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(String label, double score, bool isDark, {bool highlight = false}) {
    final color = highlight
        ? (score >= 8.0
            ? const Color(0xFF10B981)
            : score >= 5.0
                ? const Color(0xFF2563EB)
                : AppColors.error)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: isDark ? 0.2 : 0.1)
            : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: ${score.toStringAsFixed(1)}',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          color: highlight ? color : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
