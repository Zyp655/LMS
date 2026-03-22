import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

class StudentDetailSheet extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onSendNotification;
  final VoidCallback onViewHistory;
  final String Function(String?) formatTime;

  const StudentDetailSheet({
    super.key,
    required this.student,
    required this.onSendNotification,
    required this.onViewHistory,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final subtextColor = isDark ? Colors.grey[400]! : AppColors.textSecondaryLight;


    final progressPercent = student['progressPercent'] ?? 0;
    final completedLessons = student['completedLessons'] ?? 0;
    final totalLessons = student['totalLessons'] ?? 0;
    final quizAverage = student['quizAverage'] as num?;
    final riskScore = (student['riskScore'] as num?)?.toDouble() ?? 0;
    final warningLevel = student['warningLevel'] ?? 1;
    final absenceCount = student['absenceCount'] ?? 0;
    final totalAttendances = student['totalAttendances'] ?? 0;
    final lateCount = student['lateCount'] ?? 0;
    final totalAssignments = student['totalAssignments'] ?? 0;
    final status = student['status'] ?? 'not_started';
    final daysInactive = student['daysInactive'] ?? 0;
    final isAtRisk = student['isAtRisk'] == true;

    final statusLabel = status == 'completed'
        ? 'Hoàn thành'
        : status == 'in_progress'
            ? 'Đang học'
            : 'Chưa bắt đầu';
    final statusColor = status == 'completed'
        ? AppColors.success
        : status == 'in_progress'
            ? AppColors.primary
            : Colors.grey;

    final warningColor = warningLevel == 3
        ? AppColors.error
        : warningLevel == 2
            ? Colors.orange
            : AppColors.success;
    final warningLabel = warningLevel == 3
        ? 'Cao'
        : warningLevel == 2
            ? 'Trung bình'
            : 'Thấp';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),

            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    (student['fullName'] as String? ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['fullName'] ?? 'Unknown',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        student['email'] ?? '',
                        style: TextStyle(color: subtextColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Tiến độ', style: TextStyle(color: subtextColor, fontSize: 13)),
                      const Spacer(),
                      Text(
                        '$progressPercent%',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent / 100,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      color: progressPercent >= 100 ? AppColors.success : AppColors.primary,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$completedLessons / $totalLessons bài học',
                        style: TextStyle(color: subtextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                _StatCard(
                  icon: Icons.quiz_outlined,
                  label: 'Quiz TB',
                  value: quizAverage != null ? '${quizAverage.toStringAsFixed(1)}%' : '--',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.event_busy_outlined,
                  label: 'Vắng',
                  value: '$absenceCount/$totalAttendances',
                  color: absenceCount > 0 ? Colors.orange : AppColors.success,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.assignment_late_outlined,
                  label: 'BT trễ',
                  value: '$lateCount/$totalAssignments',
                  color: lateCount > 0 ? AppColors.error : AppColors.success,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Đăng ký',
                    value: formatTime(student['enrolledAt']),
                    textColor: textColor,
                    subtextColor: subtextColor,
                  ),
                  const Divider(height: 16),
                  _InfoRow(
                    label: 'Truy cập cuối',
                    value: formatTime(student['lastAccessedAt']),
                    textColor: textColor,
                    subtextColor: subtextColor,
                  ),
                  const Divider(height: 16),
                  _InfoRow(
                    label: 'Điểm rủi ro',
                    value: '${riskScore.toStringAsFixed(1)} / 100',
                    textColor: textColor,
                    subtextColor: subtextColor,
                    valueColor: warningColor,
                  ),
                  const Divider(height: 16),
                  _InfoRow(
                    label: 'Mức cảnh báo',
                    value: 'Mức $warningLevel ($warningLabel)',
                    textColor: textColor,
                    subtextColor: subtextColor,
                    valueColor: warningColor,
                  ),
                ],
              ),
            ),

            if (isAtRisk) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        daysInactive > 0
                            ? 'Học viên đã không hoạt động $daysInactive ngày. Cần nhắc nhở!'
                            : 'Học viên có nguy cơ cao. Cần theo dõi sát!',
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onSendNotification();
                    },
                    icon: const Icon(Icons.notifications_outlined, size: 18),
                    label: const Text('Gửi thông báo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onViewHistory();
                    },
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Lịch sử'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : AppColors.textSecondaryLight,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color subtextColor;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.subtextColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subtextColor, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
