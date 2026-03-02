import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class ImportSubjectsUseCase {
  final AdminRepository repository;
  ImportSubjectsUseCase(this.repository);

  Future<Either<Failure, String>> call(Map<String, dynamic> payload) {
    return repository.importSubjects(payload);
  }
}
