import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/enitities/schedule_entity.dart';
import '../../domain/usecases/get_schedules_usecase.dart';
import '../../domain/usecases/add_schedule_usecase.dart';
import '../../domain/usecases/delete_schedule_usecase.dart';
import '../../domain/usecases/update_schedule_usecase.dart';
import '../../domain/usecases/join_class_usecase.dart';
import '../../../../core/services/notification_service.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final GetSchedulesUseCase getSchedulesUseCase;
  final AddScheduleUseCase addScheduleUseCase;
  final DeleteScheduleUseCase deleteScheduleUseCase;
  final UpdateScheduleUseCase updateScheduleUseCase;
  final JoinClassUseCase joinClassUseCase;

  ScheduleBloc({
    required this.getSchedulesUseCase,
    required this.addScheduleUseCase,
    required this.deleteScheduleUseCase,
    required this.updateScheduleUseCase,
    required this.joinClassUseCase,
  }) : super(ScheduleInitial()) {
    on<LoadSchedules>(_onLoadSchedules);
    on<AddScheduleRequested>(_onAddSchedule);
    on<DeleteScheduleRequested>(_onDeleteSchedule);
    on<UpdateScheduleRequested>(_onUpdateSchedule);
    on<JoinClassRequested>(_onJoinClass);
    on<ResetSchedule>(_onReset);
  }

  void _onReset(ResetSchedule event, Emitter<ScheduleState> emit) {
    emit(ScheduleInitial());
  }

  Future<void> _onLoadSchedules(
    LoadSchedules event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleLoading());
    final result = await getSchedulesUseCase();
    result.fold((failure) => emit(ScheduleError(failure.message)), (schedules) {
      final uniqueSchedules = <ScheduleEntity>[];
      final seenClassCodes = <String>{};

      for (var schedule in schedules) {
        if (schedule.classCode != null && schedule.classCode!.isNotEmpty) {
          if (!seenClassCodes.contains(schedule.classCode)) {
            seenClassCodes.add(schedule.classCode!);
            uniqueSchedules.add(schedule);
          }
        } else {
          uniqueSchedules.add(schedule);
        }
      }

      _checkAndNotifyRisks(uniqueSchedules);
      emit(ScheduleLoaded(uniqueSchedules));
    });
  }

  Future<void> _onAddSchedule(
    AddScheduleRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    final result = await addScheduleUseCase([event.schedule]);
    result.fold(
      (failure) => emit(ScheduleError(failure.message)),
      (_) => add(LoadSchedules()),
    );
  }

  Future<void> _onDeleteSchedule(
    DeleteScheduleRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    final result = await deleteScheduleUseCase(event.id);
    result.fold(
      (failure) => emit(ScheduleError(failure.message)),
      (_) => add(LoadSchedules()),
    );
  }

  Future<void> _onUpdateSchedule(
    UpdateScheduleRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    final result = await updateScheduleUseCase(event.schedule);
    result.fold(
      (failure) => emit(ScheduleError(failure.message)),
      (_) => add(LoadSchedules()),
    );
  }

  Future<void> _onJoinClass(
    JoinClassRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleLoading());
    final result = await joinClassUseCase(event.code);
    result.fold((failure) => emit(ScheduleError(failure.message)), (_) {
      emit(JoinClassSuccess());
      add(LoadSchedules());
    });
  }

  void _checkAndNotifyRisks(List<ScheduleEntity> schedules) {
    final notificationService = NotificationService();

    for (var subject in schedules) {
      if (subject.currentAbsences >= subject.maxAbsences) {
        notificationService.showWarningNotification(
          id: subject.id ?? 0,
          title: '⚠️ CẢNH BÁO TỪ GIÁO VIÊN',
          body:
              'Môn ${subject.subject}: Thầy/Cô đã đánh dấu bạn nghỉ ${subject.currentAbsences} buổi. CẤM THI!',
        );
      }

      if (subject.currentScore != null && subject.currentScore! < 4.0) {
        notificationService.showWarningNotification(
          id: (subject.id ?? 0) + 1000,
          title: '⚠️ KẾT QUẢ HỌC TẬP',
          body:
              'Môn ${subject.subject}: Giáo viên vừa nhập điểm ${subject.currentScore}. NGUY CƠ HỌC LẠI!',
        );
      }
    }
  }
}
