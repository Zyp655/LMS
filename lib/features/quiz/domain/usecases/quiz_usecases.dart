import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/quiz_entity.dart';
import '../entities/quiz_statistics_entity.dart';
import '../entities/leaderboard_entry.dart';
import '../repositories/quiz_repository.dart';

class GenerateQuizUseCase {
  final QuizRepository repository;

  GenerateQuizUseCase(this.repository);

  Future<Either<Failure, QuizEntity>> call({
    required String topic,
    required int numQuestions,
    required String difficulty,
    String? subjectContext,
    List<String>? questionTypes,
    String? videoUrl,
  }) {
    return repository.generateQuiz(
      topic: topic,
      numQuestions: numQuestions,
      difficulty: difficulty,
      subjectContext: subjectContext,
      questionTypes: questionTypes,
      videoUrl: videoUrl,
    );
  }
}

class GenerateQuizFromImageUseCase {
  final QuizRepository repository;

  GenerateQuizFromImageUseCase(this.repository);

  Future<Either<Failure, QuizEntity>> call({
    required Uint8List imageBytes,
    required int numQuestions,
    required String difficulty,
  }) {
    return repository.generateQuizFromImage(
      imageBytes: imageBytes,
      numQuestions: numQuestions,
      difficulty: difficulty,
    );
  }
}

class GenerateAdaptiveQuizUseCase {
  final QuizRepository repository;

  GenerateAdaptiveQuizUseCase(this.repository);

  Future<Either<Failure, QuizEntity>> call({
    required int userId,
    required String topic,
    required int numQuestions,
  }) {
    return repository.generateAdaptiveQuiz(
      userId: userId,
      topic: topic,
      numQuestions: numQuestions,
    );
  }
}

class SaveQuizUseCase {
  final QuizRepository repository;

  SaveQuizUseCase(this.repository);

  Future<Either<Failure, int>> call({
    required int userId,
    required QuizEntity quiz,
    bool isPublic = false,
  }) {
    return repository.saveQuiz(userId: userId, quiz: quiz, isPublic: isPublic);
  }
}

class GetQuizByIdUseCase {
  final QuizRepository repository;

  GetQuizByIdUseCase(this.repository);

  Future<Either<Failure, QuizEntity>> call(int quizId) {
    return repository.getQuizById(quizId);
  }
}

class GetMyQuizzesUseCase {
  final QuizRepository repository;

  GetMyQuizzesUseCase(this.repository);

  Future<Either<Failure, List<QuizEntity>>> call(int userId) {
    return repository.getMyQuizzes(userId);
  }
}

class SubmitQuizUseCase {
  final QuizRepository repository;

  SubmitQuizUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required int userId,
    required int quizId,
    required List<dynamic> answers,
    required int timeSpentSeconds,
  }) {
    return repository.submitQuiz(
      userId: userId,
      quizId: quizId,
      answers: answers,
      timeSpentSeconds: timeSpentSeconds,
    );
  }
}

class GetQuizStatisticsUseCase {
  final QuizRepository repository;

  GetQuizStatisticsUseCase(this.repository);

  Future<Either<Failure, QuizStatisticsResponseEntity>> call(
    int userId, {
    String? topic,
  }) {
    return repository.getStatistics(userId, topic: topic);
  }
}

class GetLeaderboardUseCase {
  final QuizRepository repository;

  GetLeaderboardUseCase(this.repository);

  Future<Either<Failure, List<LeaderboardEntry>>> call({
    required int classId,
    required String period,
  }) {
    return repository.getLeaderboard(classId: classId, period: period);
  }
}
