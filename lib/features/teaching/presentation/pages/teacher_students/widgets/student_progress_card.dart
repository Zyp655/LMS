import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';

class StudentProgressCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final ValueChanged<bool?>? onSelectChanged;
  final VoidCallback onNudge;

  const StudentProgressCard({
    super.key,
    required this.student,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onTap,
    this.onSelectChanged,
    required this.onNudge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isAtRisk = student['isAtRisk'] == true;
    final progressPercent = student['progressPercent'] ?? 0;
    final lastNudgedAt = student['lastNudgedAt'] as String?;
    final quizAverage = student['quizAverage'];
    final studentEmail = student['email'] as String? ?? '';

    final avatarColor =
        Colors.primaries[studentEmail.hashCode % Colors.primaries.length];

    Color statusColor = AppColors.success;
    String statusText = 'Tốt';
    if (isAtRisk) {
      statusColor = AppColors.error;
      statusText = 'Cần chú ý';
    } else if (progressPercent < 50) {
      statusColor = AppColors.warning;
      statusText = 'Trung bình';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.border(context),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isSelectionMode
              ? () => onSelectChanged?.call(!isSelected)
              : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: onSelectChanged,
                      activeColor: AppColors.accent,
                      side: BorderSide(color: AppColors.textSecondary(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: avatarColor.withAlpha(isDark ? 50 : 30),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: avatarColor.withAlpha(isDark ? 80 : 60),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    studentEmail.isNotEmpty
                        ? studentEmail[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student['email'] ?? '',
                              style: TextStyle(
                                color: AppColors.textPrimary(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(isDark ? 25 : 15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withAlpha(isDark ? 50 : 30),
                              ),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progressPercent / 100,
                                backgroundColor: isDark
                                    ? Colors.white.withAlpha(15)
                                    : Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                  isAtRisk ? AppColors.error : AppColors.accent,
                                ),
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$progressPercent%',
                            style: TextStyle(
                              color: isAtRisk
                                  ? AppColors.error
                                  : AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 16,
                            color: AppColors.textSecondary(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${student['completedLessons'] ?? 0}/${student['totalLessons'] ?? 0}',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.quiz_outlined,
                            size: 16,
                            color: AppColors.textSecondary(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            quizAverage != null
                                ? '${(quizAverage as num).toStringAsFixed(1)}%'
                                : '--',
                            style: TextStyle(
                              color: quizAverage != null
                                  ? AppColors.warning
                                  : AppColors.textSecondary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),

                          if (isAtRisk) ...[
                            if (lastNudgedAt != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  'Đã nhắc',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            InkWell(
                              onTap: onNudge,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withAlpha(isDark ? 30 : 18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF6C63FF,
                                    ).withAlpha(isDark ? 60 : 40),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: AppColors.secondary,
                                      size: 14,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Nhắc nhở',
                                      style: TextStyle(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
