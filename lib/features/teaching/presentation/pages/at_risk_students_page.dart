import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_constants.dart';
import '../../../../core/theme/app_colors.dart';

class AtRiskStudentsPage extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const AtRiskStudentsPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<AtRiskStudentsPage> createState() => _AtRiskStudentsPageState();
}

class _AtRiskStudentsPageState extends State<AtRiskStudentsPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/courses/${widget.courseId}/at-risk-students'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _data = jsonDecode(response.body) as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Lỗi: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể tải dữ liệu';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('⚠️ Sinh viên nguy cơ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: cs.onSurface)))
              : RefreshIndicator(onRefresh: _load, child: _buildContent(cs, isDark)),
    );
  }

  Widget _buildContent(ColorScheme cs, bool isDark) {
    final summary = _data!['summary'] as Map<String, dynamic>? ?? {};
    final students = _data!['atRiskStudents'] as List? ?? [];
    final totalStudents = _data!['totalStudents'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(cs, isDark, summary, totalStudents),
        const SizedBox(height: 16),
        if (students.isEmpty)
          _buildEmptyState(cs)
        else
          ...students.map((s) => _buildStudentCard(cs, isDark, s as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildSummaryCard(ColorScheme cs, bool isDark, Map<String, dynamic> summary, int total) {
    final atRisk = summary['atRiskCount'] as int? ?? 0;
    final warning = summary['warningCount'] as int? ?? 0;
    final percent = (summary['atRiskPercent'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: atRisk > 0
              ? [AppColors.error, AppColors.error.withValues(alpha: 0.7)]
              : [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.courseTitle,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSumStat('$total', 'Tổng SV'),
              const SizedBox(width: 20),
              _buildSumStat('$atRisk', 'Nguy cơ cao'),
              const SizedBox(width: 20),
              _buildSumStat('$warning', 'Cảnh báo'),
              const SizedBox(width: 20),
              _buildSumStat('${percent.toStringAsFixed(0)}%', 'Tỷ lệ'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSumStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
          const SizedBox(height: 16),
          Text(
            'Không có sinh viên nào có nguy cơ!',
            style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(ColorScheme cs, bool isDark, Map<String, dynamic> student) {
    final riskLevel = student['riskLevel'] as String? ?? 'medium';
    final riskScore = (student['riskScore'] as num?)?.toDouble() ?? 0;
    final factors = (student['riskFactors'] as List?)?.cast<String>() ?? [];
    final completion = (student['completionRate'] as num?)?.toDouble() ?? 0;
    final quizScore = (student['avgQuizScore'] as num?)?.toDouble() ?? 0;

    final isHigh = riskLevel == 'high';
    final accentColor = isHigh ? AppColors.error : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accentColor.withValues(alpha: 0.15),
                child: Icon(
                  isHigh ? Icons.warning_rounded : Icons.info_outline,
                  color: accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['fullName'] as String? ?? '',
                      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      student['email'] as String? ?? '',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${riskScore.toStringAsFixed(0)}%',
                  style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat('Tiến độ', '${(completion * 100).toStringAsFixed(0)}%', cs),
              const SizedBox(width: 12),
              _buildMiniStat('Quiz', '${quizScore.toStringAsFixed(0)}%', cs),
              const SizedBox(width: 12),
              _buildMiniStat('Streak', '${student['currentStreak'] ?? 0}d', cs),
              const SizedBox(width: 12),
              _buildMiniStat('Nghỉ', '${student['daysSinceActivity'] ?? 0}d', cs),
            ],
          ),
          if (factors.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: factors.map((f) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(f, style: TextStyle(color: accentColor, fontSize: 11)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, ColorScheme cs) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
        ],
      ),
    );
  }
}
