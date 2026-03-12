import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class QuizPreviewDialog extends StatelessWidget {
  final Map<String, dynamic> quizData;
  final int moduleId;

  const QuizPreviewDialog({
    super.key,
    required this.quizData,
    required this.moduleId,
  });

  @override
  Widget build(BuildContext context) {
    final quiz = quizData['quiz'] as Map<String, dynamic>;
    final questions = quizData['questions'] as List;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: AppColors.accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz['topic'] ?? 'Quiz',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${questions.length} câu hỏi • ${quiz['difficulty'] ?? 'medium'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index] as Map<String, dynamic>;
                  final options = q['options'] as List? ?? [];
                  final correctIndex = q['correctIndex'] as int? ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Câu ${index + 1}: ${q['question']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(options.length, (i) {
                            final isCorrect = i == correctIndex;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    isCorrect
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isCorrect
                                        ? AppColors.success
                                        : Colors.grey[400],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      options[i].toString(),
                                      style: TextStyle(
                                        fontWeight: isCorrect
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isCorrect
                                            ? AppColors.successDark
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (q['explanation'] != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    size: 16,
                                    color: AppColors.warningDark,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      q['explanation'].toString(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
