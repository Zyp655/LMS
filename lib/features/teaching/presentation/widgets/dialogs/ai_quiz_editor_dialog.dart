import 'package:flutter/material.dart';
import '../../../../../core/services/content_analyzer_service.dart';
import '../../../../../core/theme/app_colors.dart';

class AIQuizEditorDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final int moduleId;
  const AIQuizEditorDialog({
    super.key,
    required this.data,
    required this.moduleId,
  });

  @override
  State<AIQuizEditorDialog> createState() => _AIQuizEditorDialogState();
}

class _AIQuizEditorDialogState extends State<AIQuizEditorDialog> {
  bool _isSaving = false;
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List<Map<String, dynamic>>.from(
      (widget.data['questions'] as List).map(
        (q) => Map<String, dynamic>.from(q),
      ),
    );
  }

  void _updateQuestion(int index, String key, dynamic value) {
    setState(() {
      _questions[index][key] = value;
    });
  }

  Future<void> _saveQuizToServer() async {
    setState(() => _isSaving = true);

    try {
      final service = ContentAnalyzerService();
      final result = await service.saveQuizForModule(
        moduleId: widget.moduleId,
        questions: _questions,
        topic: widget.data['topic'] as String? ?? 'Quiz',
        difficulty: widget.data['difficulty'] as String? ?? 'medium',
      );

      if (!mounted) return;

      if (result != null && result['success'] == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                    content: Text('Đã lưu bài Quiz thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                    content: Text('Không thể lưu quiz. Vui lòng thử lại.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showEditQuestionDialog(int index) {
    final q = _questions[index];
    final questionController = TextEditingController(text: q['question']);
    final explanationController = TextEditingController(text: q['explanation']);
    final optionControllers = (q['options'] as List)
        .map((o) => TextEditingController(text: o.toString()))
        .toList();
    int correctIndex = q['correctIndex'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Chỉnh sửa câu ${index + 1}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    decoration: InputDecoration(
                      labelText: 'Câu hỏi',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Các lựa chọn (Chọn đáp án đúng):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(4, (i) {
                    return RadioListTile<int>(
                      title: TextField(
                        controller: optionControllers[i],
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.all(8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      value: i,
                      groupValue: correctIndex,
                      onChanged: (val) =>
                          setDialogState(() => correctIndex = val!),
                      activeColor: AppColors.accent,
                    );
                  }),
                  const SizedBox(height: 16),
                  TextField(
                    controller: explanationController,
                    decoration: InputDecoration(
                      labelText: 'Giải thích đáp án',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Hủy'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: const Text('Lưu thay đổi'),
                onPressed: () {
                  _updateQuestion(index, 'question', questionController.text);
                  _updateQuestion(
                    index,
                    'explanation',
                    explanationController.text,
                  );
                  _updateQuestion(
                    index,
                    'options',
                    optionControllers.map((c) => c.text).toList(),
                  );
                  _updateQuestion(index, 'correctIndex', correctIndex);
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.accent, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Review & Chỉnh sửa Quiz',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Câu ${index + 1}: ${q['question']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: AppColors.accent,
                                ),
                                onPressed: () => _showEditQuestionDialog(index),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.generate((q['options'] as List).length, (i) {
                            final isCorrect = i == q['correctIndex'];
                            return _buildAnswerOption(
                              q['options'][i],
                              isCorrect,
                            );
                          }),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.warningLight,
                              ),
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
                                    'Giải thích: ${q['explanation']}',
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
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveQuizToServer,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.save),
                label: Text(_isSaving ? 'Đang lưu...' : 'Xác nhận & Lưu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOption(String text, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCorrect ? AppColors.success : Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                color: isCorrect ? AppColors.successDark : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
