import 'package:equatable/equatable.dart';
import '../../domain/entities/achievement_entity.dart';

abstract class AchievementState extends Equatable {
  const AchievementState();

  @override
  List<Object?> get props => [];
}

class AchievementInitial extends AchievementState {}

class AchievementLoading extends AchievementState {}

class AchievementsLoaded extends AchievementState {
  final List<AchievementEntity> achievements;
  final int totalPoints;
  final int earnedCount;

  AchievementsLoaded(this.achievements)
    : totalPoints = achievements
          .where((a) => a.earned)
          .fold<int>(0, (sum, a) => sum + a.points),
      earnedCount = achievements.where((a) => a.earned).length;

  @override
  List<Object?> get props => [achievements];
}

class AchievementError extends AchievementState {
  final String message;

  const AchievementError(this.message);

  @override
  List<Object?> get props => [message];
}
