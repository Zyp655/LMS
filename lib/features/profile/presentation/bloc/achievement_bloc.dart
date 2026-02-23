import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_achievements_usecase.dart';
import 'achievement_event.dart';
import 'achievement_state.dart';

class AchievementBloc extends Bloc<AchievementEvent, AchievementState> {
  final GetAchievementsUseCase getAchievements;

  AchievementBloc({required this.getAchievements})
    : super(AchievementInitial()) {
    on<LoadAchievements>(_onLoadAchievements);
  }

  Future<void> _onLoadAchievements(
    LoadAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    emit(AchievementLoading());
    final result = await getAchievements(event.userId);
    result.fold(
      (failure) => emit(AchievementError(failure.message)),
      (achievements) => emit(AchievementsLoaded(achievements)),
    );
  }
}
