import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class GetUsersUseCase {
  final AdminRepository repository;
  GetUsersUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    int? role,
    String? search,
    int? departmentId,
    String? studentClass,
  }) {
    return repository.getUsers(
      role: role,
      search: search,
      departmentId: departmentId,
      studentClass: studentClass,
    );
  }
}
