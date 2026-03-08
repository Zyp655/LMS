import 'package:flutter/material.dart';
import '../../domain/entities/benchmark_data.dart';
import '../../../../core/theme/app_colors.dart';

class BenchmarkBarWidget extends StatelessWidget {
  final BenchmarkData benchmark;

  const BenchmarkBarWidget({super.key, required this.benchmark});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'So Sánh Với Lớp',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Top ${benchmark.percentileRank}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar(
            context,
            label: 'Bạn',
            value: benchmark.myProgress,
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            context,
            label: 'TB lớp',
            value: benchmark.avgProgress,
            color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            context,
            label: 'Top',
            value: benchmark.topProgress,
            color: const Color(0xFF39D353),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(13) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTimeCompare(
                    'Thời gian học của bạn',
                    benchmark.myStudyTimeFormatted,
                    AppColors.primary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: isDark ? Colors.white12 : Colors.grey[300],
                ),
                Expanded(
                  child: _buildTimeCompare(
                    'Trung bình lớp',
                    benchmark.avgStudyTimeFormatted,
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context, {
    required String label,
    required double value,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(13) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (value / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${value.toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCompare(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
