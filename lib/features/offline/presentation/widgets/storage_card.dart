import 'package:flutter/material.dart';
import '../../domain/entities/storage_info.dart';
import '../../../../core/theme/app_colors.dart';

class StorageCard extends StatelessWidget {
  final StorageInfo storageInfo;
  final bool isDark;
  final void Function(int courseId)? onDeleteCourse;

  const StorageCard({
    super.key,
    required this.storageInfo,
    required this.isDark,
    this.onDeleteCourse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Quản Lý Bộ Nhớ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${storageInfo.usedFormatted} / ${storageInfo.totalFormatted}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: storageInfo.usagePercent / 100,
              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                storageInfo.usagePercent > 80
                    ? AppColors.error
                    : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          ...storageInfo.courses.map(
            (course) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      course.courseTitle,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    course.sizeFormatted,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => onDeleteCourse?.call(course.courseId),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
