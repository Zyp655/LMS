import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class GradeSubmissionDialog extends StatefulWidget {
  final String studentName;
  final int submissionId;
  final Function(double grade, String? feedback) onGrade;

  const GradeSubmissionDialog({
    Key? key,
    required this.studentName,
    required this.submissionId,
    required this.onGrade,
  }) : super(key: key);

  @override
  State<GradeSubmissionDialog> createState() => _GradeSubmissionDialogState();
}

class _GradeSubmissionDialogState extends State<GradeSubmissionDialog> {
  final _gradeController = TextEditingController();
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _gradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final grade = double.parse(_gradeController.text);
      final feedback = _feedbackController.text.trim().isEmpty
          ? null
          : _feedbackController.text.trim();

      await widget.onGrade(grade, feedback);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                    content: Text('Đã lưu điểm thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.grade, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chấm điểm',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sinh viên: ${widget.studentName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gradeController,
                decoration: InputDecoration(
                  labelText: 'Điểm *',
                  hintText: '0.0 - 10.0',
                  prefixIcon: Icon(Icons.star),
                  border: OutlineInputBorder(),
                  helperText: 'Nhập điểm từ 0 đến 10',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập điểm';
                  }
                  final grade = double.tryParse(value);
                  if (grade == null) {
                    return 'Điểm phải là số';
                  }
                  if (grade < 0 || grade > 10) {
                    return 'Điểm phải từ 0 đến 10';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _feedbackController,
                decoration: InputDecoration(
                  labelText: 'Nhận xét (tùy chọn)',
                  hintText: 'Viết nhận xét cho sinh viên...',
                  prefixIcon: Icon(Icons.comment),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.save),
          label: const Text('Lưu Điểm'),
        ),
      ],
    );
  }
}
