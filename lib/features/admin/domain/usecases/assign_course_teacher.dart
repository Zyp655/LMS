import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class AssignCourseTeacherUseCase {
  final AdminRepository repository;
  AssignCourseTeacherUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(
    int courseClassId,
    int teacherId, {
    bool force = false,
  }) {
    return repository.assignCourseTeacher(
      courseClassId,
      teacherId,
      force: force,
    );
  }
}
