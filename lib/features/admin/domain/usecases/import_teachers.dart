import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class ImportTeachersUseCase {
  final AdminRepository repository;
  ImportTeachersUseCase(this.repository);

  Future<Either<Failure, String>> call(Map<String, dynamic> payload) {
    return repository.importTeachers(payload);
  }
}
