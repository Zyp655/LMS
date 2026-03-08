import 'package:flutter/material.dart';
import '../../domain/entities/heatmap_entry.dart';
import '../../../../core/theme/app_colors.dart';

class ActivityHeatmapWidget extends StatelessWidget {
  final List<HeatmapEntry> entries;

  const ActivityHeatmapWidget({super.key, required this.entries});

  static const _lightColors = [
    AppColors.lightDivider,
    Color(0xFF9BE9A8),
    Color(0xFF40C463),
    Color(0xFF30A14E),
    Color(0xFF216E39),
  ];

  static const _darkColors = [
    AppColors.darkBackground,
    Color(0xFF0E4429),
    Color(0xFF006D32),
    Color(0xFF26A641),
    Color(0xFF39D353),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? _darkColors : _lightColors;
    final entryMap = <String, HeatmapEntry>{};
    for (final entry in entries) {
      final key =
          '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
      entryMap[key] = entry;
    }
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 182));

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
              Icon(Icons.local_fire_department, color: colors[4], size: 20),
              const SizedBox(width: 8),
              Text(
                'Activity Heatmap',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '6 tháng',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    const SizedBox(height: 0),
                    for (final day in ['', 'T2', '', 'T4', '', 'T6', ''])
                      SizedBox(
                        height: 14,
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: _buildWeekColumns(
                      startDate,
                      today,
                      entryMap,
                      colors,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Ít',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
              const SizedBox(width: 4),
              for (int i = 0; i < 5; i++)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                'Nhiều',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeekColumns(
    DateTime start,
    DateTime end,
    Map<String, HeatmapEntry> entryMap,
    List<Color> colors,
  ) {
    final weeks = <Widget>[];
    var current = start;
    while (current.weekday != DateTime.monday) {
      current = current.add(const Duration(days: 1));
    }

    while (current.isBefore(end.add(const Duration(days: 1)))) {
      final column = <Widget>[];
      for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
        final date = current.add(Duration(days: dayOfWeek));
        if (date.isAfter(end)) {
          column.add(const SizedBox(width: 12, height: 12));
          continue;
        }

        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final entry = entryMap[key];
        final level = entry?.level ?? 0;

        column.add(
          Tooltip(
            message: entry != null
                ? '${key}\n${entry.activityCount} hoạt động\n${entry.totalMinutes} phút'
                : '$key\nKhông có hoạt động',
            child: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: colors[level],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }

      weeks.add(Column(children: column));
      current = current.add(const Duration(days: 7));
    }

    return weeks;
  }
}
