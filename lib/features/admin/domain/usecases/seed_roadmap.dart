import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class SeedRoadmapUseCase {
  final AdminRepository repository;
  SeedRoadmapUseCase(this.repository);

  Future<Either<Failure, String>> call() => repository.seedRoadmap();
}
