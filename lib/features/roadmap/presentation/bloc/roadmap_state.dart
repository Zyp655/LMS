import 'package:equatable/equatable.dart';

abstract class RoadmapState extends Equatable {
  const RoadmapState();

  @override
  List<Object?> get props => [];
}

class RoadmapInitial extends RoadmapState {}

class RoadmapLoading extends RoadmapState {}

class PersonalRoadmapLoaded extends RoadmapState {
  final Map<String, dynamic> roadmap;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> stats;

  const PersonalRoadmapLoaded({
    required this.roadmap,
    required this.items,
    required this.stats,
  });

  @override
  List<Object?> get props => [roadmap, items, stats];
}

class RoadmapNoData extends RoadmapState {
  final String message;
  const RoadmapNoData(this.message);

  @override
  List<Object?> get props => [message];
}

class RoadmapActionSuccess extends RoadmapState {
  final String message;
  const RoadmapActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SuggestionsLoaded extends RoadmapState {
  final List<Map<String, dynamic>> suggestions;
  const SuggestionsLoaded(this.suggestions);

  @override
  List<Object?> get props => [suggestions];
}

class RoadmapError extends RoadmapState {
  final String message;
  const RoadmapError(this.message);

  @override
  List<Object?> get props => [message];
}
