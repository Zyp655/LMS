import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationDialogWidget extends StatefulWidget {
  final List<String> studentNames;
  final String? initialMessage;
  final bool isAiGenerated;
  final Function(String title, String message) onSend;

  const NotificationDialogWidget({
    super.key,
    required this.studentNames,
    this.initialMessage,
    this.isAiGenerated = false,
    required this.onSend,
  });

  @override
  State<NotificationDialogWidget> createState() =>
      _NotificationDialogWidgetState();
}

class _NotificationDialogWidgetState extends State<NotificationDialogWidget> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      _titleController.text = 'Nhắc nhở học tập';
      _messageController.text = widget.initialMessage!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardColor(context),
      title: Row(
        children: [
          if (widget.isAiGenerated)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.auto_awesome, color: AppColors.primary),
            ),
          Text(widget.isAiGenerated ? 'AI Soạn tin nhắn' : 'Gửi thông báo'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gửi đến: ${widget.studentNames.length} sinh viên',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tiêu đề',
                labelStyle: TextStyle(color: AppColors.textSecondary(context)),
                filled: true,
                fillColor: AppColors.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Nội dung',
                labelStyle: TextStyle(color: AppColors.textSecondary(context)),
                filled: true,
                fillColor: AppColors.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Hủy',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            if (_titleController.text.isNotEmpty &&
                _messageController.text.isNotEmpty) {
              Navigator.pop(context);
              widget.onSend(_titleController.text, _messageController.text);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: widget.isAiGenerated
                ? AppColors.primary
                : AppColors.accent,
          ),
          icon: Icon(
            widget.isAiGenerated ? Icons.auto_awesome : Icons.send,
            size: 18,
          ),
          label: Text(widget.isAiGenerated ? 'Gửi AI Nudge' : 'Gửi'),
        ),
      ],
    );
  }
}
