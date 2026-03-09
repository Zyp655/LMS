import 'dart:typed_data';
import '../entities/quiz_entity.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/quiz_statistics_entity.dart';
import '../entities/leaderboard_entry.dart';

abstract class QuizRepository {
  Future<Either<Failure, QuizEntity>> generateQuiz({
    required String topic,
    required int numQuestions,
    required String difficulty,
    String? subjectContext,
    List<String>? questionTypes,
    String? videoUrl,
  });

  Future<Either<Failure, QuizEntity>> generateQuizFromImage({
    required Uint8List imageBytes,
    required int numQuestions,
    required String difficulty,
  });

  Future<Either<Failure, QuizEntity>> generateAdaptiveQuiz({
    required int userId,
    required String topic,
    required int numQuestions,
  });

  Future<Either<Failure, int>> saveQuiz({
    required int userId,
    required QuizEntity quiz,
    bool isPublic = false,
  });

  Future<Either<Failure, QuizEntity>> getQuizById(int quizId);

  Future<Either<Failure, List<QuizEntity>>> getMyQuizzes(int userId);

  Future<Either<Failure, Map<String, dynamic>>> submitQuiz({
    required int userId,
    required int quizId,
    required List<dynamic> answers,
    required int timeSpentSeconds,
  });

  Future<Either<Failure, QuizStatisticsResponseEntity>> getStatistics(
    int userId, {
    String? topic,
  });

  Future<Either<Failure, List<LeaderboardEntry>>> getLeaderboard({
    required int classId,
    required String period,
  });
}
