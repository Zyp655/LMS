import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/roadmap_usecases.dart';
import 'roadmap_event.dart';
import 'roadmap_state.dart';

class RoadmapBloc extends Bloc<RoadmapEvent, RoadmapState> {
  final GetPersonalRoadmapUseCase getPersonalRoadmap;
  final ResetRoadmapUseCase resetRoadmap;
  final AddRoadmapItemUseCase addRoadmapItem;
  final UpdateRoadmapItemUseCase updateRoadmapItem;
  final RemoveRoadmapItemUseCase removeRoadmapItem;
  final GetRoadmapSuggestionsUseCase getSuggestions;

  RoadmapBloc({
    required this.getPersonalRoadmap,
    required this.resetRoadmap,
    required this.addRoadmapItem,
    required this.updateRoadmapItem,
    required this.removeRoadmapItem,
    required this.getSuggestions,
  }) : super(RoadmapInitial()) {
    on<LoadPersonalRoadmap>(_onLoadRoadmap);
    on<ResetRoadmap>(_onResetRoadmap);
    on<AddRoadmapItem>(_onAddItem);
    on<UpdateRoadmapItem>(_onUpdateItem);
    on<RemoveRoadmapItem>(_onRemoveItem);
    on<LoadSuggestions>(_onLoadSuggestions);
  }

  Future<void> _onLoadRoadmap(
    LoadPersonalRoadmap event,
    Emitter<RoadmapState> emit,
  ) async {
    emit(RoadmapLoading());
    final result = await getPersonalRoadmap(event.userId);
    result.fold((failure) => emit(RoadmapError(failure.message)), (data) {
      final roadmap = data['roadmap'];
      if (roadmap == null) {
        emit(RoadmapNoData(data['message'] as String? ?? 'Không có dữ liệu'));
        return;
      }
      emit(
        PersonalRoadmapLoaded(
          roadmap: roadmap as Map<String, dynamic>,
          items: List<Map<String, dynamic>>.from(data['items'] ?? []),
          stats: data['stats'] as Map<String, dynamic>? ?? {},
        ),
      );
    });
  }

  Future<void> _onResetRoadmap(
    ResetRoadmap event,
    Emitter<RoadmapState> emit,
  ) async {
    emit(RoadmapLoading());
    final result = await resetRoadmap(event.userId);
    result.fold((failure) => emit(RoadmapError(failure.message)), (message) {
      emit(RoadmapActionSuccess(message));
      add(LoadPersonalRoadmap(userId: event.userId));
    });
  }

  Future<void> _onAddItem(
    AddRoadmapItem event,
    Emitter<RoadmapState> emit,
  ) async {
    final result = await addRoadmapItem(
      roadmapId: event.roadmapId,
      academicCourseId: event.academicCourseId,
      semesterOrder: event.semesterOrder,
    );
    result.fold((failure) => emit(RoadmapError(failure.message)), (message) {
      emit(RoadmapActionSuccess(message));
      add(LoadPersonalRoadmap(userId: event.userId));
    });
  }

  Future<void> _onUpdateItem(
    UpdateRoadmapItem event,
    Emitter<RoadmapState> emit,
  ) async {
    final result = await updateRoadmapItem(event.data);
    result.fold((failure) => emit(RoadmapError(failure.message)), (message) {
      emit(RoadmapActionSuccess(message));
      add(LoadPersonalRoadmap(userId: event.userId));
    });
  }

  Future<void> _onRemoveItem(
    RemoveRoadmapItem event,
    Emitter<RoadmapState> emit,
  ) async {
    final result = await removeRoadmapItem(event.itemId);
    result.fold((failure) => emit(RoadmapError(failure.message)), (message) {
      emit(RoadmapActionSuccess(message));
      add(LoadPersonalRoadmap(userId: event.userId));
    });
  }

  Future<void> _onLoadSuggestions(
    LoadSuggestions event,
    Emitter<RoadmapState> emit,
  ) async {
    final result = await getSuggestions(
      departmentId: event.departmentId,
      roadmapId: event.roadmapId,
    );
    result.fold(
      (failure) => emit(RoadmapError(failure.message)),
      (suggestions) => emit(SuggestionsLoaded(suggestions)),
    );
  }
}
