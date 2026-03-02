import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class GetAdminCoursesUseCase {
  final AdminRepository repository;
  GetAdminCoursesUseCase(this.repository);

  Future<Either<Failure, List<Map<String, dynamic>>>> call({String? search}) {
    return repository.getAdminCourses(search: search);
  }
}
