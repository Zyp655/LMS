import 'package:equatable/equatable.dart';

class RoadmapProgressEntity extends Equatable {
  final String pathId;
  final int userId;
  final List<String> completedStepIds;
  final int totalSteps;
  final String? currentMilestoneTitle;
  final DateTime? startedAt;
  final DateTime? lastActivityAt;

  const RoadmapProgressEntity({
    required this.pathId,
    required this.userId,
    this.completedStepIds = const [],
    required this.totalSteps,
    this.currentMilestoneTitle,
    this.startedAt,
    this.lastActivityAt,
  });

  int get completedCount => completedStepIds.length;
  double get progressPercent =>
      totalSteps > 0 ? completedCount / totalSteps : 0;

  @override
  List<Object?> get props => [
    pathId,
    userId,
    completedStepIds,
    totalSteps,
    currentMilestoneTitle,
    startedAt,
    lastActivityAt,
  ];
}
