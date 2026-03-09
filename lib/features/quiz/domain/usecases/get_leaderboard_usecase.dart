import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/quiz_repository.dart';
import '../entities/leaderboard_entry.dart';

class GetLeaderboardUseCase {
  final QuizRepository repository;

  GetLeaderboardUseCase(this.repository);

  Future<Either<Failure, List<LeaderboardEntry>>> call(
    GetLeaderboardParams params,
  ) async {
    return await repository.getLeaderboard(
      classId: params.classId,
      period: params.period,
    );
  }
}

class GetLeaderboardParams {
  final int classId;
  final String period;

  GetLeaderboardParams({required this.classId, required this.period});
}
