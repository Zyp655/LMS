import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_constants.dart';
import '../../../../core/theme/app_colors.dart';

class EngagementReportPage extends StatefulWidget {
  final int userId;

  const EngagementReportPage({super.key, required this.userId});

  @override
  State<EngagementReportPage> createState() => _EngagementReportPageState();
}

class _EngagementReportPageState extends State<EngagementReportPage> {
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
        Uri.parse(
          '${ApiConstants.baseUrl}/analytics/learning-profile?userId=${widget.userId}',
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
        title: const Text('📋 Learning Profile'),
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
    final overview = _data!['overview'] as Map<String, dynamic>? ?? {};
    final skillProfile = _data!['skillProfile'] as Map<String, dynamic>? ?? {};
    final weakTopics = skillProfile['weakTopics'] as List? ?? [];
    final strongTopics = skillProfile['strongTopics'] as List? ?? [];
    final improvingTopics = skillProfile['improvingTopics'] as List? ?? [];
    final activityBreakdown = _data!['activityBreakdown'] as Map<String, dynamic>? ?? {};
    final engagementLevel = overview['engagementLevel'] as String? ?? 'low';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEngagementBanner(cs, engagementLevel),
        const SizedBox(height: 16),
        _buildOverviewGrid(cs, isDark, overview),
        const SizedBox(height: 16),
        if (weakTopics.isNotEmpty || strongTopics.isNotEmpty || improvingTopics.isNotEmpty)
          _buildSkillBreakdown(cs, isDark, weakTopics, strongTopics, improvingTopics),
        if (activityBreakdown.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildActivityBreakdown(cs, isDark, activityBreakdown),
        ],
      ],
    );
  }

  Widget _buildEngagementBanner(ColorScheme cs, String level) {
    final config = switch (level) {
      'excellent' => ('🔥 Xuất sắc', AppColors.success, 'Bạn đang học rất tốt!'),
      'good' => ('✅ Tốt', AppColors.primary, 'Tiếp tục phát huy!'),
      'fair' => ('⚡ Trung bình', AppColors.warning, 'Hãy tăng thời gian học'),
      _ => ('⚠️ Cần cải thiện', AppColors.error, 'Hãy quay lại học mỗi ngày'),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [config.$2, config.$2.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.$1,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            config.$3,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(ColorScheme cs, bool isDark, Map<String, dynamic> overview) {
    final items = [
      ('📚', '${overview['enrolledCourses'] ?? 0}', 'Khóa học'),
      ('✅', '${overview['completedLessons'] ?? 0}', 'Bài hoàn thành'),
      ('⏱', '${overview['totalStudyMinutes30d'] ?? 0} phút', '30 ngày qua'),
      ('🔥', '${overview['currentStreak'] ?? 0} ngày', 'Streak'),
      ('📊', '${(overview['overallAvgScore'] as num? ?? 0).toStringAsFixed(0)}%', 'Điểm TB Quiz'),
      ('🏆', '${overview['longestStreak'] ?? 0} ngày', 'Streak dài nhất'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
            'Tổng quan',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      item.$3,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBreakdown(
    ColorScheme cs,
    bool isDark,
    List weakTopics,
    List strongTopics,
    List improvingTopics,
  ) {
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
            '🎯 Kỹ năng theo chủ đề',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (strongTopics.isNotEmpty)
            _buildTopicSection('Thành thạo', strongTopics, AppColors.success, cs),
          if (improvingTopics.isNotEmpty)
            _buildTopicSection('Đang tiến bộ', improvingTopics, AppColors.warning, cs),
          if (weakTopics.isNotEmpty)
            _buildTopicSection('Cần cải thiện', weakTopics, AppColors.error, cs),
        ],
      ),
    );
  }

  Widget _buildTopicSection(String label, List topics, Color color, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
        ...topics.map((t) {
          final topic = t as Map<String, dynamic>;
          final skill = (topic['skillLevel'] as num?)?.toDouble() ?? 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    topic['topic'] as String? ?? '',
                    style: TextStyle(color: cs.onSurface, fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: skill,
                      backgroundColor: color.withValues(alpha: 0.15),
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(skill * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildActivityBreakdown(ColorScheme cs, bool isDark, Map<String, dynamic> breakdown) {
    final labels = <String, String>{
      'video_watch': '🎬 Xem video',
      'lesson_complete': '✅ Hoàn thành bài',
      'quiz_attempt': '📝 Làm quiz',
      'document_access': '📄 Đọc tài liệu',
      'assignment_submit': '📎 Nộp bài tập',
    };

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
            '📈 Hoạt động 30 ngày qua',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...breakdown.entries.map((e) {
            final label = labels[e.key] ?? e.key;
            final count = e.value as int? ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: TextStyle(color: cs.onSurface, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count lần',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
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
