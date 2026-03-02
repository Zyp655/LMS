import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ImportStepIndicator extends StatelessWidget {
  final int currentStep;
  final bool isDark;
  final List<String> labels;
  final List<IconData> icons;

  const ImportStepIndicator({
    super.key,
    required this.currentStep,
    required this.isDark,
    this.labels = const ['Tệp mẫu', 'Tải lên', 'Kiểm tra', 'Kết quả'],
    this.icons = const [
      Icons.description_outlined,
      Icons.upload_file_rounded,
      Icons.fact_check_outlined,
      Icons.download_done_rounded,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          final color = isActive
              ? AppColors.primary
              : isDone
              ? AppColors.success
              : (isDark ? Colors.white24 : Colors.grey.shade300);

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: isActive ? 0.15 : 0.08),
                    border: Border.all(color: color, width: isActive ? 2 : 1),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : icons[i],
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? AppColors.primary
                        : isDone
                        ? AppColors.success
                        : (isDark ? Colors.white38 : Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
