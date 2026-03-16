import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/course_class_entity.dart';
import '../../../../core/theme/app_colors.dart';

class CourseCard extends StatefulWidget {
  final CourseClassEntity courseClass;

  const CourseCard({super.key, required this.courseClass});

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cc = widget.courseClass;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        context.push('/courses/${cc.courseId}');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.12 : 0.08),
                blurRadius: _isPressed ? 24 : 20,
                offset: Offset(0, _isPressed ? 8 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark, cc),
                const SizedBox(height: 12),
                _buildTitle(isDark, cc),
                const SizedBox(height: 8),
                _buildDepartmentCredits(isDark, cc),
                const SizedBox(height: 12),
                _buildTeacherSchedule(isDark, cc),
                const SizedBox(height: 16),
                _buildFooter(isDark, cc),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, CourseClassEntity cc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cc.isRequired
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            cc.isRequired ? 'Bắt buộc' : 'Tự chọn',
            style: TextStyle(
              color: cc.isRequired ? AppColors.primary : AppColors.warningDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Text(
          cc.courseCode,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[500],
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'JetBrains Mono',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(bool isDark, CourseClassEntity cc) {
    return Text(
      cc.courseName,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.darkBackground,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDepartmentCredits(bool isDark, CourseClassEntity cc) {
    return Row(
      children: [
        if (cc.departmentName != null) ...[
          Icon(
            Icons.account_balance_outlined,
            size: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            cc.departmentName!,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Text('•', style: TextStyle(color: Colors.grey[400])),
          const SizedBox(width: 8),
        ],
        Icon(
          Icons.school_outlined,
          size: 14,
          color: isDark ? Colors.grey[400] : Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          '${cc.credits} tín chỉ',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherSchedule(bool isDark, CourseClassEntity cc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'GV: ${cc.teacherName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (cc.scheduleLabel != null || cc.room != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 15,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [
                      if (cc.scheduleLabel != null) cc.scheduleLabel,
                      if (cc.room != null) cc.room,
                    ].join(' • '),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark, CourseClassEntity cc) {
    return Column(
      children: [
        if (cc.isEnrolled && cc.progressPercent > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                '${cc.progressPercent.toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cc.progressPercent / 100,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Icon(
              Icons.people_outline,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              '${cc.enrolledCount}/${cc.maxStudents}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (cc.semesterName != null) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                cc.semesterName!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cc.isCompleted ? AppColors.success : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cc.isCompleted ? Icons.check_circle : Icons.play_arrow,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cc.isCompleted ? 'Hoàn thành' : 'Vào học',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
