import 'package:flutter/material.dart';
import '../../domain/entities/analytics_summary.dart';
import '../../../../core/theme/app_colors.dart';

class QuickStatsCard extends StatelessWidget {
  final AnalyticsSummary summary;

  const QuickStatsCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkSurfaceVariant, AppColors.darkSurface]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(76),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            icon: Icons.local_fire_department,
            value: '${summary.currentStreak}',
            label: 'Streak',
            color: AppColors.error,
          ),
          _buildDivider(),
          _buildStat(
            icon: Icons.schedule,
            value: summary.weekStudyTimeFormatted,
            label: 'Tuần này',
            color: AppColors.secondary,
          ),
          _buildDivider(),
          _buildStat(
            icon: Icons.trending_up,
            value: '${summary.overallProgress.toStringAsFixed(0)}%',
            label: 'Tiến độ',
            color: const Color(0xFF39D353),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(178)),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withAlpha(51),
    );
  }
}
