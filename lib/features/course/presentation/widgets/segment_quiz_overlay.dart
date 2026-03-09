import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SegmentQuizOverlay extends StatefulWidget {
  final Map<String, dynamic> quizData;
  final int segmentIndex;
  final int attemptCount;
  final String segmentTimeRange;
  final void Function(int answerIndex) onAnswer;
  final VoidCallback onDismiss;

  const SegmentQuizOverlay({
    super.key,
    required this.quizData,
    required this.segmentIndex,
    required this.attemptCount,
    required this.segmentTimeRange,
    required this.onAnswer,
    required this.onDismiss,
  });

  @override
  State<SegmentQuizOverlay> createState() => _SegmentQuizOverlayState();
}

class _SegmentQuizOverlayState extends State<SegmentQuizOverlay>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  bool _answered = false;
  bool? _wasCorrect;
  String? _feedbackMessage;
  late AnimationController _animController;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedIndex == null || _answered) return;
    setState(() => _answered = true);
    widget.onAnswer(_selectedIndex!);
  }

  void updateResult({
    required bool correct,
    required String message,
    required bool shouldRewind,
  }) {
    if (!mounted) return;
    setState(() {
      _wasCorrect = correct;
      _feedbackMessage = message;
    });
    if (correct) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) widget.onDismiss();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = AppColors.isDark(context);
    final question = widget.quizData['question'] as String? ?? '';
    final options =
        (widget.quizData['options'] as List<dynamic>?)?.cast<String>() ?? [];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnim),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    const Color(0xFF111B2E).withValues(alpha: 0.98),
                    const Color(0xFF172338).withValues(alpha: 0.98),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isDark ? null : Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.quiz, size: 16, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Phân đoạn ${widget.segmentIndex + 1}',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.segmentTimeRange,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                question,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(options.length, (i) {
                final isSelected = _selectedIndex == i;
                final labels = ['A', 'B', 'C', 'D'];

                Color borderColor = cs.outline.withValues(alpha: 0.3);
                Color bgColor = Colors.transparent;
                if (_answered && _wasCorrect != null) {
                  final correctIdx =
                      widget.quizData['correctIndex'] as int? ?? 0;
                  if (i == correctIdx) {
                    borderColor = AppColors.success;
                    bgColor = AppColors.success.withValues(alpha: 0.1);
                  } else if (i == _selectedIndex && !_wasCorrect!) {
                    borderColor = AppColors.error;
                    bgColor = AppColors.error.withValues(alpha: 0.1);
                  }
                } else if (isSelected) {
                  borderColor = AppColors.accent;
                  bgColor = AppColors.accent.withValues(alpha: 0.08);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: _answered
                        ? null
                        : () => setState(() => _selectedIndex = i),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.accent.withValues(alpha: 0.15)
                                  : cs.surfaceContainerHighest,
                            ),
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected
                                    ? AppColors.accent
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              options[i],
                              style: TextStyle(
                                fontSize: 14,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (_feedbackMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        (_wasCorrect == true
                                ? AppColors.success
                                : AppColors.error)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          (_wasCorrect == true
                                  ? AppColors.success
                                  : AppColors.error)
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _wasCorrect == true
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        size: 18,
                        color: _wasCorrect == true
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _feedbackMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _wasCorrect == true
                                ? AppColors.success
                                : AppColors.error,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!_answered)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedIndex != null ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Xác nhận',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              if (_answered && _wasCorrect == false) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = null;
                        _answered = false;
                        _wasCorrect = null;
                        _feedbackMessage = null;
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
