import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_summary_usecase.dart';
import '../../domain/usecases/get_heatmap_usecase.dart';
import '../../domain/usecases/get_velocity_usecase.dart';
import '../../domain/usecases/get_benchmark_usecase.dart';
import '../../domain/usecases/track_activity_usecase.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final GetSummaryUseCase getSummary;
  final GetHeatmapUseCase getHeatmap;
  final GetVelocityUseCase getVelocity;
  final GetBenchmarkUseCase getBenchmark;
  final TrackActivityUseCase trackActivity;

  AnalyticsBloc({
    required this.getSummary,
    required this.getHeatmap,
    required this.getVelocity,
    required this.getBenchmark,
    required this.trackActivity,
  }) : super(AnalyticsInitial()) {
    on<LoadAnalyticsDashboard>(_onLoadDashboard);
    on<LoadVelocity>(_onLoadVelocity);
    on<LoadBenchmark>(_onLoadBenchmark);
    on<TrackActivity>(_onTrackActivity);
  }

  Future<void> _onLoadDashboard(
    LoadAnalyticsDashboard event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());

    final summaryResult = await getSummary(userId: event.userId);
    final heatmapResult = await getHeatmap(
      userId: event.userId,
      months: event.heatmapMonths,
    );

    final summary = summaryResult.fold((failure) => null, (data) => data);
    final heatmap = heatmapResult.fold((failure) => null, (data) => data);

    if (summary != null && heatmap != null) {
      emit(AnalyticsDashboardLoaded(summary: summary, heatmap: heatmap));
    } else {
      emit(const AnalyticsError(message: 'Failed to load analytics dashboard'));
    }
  }

  Future<void> _onLoadVelocity(
    LoadVelocity event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());

    final result = await getVelocity(
      userId: event.userId,
      courseId: event.courseId,
    );

    result.fold(
      (failure) => emit(AnalyticsError(message: failure.message)),
      (data) => emit(VelocityLoaded(velocity: data)),
    );
  }

  Future<void> _onLoadBenchmark(
    LoadBenchmark event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());

    final result = await getBenchmark(
      userId: event.userId,
      courseId: event.courseId,
    );

    result.fold(
      (failure) => emit(AnalyticsError(message: failure.message)),
      (data) => emit(BenchmarkLoaded(benchmark: data)),
    );
  }

  Future<void> _onTrackActivity(
    TrackActivity event,
    Emitter<AnalyticsState> emit,
  ) async {
    await trackActivity(
      userId: event.userId,
      activityType: event.activityType,
      courseId: event.courseId,
      lessonId: event.lessonId,
      durationMinutes: event.durationMinutes,
    );
    emit(ActivityTracked());
  }
}
