import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/update_lesson_progress_usecase.dart';
import 'learning_player_event.dart';
import 'learning_player_state.dart';

class LearningPlayerBloc
    extends Bloc<LearningPlayerEvent, LearningPlayerState> {
  final UpdateLessonProgressUseCase updateLessonProgressUseCase;

  LearningPlayerBloc({required this.updateLessonProgressUseCase})
    : super(LearningPlayerInitial()) {
    on<UpdateProgressEvent>(_onUpdateProgress);
    on<MarkLessonCompleteEvent>(_onMarkComplete);
  }

  Future<void> _onUpdateProgress(
    UpdateProgressEvent event,
    Emitter<LearningPlayerState> emit,
  ) async {
    final result = await updateLessonProgressUseCase(
      userId: event.userId,
      lessonId: event.lessonId,
      lastWatchedPosition: event.currentPosition,
      isCompleted: event.isCompleted,
    );

    result.fold((failure) {}, (_) {});
  }

  Future<void> _onMarkComplete(
    MarkLessonCompleteEvent event,
    Emitter<LearningPlayerState> emit,
  ) async {
    final result = await updateLessonProgressUseCase(
      userId: event.userId,
      lessonId: event.lessonId,
      isCompleted: true,
    );

    result.fold((failure) => emit(LearningPlayerError(failure.message)), (_) {
      emit(ProgressUpdated());
    });
  }
}
