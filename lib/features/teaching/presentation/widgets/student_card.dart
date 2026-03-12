import 'package:flutter/material.dart';
import '../../domain/entities/student_entity.dart';
import '../../../../core/theme/app_colors.dart';

class StudentCard extends StatelessWidget {
  final StudentEntity student;
  final int index;
  final VoidCallback onEdit;

  const StudentCard({
    super.key,
    required this.student,
    required this.index,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    double attendanceScore = (10 - (student.currentAbsences * 1)).toDouble();
    if (attendanceScore < 0) attendanceScore = 0;

    final midterm = student.midtermScore ?? 0;
    final finalS = student.finalScore ?? 0;
    final exam = student.examScore ?? 0;

    double total =
        (attendanceScore * 0.1) +
        (midterm * 0.15) +
        (finalS * 0.15) +
        (exam * 0.6);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: CircleAvatar(
                backgroundColor: AppColors.info.withValues(alpha: 0.15),
                foregroundColor: AppColors.info,
                child: Text("${index + 1}"),
              ),
              title: Text(
                student.studentName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("ID: ${student.studentId}"),
              trailing: IconButton(
                icon: Icon(Icons.edit_note, color: AppColors.info),
                onPressed: onEdit,
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildScoreItem(
                        "CC (10%)",
                        attendanceScore,
                        Colors.purple,
                      ),
                      _buildScoreItem(
                        "GK (15%)",
                        student.midtermScore,
                        Colors.orange,
                      ),
                      _buildScoreItem(
                        "CK (15%)",
                        student.finalScore,
                        Colors.blue,
                      ),
                      _buildScoreItem(
                        "Thi (60%)",
                        student.examScore,
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Tổng kết: ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          total.toStringAsFixed(2),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, double? score, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        Text(
          score?.toString() ?? "-",
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
