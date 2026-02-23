import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/achievement_entity.dart';
import '../repositories/achievement_repository.dart';

class GetAchievementsUseCase {
  final AchievementRepository repository;

  GetAchievementsUseCase(this.repository);

  Future<Either<Failure, List<AchievementEntity>>> call(int userId) {
    return repository.getAchievements(userId);
  }
}
