import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_constants.dart';
import '../../../../core/theme/app_colors.dart';

class CourseInsightsPage extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const CourseInsightsPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<CourseInsightsPage> createState() => _CourseInsightsPageState();
}

class _CourseInsightsPageState extends State<CourseInsightsPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/courses/${widget.courseId}/analytics/insights',
        ),
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
        title: Text(
          '🤖 AI Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError(cs)
              : RefreshIndicator(
                  onRefresh: _loadInsights,
                  child: _buildContent(cs, isDark),
                ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: cs.onSurface)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadInsights,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, bool isDark) {
    final totalStudents = _data!['totalStudents'] as int? ?? 0;
    final moduleStats = _data!['moduleStats'] as List? ?? [];
    final aiInsights = _data!['aiInsights'] as Map<String, dynamic>? ?? {};

    final summary = aiInsights['summary'] as String? ?? '';
    final causes = (aiInsights['causes'] as List?)?.cast<String>() ?? [];
    final recommendations = (aiInsights['recommendations'] as List?)?.cast<String>() ?? [];
    final bottleneck = aiInsights['top_bottleneck'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOverviewCard(cs, isDark, totalStudents, moduleStats.length),
        const SizedBox(height: 16),
        if (summary.isNotEmpty) _buildAiSummaryCard(cs, isDark, summary),
        const SizedBox(height: 16),
        if (bottleneck != null) _buildBottleneckCard(cs, isDark, bottleneck),
        const SizedBox(height: 16),
        if (moduleStats.isNotEmpty) _buildModuleFunnel(cs, isDark, moduleStats, totalStudents),
        const SizedBox(height: 16),
        if (causes.isNotEmpty) _buildListCard(cs, isDark, '⚠️ Nguyên nhân', causes, AppColors.warning),
        const SizedBox(height: 16),
        if (recommendations.isNotEmpty)
          _buildListCard(cs, isDark, '💡 Đề xuất cải thiện', recommendations, AppColors.success),
      ],
    );
  }

  Widget _buildOverviewCard(ColorScheme cs, bool isDark, int students, int modules) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courseTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '$students sinh viên · $modules chương',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.insights, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSummaryCard(ColorScheme cs, bool isDark, String summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Phân tích AI',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: TextStyle(color: cs.onSurface, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottleneckCard(ColorScheme cs, bool isDark, Map<String, dynamic> bottleneck) {
    final moduleName = bottleneck['moduleName'] as String? ?? '';
    final dropRate = (bottleneck['dropRate'] as num?)?.toDouble() ?? 0.0;
    final avgScore = (bottleneck['avgScore'] as num?)?.toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Điểm nghẽn lớn nhất',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            moduleName,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetric('Tỷ lệ rớt', '${(dropRate * 100).toStringAsFixed(0)}%', AppColors.error),
              const SizedBox(width: 16),
              if (avgScore != null)
                _buildMetric('Điểm TB Quiz', avgScore.toStringAsFixed(1), AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildModuleFunnel(ColorScheme cs, bool isDark, List moduleStats, int totalStudents) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Completion Funnel',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...moduleStats.asMap().entries.map((entry) {
            final idx = entry.key;
            final stat = entry.value as Map<String, dynamic>;
            final title = stat['title'] as String? ?? 'Module ${idx + 1}';
            final completionRate = (stat['completionRate'] as num?)?.toDouble() ?? 0.0;
            final studentCount = stat['studentCount'] as int? ?? 0;

            final barColor = completionRate > 0.6
                ? AppColors.success
                : completionRate > 0.3
                    ? AppColors.warning
                    : AppColors.error;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(color: cs.onSurface, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$studentCount/${totalStudents} (${(completionRate * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          color: barColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completionRate,
                      backgroundColor: barColor.withValues(alpha: 0.15),
                      color: barColor,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildListCard(ColorScheme cs, bool isDark, String title, List<String> items, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(color: cs.onSurface, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
