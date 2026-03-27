import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class SeedProgressUseCase {
  final AdminRepository repository;
  SeedProgressUseCase(this.repository);

  Future<Either<Failure, String>> call() => repository.seedProgress();
}
