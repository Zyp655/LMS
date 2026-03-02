import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class GetAcademicCoursesWithTeachersUseCase {
  final AdminRepository repository;
  GetAcademicCoursesWithTeachersUseCase(this.repository);

  Future<Either<Failure, List<Map<String, dynamic>>>> call() {
    return repository.getAcademicCoursesWithTeachers();
  }
}
