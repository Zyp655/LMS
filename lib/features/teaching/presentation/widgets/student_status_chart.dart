import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StudentStatusChart extends StatelessWidget {
  final int notStarted;
  final int inProgress;
  final int completed;

  const StudentStatusChart({
    super.key,
    required this.notStarted,
    required this.inProgress,
    required this.completed,
  });

  int get _total => notStarted + inProgress + completed;

  @override
  Widget build(BuildContext context) {
    if (_total == 0) {
      return Container(
        padding: AppSpacing.paddingXl,
        decoration: BoxDecoration(
          color: AppColors.cardColor(context),
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        child: Center(
          child: Text(
            'Chưa có học viên',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ),
      );
    }

    return Container(
      padding: AppSpacing.paddingXl,
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trạng thái học viên',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.gapV16,
          _StatusBar(
            label: 'Chưa học',
            value: notStarted,
            total: _total,
            color: Colors.grey,
          ),
          AppSpacing.gapV8,
          _StatusBar(
            label: 'Đang học',
            value: inProgress,
            total: _total,
            color: AppColors.warning,
          ),
          AppSpacing.gapV8,
          _StatusBar(
            label: 'Hoàn thành',
            value: completed,
            total: _total,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _StatusBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? value / total : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.border(context),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
