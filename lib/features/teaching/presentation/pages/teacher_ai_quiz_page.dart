import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_constants.dart';
import '../../../../core/theme/app_colors.dart';

class TeacherAiQuizPage extends StatefulWidget {
  final int courseId;

  const TeacherAiQuizPage({super.key, required this.courseId});

  @override
  State<TeacherAiQuizPage> createState() => _TeacherAiQuizPageState();
}

class _TeacherAiQuizPageState extends State<TeacherAiQuizPage> {
  int _step = 0;
  final _contentController = TextEditingController();
  int _numQuestions = 10;
  String _difficulty = 'medium';
  String _quizTitle = '';
  bool _isGenerating = false;
  List<Map<String, dynamic>> _draftQuestions = [];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _generateQuiz() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung tài liệu')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/teacher/generate-quiz-from-file'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fileContent': _contentController.text,
          'numQuestions': _numQuestions,
          'difficulty': _difficulty,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final questions = (data['questions'] as List).map((q) {
          final m = Map<String, dynamic>.from(q as Map);
          m['_editing'] = false;
          return m;
        }).toList();

        setState(() {
          _draftQuestions = questions;
          _step = 1;
          _isGenerating = false;
        });
      } else {
        final err = jsonDecode(response.body);
        setState(() => _isGenerating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err['error'] ?? 'Lỗi')),
          );
        }
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi kết nối')),
        );
      }
    }
  }

  Future<void> _publishQuiz() async {
    if (_quizTitle.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên quiz')),
      );
      return;
    }

    if (_draftQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 1 câu hỏi')),
      );
      return;
    }

    try {
      final quizQuestions = _draftQuestions.map((q) {
        final options = (q['options'] as List).cast<String>();
        final correctIdx = q['correctIndex'] as int? ?? 0;
        return {
          'question': q['question'],
          'options': options,
          'correctAnswer': options[correctIdx],
          'explanation': q['explanation'] ?? '',
        };
      }).toList();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/quiz/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': 0,
          'courseId': widget.courseId,
          'title': _quizTitle,
          'topic': _quizTitle,
          'difficulty': _difficulty,
          'isPublic': true,
          'questions': quizQuestions,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Quiz đã được lưu thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi lưu quiz')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi kết nối')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(_step == 0 ? '📄 Import Nội dung' : '📝 Duyệt Quiz'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_step == 1)
            TextButton.icon(
              onPressed: () {
                setState(() => _step = 0);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Quay lại'),
            ),
        ],
      ),
      body: _step == 0
          ? _buildImportStep(cs, isDark)
          : _buildDraftReviewStep(cs, isDark),
    );
  }

  Widget _buildImportStep(ColorScheme cs, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Quiz Generator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Paste nội dung tài liệu → AI tạo quiz → Bạn duyệt & chỉnh sửa',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nội dung tài liệu',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: TextField(
              controller: _contentController,
              maxLines: 10,
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Paste nội dung bài giảng, sách, tài liệu tại đây...',
                hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số câu: $_numQuestions',
                      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: _numQuestions.toDouble(),
                      min: 3,
                      max: 20,
                      divisions: 17,
                      activeColor: AppColors.primary,
                      label: '$_numQuestions',
                      onChanged: (v) => setState(() => _numQuestions = v.round()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Độ khó',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDiffChip('easy', 'Dễ', AppColors.success, isDark),
              const SizedBox(width: 8),
              _buildDiffChip('medium', 'TB', AppColors.warning, isDark),
              const SizedBox(width: 8),
              _buildDiffChip('hard', 'Khó', AppColors.error, isDark),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isGenerating ? null : _generateQuiz,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'Đang tạo quiz...' : 'Tạo Quiz AI',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffChip(String value, String label, Color color, bool isDark) {
    final selected = _difficulty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : (isDark ? Colors.grey[800] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraftReviewStep(ColorScheme cs, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          color: isDark ? AppColors.darkSurface : Colors.white,
          child: Column(
            children: [
              TextField(
                onChanged: (v) => _quizTitle = v,
                style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Nhập tên Quiz...',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.quiz),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_draftQuestions.length} câu hỏi',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addManualQuestion,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm câu'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _publishQuiz,
                    icon: const Icon(Icons.publish, size: 18),
                    label: const Text('Lưu Quiz'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _draftQuestions.length,
            itemBuilder: (_, i) => _buildQuestionCard(cs, isDark, i),
          ),
        ),
      ],
    );
  }

  void _addManualQuestion() {
    setState(() {
      _draftQuestions.add({
        'question': '',
        'options': ['A. ', 'B. ', 'C. ', 'D. '],
        'correctIndex': 0,
        'explanation': '',
        'difficulty': _difficulty,
        '_editing': true,
      });
    });
  }

  Widget _buildQuestionCard(ColorScheme cs, bool isDark, int index) {
    final q = _draftQuestions[index];
    final isEditing = q['_editing'] == true;
    final correctIdx = q['correctIndex'] as int? ?? 0;
    final options = (q['options'] as List).cast<String>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Câu ${index + 1}',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isEditing ? Icons.check_circle : Icons.edit,
                    color: isEditing ? AppColors.success : cs.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => q['_editing'] = !isEditing);
                  },
                  tooltip: isEditing ? 'Xong' : 'Sửa',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () {
                    setState(() => _draftQuestions.removeAt(index));
                  },
                  tooltip: 'Xóa',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEditing)
                  TextFormField(
                    initialValue: q['question'] as String? ?? '',
                    style: TextStyle(color: cs.onSurface, fontSize: 14),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Câu hỏi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (v) => q['question'] = v,
                  )
                else
                  Text(
                    q['question'] as String? ?? '',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 12),
                ...List.generate(options.length, (oi) {
                  final isCorrect = oi == correctIdx;
                  if (isEditing) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: oi,
                            groupValue: correctIdx,
                            onChanged: (v) {
                              setState(() => q['correctIndex'] = v);
                            },
                            activeColor: AppColors.success,
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: options[oi],
                              style: TextStyle(color: cs.onSurface, fontSize: 13),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (v) {
                                options[oi] = v;
                                q['options'] = options;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.success.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCorrect
                              ? AppColors.success.withValues(alpha: 0.4)
                              : cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isCorrect)
                            const Icon(Icons.check_circle, color: AppColors.success, size: 16)
                          else
                            Icon(Icons.circle_outlined, color: cs.onSurfaceVariant, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              options[oi],
                              style: TextStyle(
                                color: isCorrect ? AppColors.success : cs.onSurface,
                                fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }),
                if ((q['explanation'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  if (isEditing)
                    TextFormField(
                      initialValue: q['explanation'] as String? ?? '',
                      style: TextStyle(color: cs.onSurface, fontSize: 13),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Giải thích',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (v) => q['explanation'] = v,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, color: AppColors.info, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              q['explanation'] as String,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
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
        ],
      ),
    );
  }
}
