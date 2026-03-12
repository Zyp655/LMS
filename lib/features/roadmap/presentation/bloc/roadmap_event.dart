import 'package:equatable/equatable.dart';

abstract class RoadmapEvent extends Equatable {
  const RoadmapEvent();

  @override
  List<Object?> get props => [];
}

class LoadPersonalRoadmap extends RoadmapEvent {
  final int userId;
  const LoadPersonalRoadmap({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class ResetRoadmap extends RoadmapEvent {
  final int userId;
  const ResetRoadmap({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class AddRoadmapItem extends RoadmapEvent {
  final int roadmapId;
  final int academicCourseId;
  final int userId;
  final int? semesterOrder;

  const AddRoadmapItem({
    required this.roadmapId,
    required this.academicCourseId,
    required this.userId,
    this.semesterOrder,
  });

  @override
  List<Object?> get props => [roadmapId, academicCourseId, userId];
}

class UpdateRoadmapItem extends RoadmapEvent {
  final int userId;
  final Map<String, dynamic> data;

  const UpdateRoadmapItem({required this.userId, required this.data});

  @override
  List<Object?> get props => [userId, data];
}

class RemoveRoadmapItem extends RoadmapEvent {
  final int itemId;
  final int userId;

  const RemoveRoadmapItem({required this.itemId, required this.userId});

  @override
  List<Object?> get props => [itemId, userId];
}

class LoadSuggestions extends RoadmapEvent {
  final int departmentId;
  final int? roadmapId;

  const LoadSuggestions({required this.departmentId, this.roadmapId});

  @override
  List<Object?> get props => [departmentId, roadmapId];
}
