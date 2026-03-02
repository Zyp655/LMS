import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class DeleteUserUseCase {
  final AdminRepository repository;
  DeleteUserUseCase(this.repository);

  Future<Either<Failure, String>> call(int userId) {
    return repository.deleteUser(userId);
  }
}
