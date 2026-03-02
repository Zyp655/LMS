import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class GetAcademicDataUseCase {
  final AdminRepository repository;
  GetAcademicDataUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call() {
    return repository.getAcademicData();
  }
}
