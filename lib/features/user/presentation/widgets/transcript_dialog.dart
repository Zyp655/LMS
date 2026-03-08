import 'package:flutter/material.dart';
import '../../../../injection_container.dart' as di;
import '../../../../core/utils/grade_calculator.dart';
import '../../../schedule/domain/enitities/schedule_entity.dart';
import '../../../schedule/domain/repositories/schedule_repository.dart';
import '../../../../core/theme/app_colors.dart';

class TranscriptDialog extends StatefulWidget {
  const TranscriptDialog({super.key});

  @override
  State<TranscriptDialog> createState() => _TranscriptDialogState();
}

class _TranscriptDialogState extends State<TranscriptDialog> {
  late Future<List<ScheduleEntity>> _transcriptFuture;

  @override
  void initState() {
    super.initState();
    _transcriptFuture = _fetchTranscript();
  }

  Future<List<ScheduleEntity>> _fetchTranscript() async {
    final repository = di.sl<ScheduleRepository>();
    final result = await repository.getSchedules();
    return result.fold((failure) => [], (schedules) {
      final Map<String, ScheduleEntity> uniqueSubjects = {};
      for (final schedule in schedules) {
        final key = schedule.classCode ?? schedule.subject;
        if (!uniqueSubjects.containsKey(key)) {
          uniqueSubjects[key] = schedule;
        }
      }
      return uniqueSubjects.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 600,
        child: Column(
          children: [
            Text(
              "Bảng Điểm",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<ScheduleEntity>>(
                future: _transcriptFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Lỗi tải dữ liệu",
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }

                  final subjects = snapshot.data ?? [];
                  if (subjects.isEmpty) {
                    return Center(
                      child: Text(
                        "Chưa có dữ liệu môn học",
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final score =
                          subject.overallScore ??
                          GradeCalculator.calculateOverallScore(
                            credits: subject.credits,
                            midtermScore: subject.midtermScore,
                            finalScore: subject.finalScore,
                            examScore: subject.examScore,
                            currentAbsences: subject.currentAbsences,
                            maxAbsences: subject.maxAbsences,
                          );

                      Color scoreColor = AppColors.success;
                      if (score != null) {
                        if (score < 4.0)
                          scoreColor = AppColors.error;
                        else if (score < 7.0)
                          scoreColor = AppColors.warning;
                      }

                      return Card(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      subject.subject,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scoreColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: scoreColor),
                                    ),
                                    child: Text(
                                      score != null ? score.toString() : "N/A",
                                      style: TextStyle(
                                        color: scoreColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildInfoChip(
                                    context,
                                    "TC: ${subject.credits}",
                                    isDarkMode,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    context,
                                    "Vắng: ${subject.currentAbsences}/${subject.maxAbsences}",
                                    isDarkMode,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (score != null)
                                Text(
                                  "GK: ${subject.midtermScore ?? '-'} | CK: ${subject.finalScore ?? '-'} | Thi: ${subject.examScore ?? '-'}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Đóng"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
        ),
      ),
    );
  }
}
