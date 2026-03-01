import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';


class AnimatedSuccessIcon extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final Duration autoHideDuration;
  final VoidCallback? onComplete;

  const AnimatedSuccessIcon({
    super.key,
    this.size = 80,
    this.color = AppColors.success,
    this.duration = const Duration(milliseconds: 600),
    this.autoHideDuration = const Duration(milliseconds: 1800),
    this.onComplete,
  });

  static void show(
    BuildContext context, {
    Duration duration = const Duration(milliseconds: 1800),
    VoidCallback? onComplete,
  }) {
    final overlay = OverlayEntry(
      builder: (context) => Center(
        child: AnimatedSuccessIcon(
          autoHideDuration: duration,
          onComplete: onComplete,
        ),
      ),
    );

    Overlay.of(context).insert(overlay);

    Future.delayed(duration, () {
      overlay.remove();
      onComplete?.call();
    });
  }

  @override
  State<AnimatedSuccessIcon> createState() => _AnimatedSuccessIconState();
}

class _AnimatedSuccessIconState extends State<AnimatedSuccessIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _circleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    HapticFeedback.mediumImpact();

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _CheckmarkPainter(
              circleProgress: _circleAnimation.value,
              checkProgress: _checkAnimation.value,
              color: widget.color,
              strokeWidth: widget.size / 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color color;
  final double strokeWidth;

  _CheckmarkPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * circleProgress,
      false,
      circlePaint,
    );

    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final checkPath = Path();

      final startX = size.width * 0.28;
      final startY = size.height * 0.52;
      final midX = size.width * 0.45;
      final midY = size.height * 0.68;
      final endX = size.width * 0.72;
      final endY = size.height * 0.35;

      checkPath.moveTo(startX, startY);

      if (checkProgress <= 0.5) {
        final t = checkProgress * 2;
        checkPath.lineTo(
          startX + (midX - startX) * t,
          startY + (midY - startY) * t,
        );
      } else {
        checkPath.lineTo(midX, midY);
        final t = (checkProgress - 0.5) * 2;
        checkPath.lineTo(midX + (endX - midX) * t, midY + (endY - midY) * t);
      }

      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return circleProgress != oldDelegate.circleProgress ||
        checkProgress != oldDelegate.checkProgress;
  }
}
