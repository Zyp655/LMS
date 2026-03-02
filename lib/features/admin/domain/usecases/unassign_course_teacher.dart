import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class UnassignCourseTeacherUseCase {
  final AdminRepository repository;
  UnassignCourseTeacherUseCase(this.repository);

  Future<Either<Failure, String>> call(int courseClassId) {
    return repository.unassignCourseTeacher(courseClassId);
  }
}
