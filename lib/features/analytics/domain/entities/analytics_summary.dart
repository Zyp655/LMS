import 'package:equatable/equatable.dart';

class AnalyticsSummary extends Equatable {
  final int currentStreak;
  final int longestStreak;
  final int weekStudyMinutes;
  final int todayStudyMinutes;
  final int weekCompletedLessons;
  final int activeCourses;
  final double overallProgress;
  final int completedLessons;
  final int todayActivities;

  const AnalyticsSummary({
    required this.currentStreak,
    required this.longestStreak,
    required this.weekStudyMinutes,
    this.todayStudyMinutes = 0,
    this.weekCompletedLessons = 0,
    required this.activeCourses,
    required this.overallProgress,
    required this.completedLessons,
    required this.todayActivities,
  });

  String get weekStudyTimeFormatted {
    final hours = weekStudyMinutes ~/ 60;
    final mins = weekStudyMinutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  @override
  List<Object?> get props => [
    currentStreak,
    longestStreak,
    weekStudyMinutes,
    todayStudyMinutes,
    weekCompletedLessons,
    activeCourses,
    overallProgress,
    completedLessons,
    todayActivities,
  ];
}
