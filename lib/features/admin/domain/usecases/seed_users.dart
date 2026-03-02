import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class SeedUsersUseCase {
  final AdminRepository repository;
  SeedUsersUseCase(this.repository);

  Future<Either<Failure, String>> call() => repository.seedUsers();
}
