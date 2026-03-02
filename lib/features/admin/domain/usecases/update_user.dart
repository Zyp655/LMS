import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class UpdateUserUseCase {
  final AdminRepository repository;
  UpdateUserUseCase(this.repository);

  Future<Either<Failure, String>> call(int userId, Map<String, dynamic> data) {
    return repository.updateUser(userId, data);
  }
}
