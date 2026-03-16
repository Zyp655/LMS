import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class CreateCourseClassUseCase {
  final AdminRepository repository;
  CreateCourseClassUseCase(this.repository);

  Future<Either<Failure, String>> call(
    int academicCourseId,
    String classCode, {
    String? room,
    String? schedule,
    int? maxStudents,
    int? dayOfWeek,
    String? startDate,
    String? endDate,
  }) {
    return repository.createCourseClass(
      academicCourseId,
      classCode,
      room: room,
      schedule: schedule,
      maxStudents: maxStudents,
      dayOfWeek: dayOfWeek,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
