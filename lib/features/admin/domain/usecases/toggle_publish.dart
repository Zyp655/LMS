import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class TogglePublishUseCase {
  final AdminRepository repository;
  TogglePublishUseCase(this.repository);

  Future<Either<Failure, String>> call(int courseId, bool current) {
    return repository.togglePublish(courseId, current);
  }
}
