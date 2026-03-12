import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/roadmap_bloc.dart';
import '../bloc/roadmap_event.dart';
import '../bloc/roadmap_state.dart';

class LearningPathsPage extends StatefulWidget {
  const LearningPathsPage({super.key});

  @override
  State<LearningPathsPage> createState() => _LearningPathsPageState();
}

class _LearningPathsPageState extends State<LearningPathsPage> {
  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  void _loadRoadmap() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthSuccess ? authState.user?.id : null;
    if (userId != null) {
      context.read<RoadmapBloc>().add(LoadPersonalRoadmap(userId: userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lộ Trình Cá Nhân'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
            onPressed: _loadRoadmap,
          ),
        ],
      ),
      body: BlocConsumer<RoadmapBloc, RoadmapState>(
        buildWhen: (previous, current) => current is! RoadmapActionSuccess,
        listener: (context, state) {
          if (state is RoadmapActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          } else if (state is RoadmapError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: cs.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RoadmapLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RoadmapNoData) {
            return _buildEmptyState(cs, state.message);
          }

          if (state is PersonalRoadmapLoaded) {
            return _buildContent(context, cs, state);
          }

          return _buildEmptyState(cs, 'Nhấn nút tải lại để bắt đầu');
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_rounded, size: 72, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadRoadmap,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Tạo lộ trình'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme cs,
    PersonalRoadmapLoaded state,
  ) {
    final stats = state.stats;
    final total = stats['total'] as int? ?? 0;
    final completed = stats['completed'] as int? ?? 0;
    final inProgress = stats['inProgress'] as int? ?? 0;
    final totalCredits = stats['totalCredits'] as int? ?? 0;
    final completedCredits = stats['completedCredits'] as int? ?? 0;
    final progress = total > 0 ? completed / total : 0.0;

    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final item in state.items) {
      final sem = item['semesterOrder'] as int? ?? 1;
      grouped.putIfAbsent(sem, () => []).add(item);
    }
    final semesters = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () async => _loadRoadmap(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProgressCard(
            cs,
            progress,
            completed,
            total,
            inProgress,
            totalCredits,
            completedCredits,
          ),
          const SizedBox(height: 20),
          ...semesters.map(
            (sem) =>
                _buildSemesterSection(context, cs, sem, grouped[sem]!, state),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    ColorScheme cs,
    double progress,
    int completed,
    int total,
    int inProgress,
    int totalCredits,
    int completedCredits,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Tiến Độ Lộ Trình',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withAlpha(76),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statChip(
                Icons.check_circle,
                '$completed/$total môn',
                Colors.white.withAlpha(51),
              ),
              const SizedBox(width: 8),
              _statChip(
                Icons.play_circle,
                '$inProgress đang học',
                Colors.white.withAlpha(51),
              ),
              const SizedBox(width: 8),
              _statChip(
                Icons.school,
                '$completedCredits/$totalCredits TC',
                Colors.white.withAlpha(51),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSection(
    BuildContext context,
    ColorScheme cs,
    int semester,
    List<Map<String, dynamic>> items,
    PersonalRoadmapLoaded state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Học kỳ $semester',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length} môn',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildCourseCard(context, cs, item, state)),
      ],
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    ColorScheme cs,
    Map<String, dynamic> item,
    PersonalRoadmapLoaded state,
  ) {
    final status = item['status'] as String? ?? 'pending';
    final isRequired = item['isRequired'] as bool? ?? true;
    final credits = item['credits'] as int? ?? 0;
    final note = item['note'] as String?;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusLabel = 'Hoàn thành';
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusLabel = 'Đang học';
        statusIcon = Icons.play_circle;
        break;
      default:
        statusColor = cs.outline;
        statusLabel = 'Chưa học';
        statusIcon = Icons.circle_outlined;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: status == 'completed'
              ? Colors.green.withAlpha(102)
              : cs.outlineVariant.withAlpha(102),
        ),
      ),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item['courseName'] as String? ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: status == 'completed'
                          ? TextDecoration.lineThrough
                          : null,
                      color: status == 'completed'
                          ? cs.onSurfaceVariant
                          : cs.onSurface,
                    ),
                  ),
                ),
                _badge(statusLabel, statusColor, statusColor.withAlpha(25)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 30),
                _infoBadge(cs, item['courseCode'] as String? ?? ''),
                const SizedBox(width: 6),
                _infoBadge(cs, '$credits TC'),
                const SizedBox(width: 6),
                _infoBadge(cs, isRequired ? 'Bắt buộc' : 'Tự chọn'),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showItemOptions(context, item, state),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.more_horiz,
                      color: cs.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(left: 30),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha(128),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _infoBadge(ColorScheme cs, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  void _showItemOptions(
    BuildContext context,
    Map<String, dynamic> item,
    PersonalRoadmapLoaded state,
  ) {
    final cs = Theme.of(context).colorScheme;
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthSuccess ? authState.user?.id : null;
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: const Text('Thêm ghi chú'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editNote(context, item, userId);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                title: Text(
                  'Xóa khỏi lộ trình',
                  style: TextStyle(color: cs.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<RoadmapBloc>().add(
                    RemoveRoadmapItem(
                      itemId: item['id'] as int,
                      userId: userId,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editNote(BuildContext context, Map<String, dynamic> item, int userId) {
    final controller = TextEditingController(
      text: item['note'] as String? ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ghi chú'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Viết ghi chú cho môn học này...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<RoadmapBloc>().add(
                UpdateRoadmapItem(
                  userId: userId,
                  data: {'itemId': item['id'], 'note': controller.text.trim()},
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
