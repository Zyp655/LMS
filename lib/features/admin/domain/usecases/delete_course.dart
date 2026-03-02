import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class DeleteCourseUseCase {
  final AdminRepository repository;
  DeleteCourseUseCase(this.repository);

  Future<Either<Failure, String>> call(int courseId) {
    return repository.deleteCourse(courseId);
  }
}
