import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class SeedAchievementsUseCase {
  final AdminRepository repository;
  SeedAchievementsUseCase(this.repository);

  Future<Either<Failure, String>> call() => repository.seedAchievements();
}
