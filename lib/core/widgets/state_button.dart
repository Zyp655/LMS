import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
enum ButtonState { idle, loading, success, error }

class StateButton extends StatefulWidget {
  final String text;
  final String? successText;
  final String? errorText;
  final Future<bool> Function() onPressed;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? successColor;
  final Color? errorColor;
  final Duration successDuration;
  final bool resetAfterSuccess;

  const StateButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.successText,
    this.errorText,
    this.onSuccess,
    this.onError,
    this.width,
    this.height = 50,
    this.backgroundColor,
    this.successColor,
    this.errorColor,
    this.successDuration = const Duration(milliseconds: 1500),
    this.resetAfterSuccess = true,
  });

  @override
  State<StateButton> createState() => _StateButtonState();
}

class _StateButtonState extends State<StateButton>
    with SingleTickerProviderStateMixin {
  ButtonState _state = ButtonState.idle;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_state != ButtonState.idle) return;

    setState(() => _state = ButtonState.loading);
    _controller.forward();

    try {
      final success = await widget.onPressed();

      if (!mounted) return;

      _controller.reverse();

      if (success) {
        HapticFeedback.mediumImpact();
        setState(() => _state = ButtonState.success);
        widget.onSuccess?.call();

        if (widget.resetAfterSuccess) {
          await Future.delayed(widget.successDuration);
          if (mounted) setState(() => _state = ButtonState.idle);
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() => _state = ButtonState.error);
        widget.onError?.call();

        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) setState(() => _state = ButtonState.idle);
      }
    } catch (e) {
      if (!mounted) return;
      _controller.reverse();
      HapticFeedback.heavyImpact();
      setState(() => _state = ButtonState.error);
      widget.onError?.call();

      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) setState(() => _state = ButtonState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bgColor;
    Widget child;

    switch (_state) {
      case ButtonState.idle:
        bgColor = widget.backgroundColor ?? theme.primaryColor;
        child = Text(
          widget.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        );
        break;

      case ButtonState.loading:
        bgColor = widget.backgroundColor ?? theme.primaryColor;
        child = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        );
        break;

      case ButtonState.success:
        bgColor = widget.successColor ?? AppColors.success;
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 22),
            if (widget.successText != null) ...[
              const SizedBox(width: 8),
              Text(
                widget.successText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
        break;

      case ButtonState.error:
        bgColor = widget.errorColor ?? const Color(0xFFE53935);
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 22),
            if (widget.errorText != null) ...[
              const SizedBox(width: 8),
              Text(
                widget.errorText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
        break;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, _) => Transform.scale(
        scale: _scaleAnimation.value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: widget.width,
          height: widget.height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _state == ButtonState.idle ? _handlePress : null,
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
