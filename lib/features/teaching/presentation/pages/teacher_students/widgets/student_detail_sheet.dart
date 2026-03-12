import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';

class StudentDetailSheet extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onSendNotification;
  final VoidCallback onViewHistory;
  final String Function(String?) formatTime;

  const StudentDetailSheet({
    super.key,
    required this.student,
    required this.onSendNotification,
    required this.onViewHistory,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    const primaryOrange = AppColors.accent;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryOrange.withAlpha(50),
                  child: Text(
                    (student['fullName'] as String? ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: primaryOrange,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['fullName'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        student['email'] ?? '',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Đăng ký', formatTime(student['enrolledAt'])),
            _buildDetailRow('Tiến độ', '${student['progressPercent']}%'),
            _buildDetailRow(
              'Bài học',
              '${student['completedLessons']}/${student['totalLessons']}',
            ),
            _buildDetailRow(
              'Điểm Quiz TB',
              student['quizAverage'] != null
                  ? '${(student['quizAverage'] as num).toStringAsFixed(1)}%'
                  : 'Chưa làm',
            ),
            _buildDetailRow(
              'Truy cập cuối',
              formatTime(student['lastAccessedAt']),
            ),
            if (student['isAtRisk'] == true)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Học viên này đã vắng ${student['daysInactive']} ngày. Cần nhắc nhở ngay!',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onSendNotification();
                    },
                    icon: Icon(Icons.notifications_outlined),
                    label: const Text('Gửi thông báo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryOrange,
                      side: BorderSide(color: primaryOrange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onViewHistory();
                    },
                    icon: Icon(Icons.history),
                    label: const Text('Lịch sử'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400])),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
