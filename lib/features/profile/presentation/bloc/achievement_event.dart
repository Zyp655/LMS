import 'package:equatable/equatable.dart';

abstract class AchievementEvent extends Equatable {
  const AchievementEvent();

  @override
  List<Object?> get props => [];
}

class LoadAchievements extends AchievementEvent {
  final int userId;

  const LoadAchievements(this.userId);

  @override
  List<Object?> get props => [userId];
}
