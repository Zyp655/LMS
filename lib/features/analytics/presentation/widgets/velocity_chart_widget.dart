import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/velocity_data.dart';
import '../../../../core/theme/app_colors.dart';

class VelocityChartWidget extends StatelessWidget {
  final VelocityData velocity;

  const VelocityChartWidget({super.key, required this.velocity});

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
              Icon(Icons.speed, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Dự Đoán Hoàn Thành',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (velocity.predictedCompletionDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Hoàn thành dự kiến: ${_formatDate(velocity.predictedCompletionDate!)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  _buildTrendBadge(),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: velocity.dailyProgress.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có dữ liệu học tập',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : LineChart(_buildChart(isDark)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(
                'Đã xong',
                '${velocity.completedLessons}/${velocity.totalLessons}',
                const Color(0xFF39D353),
              ),
              _buildMiniStat(
                'Tốc độ',
                velocity.dailyVelocity != null
                    ? '${velocity.dailyVelocity!.toStringAsFixed(1)}/ngày'
                    : 'N/A',
                AppColors.secondary,
              ),
              _buildMiniStat(
                'Độ tin cậy',
                '${(velocity.confidence * 100).toStringAsFixed(0)}%',
                AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBadge() {
    Color color;
    IconData icon;
    switch (velocity.trend) {
      case 'accelerating':
        color = const Color(0xFF39D353);
        icon = Icons.trending_up;
        break;
      case 'slowing':
        color = AppColors.error;
        icon = Icons.trending_down;
        break;
      default:
        color = AppColors.secondary;
        icon = Icons.trending_flat;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  LineChartData _buildChart(bool isDark) {
    final spots = <FlSpot>[];
    for (int i = 0; i < velocity.dailyProgress.length; i++) {
      spots.add(
        FlSpot(
          i.toDouble(),
          velocity.dailyProgress[i].lessonsCompleted.toDouble(),
        ),
      );
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: isDark ? Colors.white12 : Colors.grey[200]!,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withAlpha(76),
                AppColors.primary.withAlpha(0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
