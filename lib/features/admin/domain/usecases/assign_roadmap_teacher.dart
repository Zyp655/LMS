import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class AssignRoadmapTeacherUseCase {
  final AdminRepository repository;
  AssignRoadmapTeacherUseCase(this.repository);

  Future<Either<Failure, String>> call(String email) {
    return repository.assignRoadmapTeacher(email);
  }
}
