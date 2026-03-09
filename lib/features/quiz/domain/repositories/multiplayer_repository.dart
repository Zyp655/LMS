import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class MultiplayerRepository {
  Stream<dynamic> get gameStream;

  Future<Either<Failure, void>> connect(
    String roomCode,
    int userId,
    String userName,
  );
  Future<Either<Failure, void>> disconnect();
  Future<Either<Failure, String>> createRoom(int quizId, {int? hostId});
  Future<Either<Failure, void>> joinRoom(String roomCode);
  Future<Either<Failure, void>> startGame(String roomCode);
  Future<Either<Failure, void>> submitAnswer(
    String roomCode,
    int questionIndex,
    int answerIndex,
    int userId,
  );

  Future<Either<Failure, List<dynamic>>> getMyQuizzes(int userId);
}
