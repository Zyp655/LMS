import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';


class GlassSnackbar {
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 2500),
    SnackbarPosition position = SnackbarPosition.bottom,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      duration: duration,
      position: position,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 2500),
    SnackbarPosition position = SnackbarPosition.bottom,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info_rounded,
      iconColor: AppColors.info,
      duration: duration,
      position: position,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 2500),
    SnackbarPosition position = SnackbarPosition.bottom,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.warning_rounded,
      iconColor: AppColors.warning,
      duration: duration,
      position: position,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 3000),
    SnackbarPosition position = SnackbarPosition.bottom,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error_rounded,
      iconColor: const Color(0xFFE53935),
      duration: duration,
      position: position,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Duration duration,
    required SnackbarPosition position,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _GlassSnackbarWidget(
        message: message,
        icon: icon,
        iconColor: iconColor,
        duration: duration,
        position: position,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

enum SnackbarPosition { top, bottom }

class _GlassSnackbarWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final Duration duration;
  final SnackbarPosition position;
  final VoidCallback onDismiss;

  const _GlassSnackbarWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.duration,
    required this.position,
    required this.onDismiss,
  });

  @override
  State<_GlassSnackbarWidget> createState() => _GlassSnackbarWidgetState();
}

class _GlassSnackbarWidgetState extends State<_GlassSnackbarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    final beginOffset = widget.position == SnackbarPosition.top
        ? const Offset(0, -1)
        : const Offset(0, 1);

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: widget.position == SnackbarPosition.top
          ? mediaQuery.padding.top + 16
          : null,
      bottom: widget.position == SnackbarPosition.bottom
          ? mediaQuery.padding.bottom + 16
          : null,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.iconColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _controller.reverse().then((_) {
                          widget.onDismiss();
                        });
                      },
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
