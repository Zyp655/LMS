import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class ToggleBanUseCase {
  final AdminRepository repository;
  ToggleBanUseCase(this.repository);

  Future<Either<Failure, String>> call(int userId) {
    return repository.toggleBan(userId);
  }
}
