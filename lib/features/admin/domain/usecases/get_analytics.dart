import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/admin_repository.dart';

class GetAnalyticsUseCase {
  final AdminRepository repository;
  GetAnalyticsUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call() {
    return repository.getAnalytics();
  }
}
