import 'package:get_it/get_it.dart';
import '../features/quiz/data/datasources/quiz_remote_data_source.dart';
import '../features/quiz/data/repositories/quiz_repository_impl.dart';
import '../features/quiz/domain/repositories/quiz_repository.dart';
import '../features/quiz/domain/usecases/quiz_usecases.dart'
    hide GetLeaderboardUseCase;
import '../features/quiz/domain/usecases/get_leaderboard_usecase.dart';
import '../features/quiz/presentation/bloc/quiz_bloc.dart';
import '../features/quiz/presentation/bloc/leaderboard/leaderboard_bloc.dart';

void initQuizModule(GetIt sl) {
  sl.registerLazySingleton<QuizRemoteDataSource>(
    () => QuizRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<QuizRepository>(
    () => QuizRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GenerateQuizUseCase(sl()));
  sl.registerLazySingleton(() => GenerateQuizFromImageUseCase(sl()));
  sl.registerLazySingleton(() => GenerateAdaptiveQuizUseCase(sl()));
  sl.registerLazySingleton(() => SaveQuizUseCase(sl()));
  sl.registerLazySingleton(() => GetQuizByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetMyQuizzesUseCase(sl()));
  sl.registerLazySingleton(() => SubmitQuizUseCase(sl()));
  sl.registerLazySingleton(() => GetQuizStatisticsUseCase(sl()));
  sl.registerLazySingleton(() => GetLeaderboardUseCase(sl()));

  sl.registerFactory(
    () => QuizBloc(
      generateQuiz: sl(),
      generateQuizFromImage: sl(),
      generateAdaptiveQuiz: sl(),
      saveQuiz: sl(),
      getQuizById: sl(),
      getMyQuizzes: sl(),
      submitQuiz: sl(),
      getStatistics: sl(),
    ),
  );
  sl.registerFactory(() => LeaderboardBloc(getLeaderboard: sl()));
}
