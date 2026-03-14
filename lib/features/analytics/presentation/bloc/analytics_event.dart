import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnalyticsDashboard extends AnalyticsEvent {
  final int userId;
  final int heatmapMonths;

  const LoadAnalyticsDashboard({
    required this.userId,
    this.heatmapMonths = 6,
  });

  @override
  List<Object?> get props => [userId, heatmapMonths];
}

class LoadVelocity extends AnalyticsEvent {
  final int userId;
  final int courseId;

  const LoadVelocity({required this.userId, required this.courseId});

  @override
  List<Object?> get props => [userId, courseId];
}

class LoadBenchmark extends AnalyticsEvent {
  final int userId;
  final int courseId;

  const LoadBenchmark({required this.userId, required this.courseId});

  @override
  List<Object?> get props => [userId, courseId];
}

class TrackActivity extends AnalyticsEvent {
  final int userId;
  final String activityType;
  final int? courseId;
  final int? lessonId;
  final int durationMinutes;

  const TrackActivity({
    required this.userId,
    required this.activityType,
    this.courseId,
    this.lessonId,
    this.durationMinutes = 0,
  });

  @override
  List<Object?> get props => [
    userId,
    activityType,
    courseId,
    lessonId,
    durationMinutes,
  ];
}
