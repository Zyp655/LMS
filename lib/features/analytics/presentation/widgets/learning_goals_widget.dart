import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LearningGoalsWidget extends StatelessWidget {
  final double dailyMinutesTarget;
  final double dailyMinutesActual;
  final int weeklyLessonsTarget;
  final int weeklyLessonsActual;
  final int currentStreak;

  const LearningGoalsWidget({
    super.key,
    this.dailyMinutesTarget = 30,
    this.dailyMinutesActual = 0,
    this.weeklyLessonsTarget = 3,
    this.weeklyLessonsActual = 0,
    this.currentStreak = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkBackground : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkBackground;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Mục tiêu học tập',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (currentStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.error, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('ðŸ”¥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$currentStreak ngày',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _GoalRing(
                  progress: dailyMinutesTarget > 0
                      ? (dailyMinutesActual / dailyMinutesTarget).clamp(
                          0.0,
                          1.0,
                        )
                      : 0.0,
                  color: AppColors.primary,
                  label: 'Hôm nay',
                  value:
                      '${dailyMinutesActual.toInt()}/${dailyMinutesTarget.toInt()}',
                  unit: 'phút',
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GoalRing(
                  progress: weeklyLessonsTarget > 0
                      ? (weeklyLessonsActual / weeklyLessonsTarget).clamp(
                          0.0,
                          1.0,
                        )
                      : 0.0,
                  color: AppColors.accent,
                  label: 'Tuần này',
                  value: '$weeklyLessonsActual/$weeklyLessonsTarget',
                  unit: 'bài học',
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalRing extends StatefulWidget {
  final double progress;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final Color textColor;
  final Color subTextColor;

  const _GoalRing({
    required this.progress,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  State<_GoalRing> createState() => _GoalRingState();
}

class _GoalRingState extends State<_GoalRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _RingPainter(
                  progress: widget.progress * _animation.value,
                  color: widget.color,
                  bgColor: widget.color.withAlpha(30),
                ),
                child: child,
              );
            },
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.value,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.unit,
                    style: TextStyle(color: widget.subTextColor, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: TextStyle(
            color: widget.subTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    const strokeWidth = 8.0;
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
