import 'package:flutter/material.dart';
import '../../domain/entities/course_entity.dart';
import '../../../../core/theme/app_colors.dart';

class CourseAboutTab extends StatelessWidget {
  final CourseEntity course;

  const CourseAboutTab({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả khóa học',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            course.description ?? 'Chưa có mô tả chi tiết.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bạn sẽ học được gì?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...[
            'Nắm vững kiến thức nền tảng',
            'Thực hành qua các bài tập thực tế',
            'Xây dựng dự án hoàn chỉnh',
            'Nhận chứng chỉ hoàn thành',
          ].map((item) => _buildCheckItem(item)),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
