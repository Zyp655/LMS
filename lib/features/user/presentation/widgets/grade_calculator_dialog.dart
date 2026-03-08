import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class GradeCalculatorDialog extends StatefulWidget {
  const GradeCalculatorDialog({super.key});

  @override
  State<GradeCalculatorDialog> createState() => _GradeCalculatorDialogState();
}

class _GradeCalculatorDialogState extends State<GradeCalculatorDialog> {
  final _formKey = GlobalKey<FormState>();

  final _attendanceController = TextEditingController();
  final _midtermController = TextEditingController();
  final _finalExamController = TextEditingController();
  final _examController = TextEditingController();

  int _credits = 3;
  double? _totalScore;
  String? _grade;

  @override
  void dispose() {
    _attendanceController.dispose();
    _midtermController.dispose();
    _finalExamController.dispose();
    _examController.dispose();
    super.dispose();
  }

  void _calculateScore() {
    if (!_formKey.currentState!.validate()) return;

    final attendance = double.tryParse(_attendanceController.text) ?? 0;
    final midterm = double.tryParse(_midtermController.text) ?? 0;
    final finalExam = double.tryParse(_finalExamController.text) ?? 0;
    final exam = double.tryParse(_examController.text) ?? 0;

    double total;

    if (_credits > 2) {
      total =
          (attendance * 0.1) +
          (midterm * 0.15) +
          (finalExam * 0.15) +
          (exam * 0.6);
    } else {
      total = (attendance * 0.1) + (finalExam * 0.3) + (exam * 0.6);
    }

    setState(() {
      _totalScore = double.parse(total.toStringAsFixed(2));
      _grade = _getLetterGrade(_totalScore!);
    });
  }

  String _getLetterGrade(double score) {
    if (score >= 9.0) return 'A+';
    if (score >= 8.5) return 'A';
    if (score >= 8.0) return 'B+';
    if (score >= 7.0) return 'B';
    if (score >= 6.5) return 'C+';
    if (score >= 5.5) return 'C';
    if (score >= 5.0) return 'D+';
    if (score >= 4.0) return 'D';
    return 'F';
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.5) return Colors.blue;
    if (score >= 5.0) return Colors.orange;
    return Colors.red;
  }

  void _resetForm() {
    _attendanceController.clear();
    _midtermController.clear();
    _finalExamController.clear();
    _examController.clear();
    setState(() {
      _totalScore = null;
      _grade = null;
    });
  }

  String? _validateScore(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập điểm';
    }
    final score = double.tryParse(value);
    if (score == null) {
      return 'Điểm không hợp lệ';
    }
    if (score < 0 || score > 10) {
      return 'Điểm phải từ 0-10';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.grey[50];

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 350,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tính Điểm Môn Học",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: textColor),
                      onPressed: _resetForm,
                      tooltip: 'Làm mới',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Số tín chỉ:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _credits = 2;
                                  _totalScore = null;
                                  _grade = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _credits == 2
                                      ? Colors.blueAccent
                                      : (isDarkMode
                                            ? Colors.grey[700]
                                            : Colors.grey[200]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '2 Tín chỉ',
                                    style: TextStyle(
                                      color: _credits == 2
                                          ? Colors.white
                                          : textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _credits = 3;
                                  _totalScore = null;
                                  _grade = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _credits > 2
                                      ? Colors.blueAccent
                                      : (isDarkMode
                                            ? Colors.grey[700]
                                            : Colors.grey[200]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '> 2 Tín chỉ',
                                    style: TextStyle(
                                      color: _credits > 2
                                          ? Colors.white
                                          : textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Công thức tính:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _credits > 2
                            ? 'Chuyên cần (10%) + GK (15%) + CK (15%) + Hết môn (60%)'
                            : 'Chuyên cần (10%) + CK (30%) + Hết môn (60%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _buildInputField(
                  controller: _attendanceController,
                  label: 'Điểm chuyên cần',
                  hint: 'Nhập điểm (0-10)',
                  icon: Icons.event_available,
                  percentage: '10%',
                  isDarkMode: isDarkMode,
                  textColor: textColor,
                ),
                const SizedBox(height: 12),

                if (_credits > 2) ...[
                  _buildInputField(
                    controller: _midtermController,
                    label: 'Điểm giữa kỳ (GK)',
                    hint: 'Nhập điểm (0-10)',
                    icon: Icons.assignment,
                    percentage: '15%',
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 12),
                ],

                _buildInputField(
                  controller: _finalExamController,
                  label: 'Điểm cuối kỳ (CK)',
                  hint: 'Nhập điểm (0-10)',
                  icon: Icons.quiz,
                  percentage: _credits > 2 ? '15%' : '30%',
                  isDarkMode: isDarkMode,
                  textColor: textColor,
                ),
                const SizedBox(height: 12),

                _buildInputField(
                  controller: _examController,
                  label: 'Điểm hết môn',
                  hint: 'Nhập điểm (0-10)',
                  icon: Icons.grade,
                  percentage: '60%',
                  isDarkMode: isDarkMode,
                  textColor: textColor,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _calculateScore,
                    icon: Icon(Icons.calculate),
                    label: const Text('Tính Điểm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                if (_totalScore != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getScoreColor(_totalScore!).withValues(alpha: 0.1),
                          _getScoreColor(_totalScore!).withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getScoreColor(_totalScore!).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Điểm Tổng Kết',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _totalScore!.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(_totalScore!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getScoreColor(_totalScore!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _grade!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getGradeDescription(_totalScore!),
                          style: TextStyle(
                            fontSize: 13,
                            color: _getScoreColor(_totalScore!),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: textColor.withValues(alpha: 0.7),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String percentage,
    required bool isDarkMode,
    required Color textColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: _validateScore,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.info),
        suffixText: percentage,
        suffixStyle: TextStyle(
          color: AppColors.info,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.info, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  String _getGradeDescription(double score) {
    if (score >= 9.0) return 'Xuất sắc';
    if (score >= 8.5) return 'Giỏi';
    if (score >= 8.0) return 'Khá giỏi';
    if (score >= 7.0) return 'Khá';
    if (score >= 6.5) return 'Trung bình khá';
    if (score >= 5.5) return 'Trung bình';
    if (score >= 5.0) return 'Trung bình yếu';
    if (score >= 4.0) return 'Yếu';
    return 'Không đạt';
  }
}
