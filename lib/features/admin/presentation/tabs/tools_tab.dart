import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/route/app_route.dart';

class ToolsTab extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSeedRoadmap;

  const ToolsTab({
    super.key,
    required this.isLoading,
    required this.onSeedRoadmap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolCard(
            cs: cs,
            icon: Icons.upload_file_rounded,
            iconColor: Colors.teal.shade800,
            iconBg: Colors.teal.shade50,
            title: 'Import Sinh Viên',
            subtitle: 'CSV hoặc Excel · Mã SV, Họ Tên, Email, Khoa',
            buttonLabel: 'Chọn File',
            buttonColor: Colors.teal.shade50,
            buttonTextColor: Colors.teal.shade800,
            onPressed: () => context.push(AppRoutes.studentImport),
          ),
          const SizedBox(height: 16),
          _toolCard(
            cs: cs,
            icon: Icons.school_rounded,
            iconColor: Colors.indigo.shade800,
            iconBg: Colors.indigo.shade50,
            title: 'Import Giảng Viên',
            subtitle: 'Excel · Mã GV, Họ Tên, Email, Khoa',
            buttonLabel: 'Chọn File',
            buttonColor: Colors.indigo.shade50,
            buttonTextColor: Colors.indigo.shade800,
            onPressed: () => context.push(AppRoutes.teacherImport),
          ),
          const SizedBox(height: 16),
          _toolCard(
            cs: cs,
            icon: Icons.menu_book_rounded,
            iconColor: Colors.deepOrange.shade800,
            iconBg: Colors.deepOrange.shade50,
            title: 'Import Môn Học',
            subtitle: 'Excel · Mã môn, Tên môn, Khoa, Tín chỉ',
            buttonLabel: 'Chọn File',
            buttonColor: Colors.deepOrange.shade50,
            buttonTextColor: Colors.deepOrange.shade800,
            onPressed: () => context.push(AppRoutes.subjectImport),
          ),
          const SizedBox(height: 16),
          _toolCard(
            cs: cs,
            icon: Icons.map_rounded,
            iconColor: Colors.indigo.shade800,
            iconBg: Colors.indigo.shade50,
            title: 'Seed Roadmap & Khoá học',
            subtitle: 'Tạo lộ trình và khoá học mẫu',
            buttonLabel: 'Seed',
            buttonColor: Colors.indigo.shade50,
            buttonTextColor: Colors.indigo.shade800,
            onPressed: isLoading ? null : onSeedRoadmap,
          ),
          const SizedBox(height: 16),
          _toolCard(
            cs: cs,
            icon: Icons.assignment_ind_rounded,
            iconColor: Colors.blue.shade800,
            iconBg: Colors.blue.shade50,
            title: 'Import Ghi Danh (SIS)',
            subtitle: 'Import danh sách ghi danh từ file Excel/CSV',
            buttonLabel: 'Import',
            buttonColor: Colors.blue.shade50,
            buttonTextColor: Colors.blue.shade800,
            onPressed: () => context.push(AppRoutes.enrollmentImport),
          ),
          if (isLoading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _toolCard({
    required ColorScheme cs,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color buttonColor,
    required Color buttonTextColor,
    required VoidCallback? onPressed,
  }) {
    return Card(
      elevation: 0,
      shadowColor: cs.shadow.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
