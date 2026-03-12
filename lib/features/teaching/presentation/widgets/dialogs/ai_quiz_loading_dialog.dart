import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/services/content_analyzer_service.dart';
import 'ai_quiz_editor_dialog.dart';
import '../../../../../core/theme/app_colors.dart';

class AIQuizLoadingDialog extends StatefulWidget {
  final int moduleId;
  const AIQuizLoadingDialog({super.key, required this.moduleId});

  @override
  State<AIQuizLoadingDialog> createState() => _AIQuizLoadingDialogState();
}

class _AIQuizLoadingDialogState extends State<AIQuizLoadingDialog> {
  String _status = 'Đang kết nối AI...';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSimulation();
    _callAPI();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    int step = 0;
    _timer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (!mounted) return;
      setState(() {
        step++;
        if (step == 1)
          _status = 'Đang đọc nội dung bài học (RAG)...';
        else if (step == 2)
          _status = 'Phân tích ngữ nghĩa & Case studies...';
        else if (step == 3)
          _status = 'Đang soạn câu hỏi trắc nghiệm...';
        else if (step == 4)
          _status = 'Tạo giải thích chi tiết (Feedback)...';
        else if (step == 5)
          _status = 'Hoàn tất...';
      });
    });
  }

  Future<void> _callAPI() async {
    try {
      final analyzer = ContentAnalyzerService();
      final result = await analyzer.generateQuizForModule(
        moduleId: widget.moduleId,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result != null && result['questions'] != null) {
        final questions = result['questions'] as List;
        if (questions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không tạo được câu hỏi. Hãy thêm nội dung cho bài học.',
              ),
            ),
          );
          return;
        }
        final saved = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              AIQuizEditorDialog(data: result, moduleId: widget.moduleId),
        );
        if (context.mounted && saved == true) {
          Navigator.of(context, rootNavigator: true).pop(true);
        }
      } else {
        final errorMsg =
            result?['error'] as String? ??
            'Không thể tạo quiz. Hãy thêm bài học có nội dung trước.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 24),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
