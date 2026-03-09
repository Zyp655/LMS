import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/quiz_entity.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_remote_data_source.dart';
import '../../domain/entities/quiz_statistics_entity.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuizRemoteDataSource remoteDataSource;

  QuizRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, QuizEntity>> generateQuiz({
    required String topic,
    required int numQuestions,
    required String difficulty,
    String? subjectContext,
    List<String>? questionTypes,
    String? videoUrl,
  }) async {
    try {
      final quizModel = await remoteDataSource.generateQuiz(
        topic: topic,
        numQuestions: numQuestions,
        difficulty: difficulty,
        subjectContext: subjectContext,
        questionTypes: questionTypes,
        videoUrl: videoUrl,
      );
      return Right(quizModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuizEntity>> generateQuizFromImage({
    required Uint8List imageBytes,
    required int numQuestions,
    required String difficulty,
  }) async {
    try {
      final quizModel = await remoteDataSource.generateQuizFromImage(
        imageBytes: imageBytes,
        numQuestions: numQuestions,
        difficulty: difficulty,
      );
      return Right(quizModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuizEntity>> generateAdaptiveQuiz({
    required int userId,
    required String topic,
    required int numQuestions,
  }) async {
    try {
      final quizModel = await remoteDataSource.generateAdaptiveQuiz(
        userId: userId,
        topic: topic,
        numQuestions: numQuestions,
      );
      return Right(quizModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> saveQuiz({
    required int userId,
    required QuizEntity quiz,
    bool isPublic = false,
  }) async {
    try {
      final quizId = await remoteDataSource.saveQuiz(
        userId: userId,
        quiz: quiz.toJson(),
        isPublic: isPublic,
      );
      return Right(quizId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuizEntity>> getQuizById(int quizId) async {
    try {
      final quizModel = await remoteDataSource.getQuizById(quizId);
      return Right(quizModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuizEntity>>> getMyQuizzes(int userId) async {
    try {
      final quizModels = await remoteDataSource.getMyQuizzes(userId);
      return Right(quizModels.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> submitQuiz({
    required int userId,
    required int quizId,
    required List<dynamic> answers,
    required int timeSpentSeconds,
  }) async {
    try {
      final result = await remoteDataSource.submitQuiz(
        userId: userId,
        quizId: quizId,
        answers: answers,
        timeSpentSeconds: timeSpentSeconds,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuizStatisticsResponseEntity>> getStatistics(
    int userId, {
    String? topic,
  }) async {
    try {
      final stats = await remoteDataSource.getStatistics(userId, topic: topic);
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LeaderboardEntry>>> getLeaderboard({
    required int classId,
    required String period,
  }) async {
    try {
      final entries = await remoteDataSource.getLeaderboard(
        classId: classId,
        period: period,
      );
      return Right(entries.map((e) => LeaderboardEntry.fromJson(e)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
