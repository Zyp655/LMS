import 'package:equatable/equatable.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../../schedule/domain/enitities/schedule_entity.dart';

abstract class TeacherEvent extends Equatable {
  const TeacherEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubjects extends TeacherEvent {
  final int teacherId;

  const LoadSubjects(this.teacherId);

  @override
  List<Object> get props => [teacherId];
}

class CreateSubjectRequested extends TeacherEvent {
  final int teacherId;
  final String name;
  final int credits;
  final String? code;

  const CreateSubjectRequested(
    this.teacherId,
    this.name,
    this.credits,
    this.code,
  );

  @override
  List<Object?> get props => [teacherId, name, credits, code];
}

class CreateClassRequested extends TeacherEvent {
  final String className;
  final int teacherId;
  final String subjectName;
  final String room;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime startDate;
  final int repeatWeeks;
  final int notificationMinutes;
  final int credits;

  const CreateClassRequested({
    required this.className,
    required this.teacherId,
    required this.subjectName,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    required this.repeatWeeks,
    required this.notificationMinutes,
    required this.credits,
  });

  @override
  List<Object> get props => [
    className,
    teacherId,
    subjectName,
    room,
    startTime,
    endTime,
    startDate,
    repeatWeeks,
    notificationMinutes,
    credits,
  ];
}

class LoadTeacherClasses extends TeacherEvent {
  final int teacherId;

  const LoadTeacherClasses(this.teacherId);

  @override
  List<Object> get props => [teacherId];
}

class RegenerateCodeRequested extends TeacherEvent {
  final int teacherId;
  final String subjectName;
  final bool isRefresh;

  const RegenerateCodeRequested(
    this.teacherId,
    this.subjectName,
    this.isRefresh,
  );

  @override
  List<Object> get props => [teacherId, subjectName, isRefresh];
}

class UpdateScoreRequested extends TeacherEvent {
  final int teacherId;
  final int scheduleId;
  final int? absences;
  final double? midtermScore;
  final double? finalScore;
  final double? examScore;

  const UpdateScoreRequested({
    required this.teacherId,
    required this.scheduleId,
    this.absences,
    this.midtermScore,
    this.finalScore,
    this.examScore,
  });

  @override
  List<Object?> get props => [
    scheduleId,
    absences,
    midtermScore,
    finalScore,
    examScore,
  ];
}

class ImportSchedulesRequested extends TeacherEvent {
  final int teacherId;
  final List<Map<String, dynamic>> schedules;

  const ImportSchedulesRequested(this.teacherId, this.schedules);

  @override
  List<Object> get props => [teacherId, schedules];
}

class GetStudentsInClass extends TeacherEvent {
  final int classId;

  const GetStudentsInClass(this.classId);

  @override
  List<Object> get props => [classId];
}

class LoadAssignments extends TeacherEvent {
  final int teacherId;
  const LoadAssignments(this.teacherId);
  @override
  List<Object> get props => [teacherId];
}

class CreateAssignmentRequested extends TeacherEvent {
  final AssignmentEntity assignment;
  final int teacherId;
  const CreateAssignmentRequested(this.assignment, this.teacherId);
  @override
  List<Object> get props => [assignment, teacherId];
}

class UpdateClassRequested extends TeacherEvent {
  final ScheduleEntity schedule;
  final int teacherId;

  const UpdateClassRequested(this.schedule, this.teacherId);

  @override
  List<Object> get props => [schedule, teacherId];
}

class DeleteClassRequested extends TeacherEvent {
  final int scheduleId;
  final int teacherId;

  const DeleteClassRequested(this.scheduleId, this.teacherId);

  @override
  List<Object> get props => [scheduleId, teacherId];
}

class UpdateAssignmentRequested extends TeacherEvent {
  final AssignmentEntity assignment;
  final int teacherId;

  const UpdateAssignmentRequested(this.assignment, this.teacherId);

  @override
  List<Object> get props => [assignment, teacherId];
}

class DeleteAssignmentRequested extends TeacherEvent {
  final int assignmentId;
  final int teacherId;

  const DeleteAssignmentRequested(this.assignmentId, this.teacherId);

  @override
  List<Object> get props => [assignmentId, teacherId];
}

class GetSubmissions extends TeacherEvent {
  final int assignmentId;
  const GetSubmissions(this.assignmentId);
  @override
  List<Object> get props => [assignmentId];
}

class GradeSubmission extends TeacherEvent {
  final int submissionId;
  final double grade;
  final String? feedback;
  final int teacherId;

  const GradeSubmission({
    required this.submissionId,
    required this.grade,
    this.feedback,
    required this.teacherId,
  });

  @override
  List<Object?> get props => [submissionId, grade, feedback, teacherId];
}

class MarkAttendanceRequested extends TeacherEvent {
  final int classId;
  final DateTime date;
  final int teacherId;
  final List<Map<String, dynamic>> attendances;

  const MarkAttendanceRequested({
    required this.classId,
    required this.date,
    required this.teacherId,
    required this.attendances,
  });

  @override
  List<Object> get props => [classId, date, teacherId, attendances];
}

class LoadAttendanceRecords extends TeacherEvent {
  final int classId;
  final DateTime date;

  const LoadAttendanceRecords({required this.classId, required this.date});

  @override
  List<Object> get props => [classId, date];
}

class LoadAttendanceStatistics extends TeacherEvent {
  final int classId;

  const LoadAttendanceStatistics(this.classId);

  @override
  List<Object> get props => [classId];
}

class EnrollStudentsByFile extends TeacherEvent {
  final int classId;
  final int teacherId;
  final List<String> identifiers;

  const EnrollStudentsByFile({
    required this.classId,
    required this.teacherId,
    required this.identifiers,
  });

  @override
  List<Object> get props => [classId, teacherId, identifiers];
}
