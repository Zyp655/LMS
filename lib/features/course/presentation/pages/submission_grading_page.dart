import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SubmissionGradingPage extends StatefulWidget {
  final int submissionId;
  final String studentName;
  final String? textContent;
  final String? linkUrl;

  const SubmissionGradingPage({
    super.key,
    required this.submissionId,
    required this.studentName,
    this.textContent,
    this.linkUrl,
  });

  @override
  State<SubmissionGradingPage> createState() => _SubmissionGradingPageState();
}

class _SubmissionGradingPageState extends State<SubmissionGradingPage> {
  final _gradeController = TextEditingController();
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _gradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitGrade() async {
    final grade = double.tryParse(_gradeController.text);
    if (grade == null || grade < 0 || grade > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
                    content: Text('Vui lòng nhập điểm hợp lệ (0-10)')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context, true); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
                    content: Text('Đã chấm điểm thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chấm điểm bài tập'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitGrade,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'LƯU',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.info.withValues(alpha: 0.2),
                      child: Text(
                        widget.studentName[0].toUpperCase(),
                        style: TextStyle(color: AppColors.info),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Học viên',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          widget.studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Nội dung bài làm:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.linkUrl != null && widget.linkUrl!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.link, color: AppColors.info),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.linkUrl!,
                            style: const TextStyle(
                              color: AppColors.info,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    widget.textContent?.isNotEmpty == true
                        ? widget.textContent!
                        : '(Không có nội dung văn bản)',
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Đánh giá & Nhận xét',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _gradeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Điểm (0-10)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.score),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(flex: 2, child: SizedBox()),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Nhận xét của giáo viên',
                hintText: 'Bài làm rất tốt, tuy nhiên cần cải thiện...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
