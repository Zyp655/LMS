import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class ImportStudentsUseCase {
  final AdminRepository repository;
  ImportStudentsUseCase(this.repository);

  Future<Either<Failure, String>> call(Map<String, dynamic> payload) {
    return repository.importStudents(payload);
  }
}
