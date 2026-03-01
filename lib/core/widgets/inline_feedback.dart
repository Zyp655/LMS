import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class InlineFeedback extends StatefulWidget {
  final FeedbackType type;
  final String message;
  final bool autoHide;
  final Duration duration;
  final VoidCallback? onDismiss;

  const InlineFeedback({
    super.key,
    required this.type,
    required this.message,
    this.autoHide = true,
    this.duration = const Duration(milliseconds: 3000),
    this.onDismiss,
  });

  factory InlineFeedback.success({
    required String message,
    bool autoHide = true,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    return InlineFeedback(
      type: FeedbackType.success,
      message: message,
      autoHide: autoHide,
      duration: duration,
    );
  }

  factory InlineFeedback.error({
    required String message,
    bool autoHide = true,
    Duration duration = const Duration(milliseconds: 4000),
  }) {
    return InlineFeedback(
      type: FeedbackType.error,
      message: message,
      autoHide: autoHide,
      duration: duration,
    );
  }

  factory InlineFeedback.info({
    required String message,
    bool autoHide = true,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    return InlineFeedback(
      type: FeedbackType.info,
      message: message,
      autoHide: autoHide,
      duration: duration,
    );
  }

  @override
  State<InlineFeedback> createState() => _InlineFeedbackState();
}

enum FeedbackType { success, error, info, warning }

class _InlineFeedbackState extends State<InlineFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    if (widget.autoHide) {
      Future.delayed(widget.duration, () {
        if (mounted) {
          _controller.reverse().then((_) {
            widget.onDismiss?.call();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(widget.type);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: config.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(config.icon, color: config.iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    color: config.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!widget.autoHide)
                GestureDetector(
                  onTap: () {
                    _controller.reverse().then((_) {
                      widget.onDismiss?.call();
                    });
                  },
                  child: Icon(
                    Icons.close,
                    color: config.iconColor.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _FeedbackConfig _getConfig(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return _FeedbackConfig(
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          borderColor: const Color(0xFFA5D6A7),
          iconColor: AppColors.success,
          textColor: AppColors.successDark,
          icon: Icons.check_circle_rounded,
        );
      case FeedbackType.error:
        return _FeedbackConfig(
          backgroundColor: const Color(0xFFFFEBEE),
          borderColor: const Color(0xFFEF9A9A),
          iconColor: const Color(0xFFE53935),
          textColor: const Color(0xFFC62828),
          icon: Icons.error_rounded,
        );
      case FeedbackType.info:
        return _FeedbackConfig(
          backgroundColor: const Color(0xFFE3F2FD),
          borderColor: const Color(0xFF90CAF9),
          iconColor: AppColors.info,
          textColor: const Color(0xFF1565C0),
          icon: Icons.info_rounded,
        );
      case FeedbackType.warning:
        return _FeedbackConfig(
          backgroundColor: AppColors.warning.withValues(alpha: 0.1),
          borderColor: const Color(0xFFFFCC80),
          iconColor: AppColors.warning,
          textColor: AppColors.accent,
          icon: Icons.warning_rounded,
        );
    }
  }
}

class _FeedbackConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  _FeedbackConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}
