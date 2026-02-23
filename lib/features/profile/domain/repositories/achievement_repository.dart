import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/achievement_entity.dart';

abstract class AchievementRepository {
  Future<Either<Failure, List<AchievementEntity>>> getAchievements(int userId);
}
