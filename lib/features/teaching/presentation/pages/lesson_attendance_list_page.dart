import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import 'lesson_student_access_page.dart';

class LessonAttendanceListPage extends StatefulWidget {
  final int classId;
  final int courseId;
  final String className;

  const LessonAttendanceListPage({
    super.key,
    required this.classId,
    required this.courseId,
    required this.className,
  });

  @override
  State<LessonAttendanceListPage> createState() =>
      _LessonAttendanceListPageState();
}

class _LessonAttendanceListPageState extends State<LessonAttendanceListPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _modules = [];
  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = sl<ApiClient>();

      final res = await api.get('/academic/courses/${widget.courseId}');
      final modules =
          List<Map<String, dynamic>>.from(res['modules'] ?? []);

      final studentsRes = await api
          .get('/teacher/class-students?classId=${widget.classId}');
      final total = studentsRes['total'] as int? ?? 0;

      if (mounted) {
        setState(() {
          _modules = modules;
          _totalStudents = total;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Lỗi tải dữ liệu: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_totalStudents SV',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
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

    if (_modules.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              children: [
                Icon(Icons.video_library_outlined,
                    size: 64, color: AppColors.textSecondary(context)),
                const SizedBox(height: 16),
                Text(
                  'Chưa có bài học nào',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _modules.length,
      itemBuilder: (context, index) =>
          _buildModuleSection(_modules[index], isDark),
    );
  }

  Widget _buildModuleSection(Map<String, dynamic> module, bool isDark) {
    final title = module['title'] ?? 'Module';
    final lessons =
        List<Map<String, dynamic>>.from(module['lessons'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.folder_outlined,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              Text(
                '${lessons.length} bài',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),

        ...lessons.map((lesson) => _buildLessonCard(lesson, isDark)),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson, bool isDark) {
    final lessonId = lesson['id'] as int;
    final title = lesson['title'] ?? '';
    final type = lesson['type'] ?? 'video';
    final duration = lesson['durationMinutes'] ?? 0;

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'video':
        icon = Icons.play_circle_outline;
        iconColor = AppColors.info;
        break;
      case 'reading':
        icon = Icons.article_outlined;
        iconColor = AppColors.success;
        break;
      case 'quiz':
        icon = Icons.quiz_outlined;
        iconColor = AppColors.warning;
        break;
      default:
        icon = Icons.description_outlined;
        iconColor = AppColors.primary;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8, left: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LessonStudentAccessPage(
                classId: widget.classId,
                lessonId: lessonId,
                lessonTitle: title,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_typeLabel(type)} • ${duration}p',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.people_outline,
                size: 18,
                color: AppColors.textSecondary(context),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'video':
        return 'Video';
      case 'reading':
        return 'Tài liệu';
      case 'quiz':
        return 'Quiz';
      default:
        return 'Bài học';
    }
  }
}
