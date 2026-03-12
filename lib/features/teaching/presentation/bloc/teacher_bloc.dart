import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_class_usecase.dart';
import '../../domain/usecases/create_subject_usecase.dart';
import '../../domain/usecases/get_subject_usecase.dart';
import '../../domain/usecases/get_teacher_schedules_usecase.dart';
import '../../domain/usecases/import_schedules_usecase.dart';
import '../../domain/usecases/regenerate_class_code_usecase.dart';
import '../../domain/usecases/update_student_score_usecase.dart';
import '../../domain/usecases/get_students_in_class_usecase.dart';
import '../../domain/usecases/get_assignments_usecase.dart';
import '../../domain/usecases/create_assignment_usecase.dart';
import '../../domain/usecases/update_assignment_usecase.dart';
import '../../domain/usecases/delete_assignment_usecase.dart';
import '../../../schedule/domain/usecases/update_schedule_usecase.dart';
import '../../../schedule/domain/usecases/delete_schedule_usecase.dart';
import '../../domain/usecases/get_submissions_usecase.dart';
import '../../domain/usecases/grade_submission_usecase.dart';
import '../../domain/usecases/mark_attendance_usecase.dart';
import '../../domain/usecases/get_attendance_records_usecase.dart';
import '../../domain/usecases/get_attendance_statistics_usecase.dart';
import '../../domain/repositories/teacher_repository.dart';
import 'teacher_event.dart';
import 'teacher_state.dart';

class TeacherBloc extends Bloc<TeacherEvent, TeacherState> {
  final GetTeacherSchedulesUseCase getTeacherSchedules;
  final CreateClassUseCase createClass;
  final UpdateStudentScoreUseCase updateScore;
  final ImportSchedulesUseCase importSchedules;
  final RegenerateClassCodeUseCase regenerateClassCode;
  final GetStudentsInClassUseCase getStudentsInClass;
  final GetAssignmentsUseCase getAssignments;
  final CreateAssignmentUseCase createAssignment;
  final UpdateAssignmentUseCase updateAssignment;
  final DeleteAssignmentUseCase deleteAssignment;
  final UpdateScheduleUseCase updateSchedule;
  final DeleteScheduleUseCase deleteSchedule;
  final GetSubmissionsUseCase getSubmissions;
  final GradeSubmissionUseCase gradeSubmission;
  final MarkAttendanceUseCase markAttendance;
  final GetAttendanceRecordsUseCase getAttendanceRecords;
  final GetAttendanceStatisticsUseCase getAttendanceStatistics;
  final TeacherRepository teacherRepository;

  final GetSubjectsUseCase getSubjects;
  final CreateSubjectUseCase createSubject;

  TeacherBloc({
    required this.getTeacherSchedules,
    required this.createClass,
    required this.updateScore,
    required this.importSchedules,
    required this.regenerateClassCode,
    required this.getStudentsInClass,
    required this.getSubjects,
    required this.createSubject,
    required this.getAssignments,
    required this.createAssignment,
    required this.updateAssignment,
    required this.deleteAssignment,
    required this.updateSchedule,
    required this.deleteSchedule,
    required this.getSubmissions,
    required this.gradeSubmission,
    required this.markAttendance,
    required this.getAttendanceRecords,
    required this.getAttendanceStatistics,
    required this.teacherRepository,
  }) : super(TeacherInitial()) {
    on<LoadSubjects>((event, emit) async {
      emit(TeacherLoading());
      final result = await getSubjects(event.teacherId);
      result.fold(
        (failure) => emit(TeacherError(failure.message)),
        (subjects) => emit(SubjectsLoaded(subjects)),
      );
    });

    on<CreateSubjectRequested>((event, emit) async {
      emit(TeacherLoading());
      final result = await createSubject(
        event.teacherId,
        event.name,
        event.credits,
        event.code,
      );
      result.fold((failure) => emit(TeacherError(failure.message)), (_) {
        emit(SubjectCreatedSuccess());
        add(LoadSubjects(event.teacherId));
      });
    });

    on<LoadTeacherClasses>((event, emit) async {
      emit(TeacherLoading());
      final result = await getTeacherSchedules(event.teacherId);
      result.fold(
        (failure) => emit(TeacherError(failure.message)),
        (schedules) => emit(TeacherLoaded(schedules)),
      );
    });

    on<CreateClassRequested>((event, emit) async {
      final result = await createClass(
        event.className,
        event.teacherId,
        event.subjectName,
        event.room,
        event.startTime,
        event.endTime,
        event.startDate,
        event.repeatWeeks,
        event.notificationMinutes,
        event.credits,
      );
      result.fold((failure) => emit(TeacherError(failure.message)), (_) {
        emit(ClassCreatedSuccess());
        add(LoadTeacherClasses(event.teacherId));
      });
    });

    on<UpdateClassRequested>((event, emit) async {
      emit(TeacherLoading());
      final result = await updateSchedule(event.schedule);
      result.fold((failure) => emit(TeacherError(failure.message)), (_) {
        emit(ClassUpdatedSuccess());
        add(LoadTeacherClasses(event.teacherId));
      });
    });

    on<DeleteClassRequested>((event, emit) async {
      emit(TeacherLoading());
      final result = await deleteSchedule(event.scheduleId);
      result.fold((failure) => emit(TeacherError(failure.message)), (_) {
        emit(ClassDeletedSuccess());
        add(LoadTeacherClasses(event.teacherId));
      });
    });

    on<UpdateScoreRequested>((event, emit) async {
      emit(TeacherLoading());
      final result = await updateScore(
        event.scheduleId,
        event.absences,
        event.midtermScore,
        event.finalScore,
        event.examScore,
      );
      result.fold((failure) => emit(TeacherError(failure.message)), (_) {
        emit(ScoreUpdatedSuccess());
        add(LoadTeacherClasses(event.teacherId));
      });
    });

    on<ImportSchedulesRequested>((event, emit) async {
      emit(TeacherLoading());
      final result = await importSchedules(event.teacherId, event.schedules);
      result.fold((failure) => emit(TeacherError(failure.message)), (_) {
        emit(ImportSuccess());
        add(LoadTeacherClasses(event.teacherId));
      });
    });

    on<GetStudentsInClass>((event, emit) async {
      emit(TeacherLoading());
      final result = await getStudentsInClass(event.classId);
      result.fold(
        (failure) => emit(TeacherError(failure.message)),
        (students) => emit(StudentsLoaded(students)),
      );
    });

    on<RegenerateCodeRequested>(_onRegenerateCode);

    on<LoadAssignments>((event, emit) async {
      emit(TeacherLoading());
      final result = await getAssignments(event.teacherId);
      result.fold(
        (failure) => emit(TeacherError(failure.message)),
        (assignments) => emit(AssignmentsLoaded(assignments)),
      );
    });

    on<CreateAssignmentRequested>((event, emit) async {
      emit(TeacherLoading());
      final result = await createAssignment(event.assignment, event.teacherId);
      result.fold((failure) => emit(TeacherError(failure.message)), (_) {
        emit(AssignmentCreatedSuccess());
        add(LoadAssignments(event.teacherId));
      });
    });

    on<UpdateAssignmentRequested>((event, emit) async {
      emit(TeacherLoading());
      final result = await updateAssignment(event.assignment, event.teacherId);
      result.fold((failure) => emit(TeacherError(failure.message)), (_) {
        emit(AssignmentUpdatedSuccess());
        add(LoadAssignments(event.teacherId));
      });
    });

    on<DeleteAssignmentRequested>((event, emit) async {
      emit(TeacherLoading());
      final result = await deleteAssignment(
        event.assignmentId,
        event.teacherId,
      );
      result.fold((failure) => emit(TeacherError(failure.message)), (_) {
        add(LoadAssignments(event.teacherId));
      });
    });

    on<GetSubmissions>((event, emit) async {
      emit(TeacherLoading());
      final result = await getSubmissions(event.assignmentId);
      result.fold(
        (failure) => emit(TeacherError(failure.message)),
        (submissions) => emit(SubmissionsLoaded(submissions)),
      );
    });

    on<GradeSubmission>((event, emit) async {
      emit(TeacherLoading());
      final result = await gradeSubmission(
        event.submissionId,
        event.grade,
        event.feedback,
        event.teacherId,
      );
      result.fold((failure) => emit(TeacherError(failure.message)), (_) {
        emit(SubmissionGradedSuccess());
      });
    });

    on<MarkAttendanceRequested>((event, emit) async {
      emit(TeacherLoading());
      final result = await markAttendance(
        classId: event.classId,
        date: event.date,
        teacherId: event.teacherId,
        attendances: event.attendances,
      );
      result.fold((failure) => emit(TeacherError(failure.message)), (_) {
        emit(AttendanceMarkedSuccess());
      });
    });

    on<LoadAttendanceRecords>((event, emit) async {
      emit(TeacherLoading());
      final result = await getAttendanceRecords(
        classId: event.classId,
        date: event.date,
      );
      result.fold(
        (failure) => emit(TeacherError(failure.message)),
        (records) => emit(AttendanceRecordsLoaded(records)),
      );
    });

    on<LoadAttendanceStatistics>((event, emit) async {
      final result = await getAttendanceStatistics(event.classId);
      result.fold(
        (failure) => emit(TeacherError(failure.message)),
        (statistics) => emit(AttendanceStatisticsLoaded(statistics)),
      );
    });

    on<EnrollStudentsByFile>((event, emit) async {
      emit(TeacherLoading());
      final result = await teacherRepository.enrollStudentsByIdentifier(
        event.classId,
        event.teacherId,
        event.identifiers,
      );
      result.fold(
        (failure) => emit(TeacherError(failure.message)),
        (data) => emit(
          EnrollmentImportResult(
            enrolled: List.from(data['enrolled'] ?? []),
            notFound: List.from(data['notFound'] ?? []),
            alreadyEnrolled: List.from(data['alreadyEnrolled'] ?? []),
          ),
        ),
      );
    });
  }

  Future<void> _onRegenerateCode(
    RegenerateCodeRequested event,
    Emitter<TeacherState> emit,
  ) async {
    final result = await regenerateClassCode(
      event.teacherId,
      event.subjectName,
      event.isRefresh,
    );
    result.fold((failure) => emit(TeacherError(failure.message)), (newCode) {
      emit(CodeRegeneratedSuccess(newCode, "Đã cập nhật mã lớp mới!"));
      add(LoadTeacherClasses(event.teacherId));
    });
  }
}
