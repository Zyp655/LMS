import '../../domain/enitities/schedule_entity.dart';

abstract class ScheduleEvent {}

class LoadSchedules extends ScheduleEvent {}

class AddScheduleRequested extends ScheduleEvent {
  final ScheduleEntity schedule;
  AddScheduleRequested(this.schedule);
}

class DeleteScheduleRequested extends ScheduleEvent {
  final int id;
  DeleteScheduleRequested(this.id);
}

class UpdateScheduleRequested extends ScheduleEvent {
  final ScheduleEntity schedule;
  UpdateScheduleRequested(this.schedule);
}

class JoinClassRequested extends ScheduleEvent {
  final String code;
  JoinClassRequested(this.code);
}

class ResetSchedule extends ScheduleEvent {}
