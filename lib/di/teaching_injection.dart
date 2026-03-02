import 'package:get_it/get_it.dart';
import '../features/teaching/data/datasources/teacher_remote_data_source.dart';
import '../features/teaching/data/repositories/teacher_repository_impl.dart';
import '../features/teaching/domain/repositories/teacher_repository.dart';
import '../features/teaching/domain/usecases/create_class_usecase.dart';
import '../features/teaching/domain/usecases/create_subject_usecase.dart';
import '../features/teaching/domain/usecases/get_subject_usecase.dart';
import '../features/teaching/domain/usecases/get_teacher_schedules_usecase.dart';
import '../features/teaching/domain/usecases/import_schedules_usecase.dart';
import '../features/teaching/domain/usecases/regenerate_class_code_usecase.dart';
import '../features/teaching/domain/usecases/update_student_score_usecase.dart';
import '../features/teaching/domain/usecases/get_students_in_class_usecase.dart';
import '../features/teaching/domain/usecases/get_assignments_usecase.dart';
import '../features/teaching/domain/usecases/create_assignment_usecase.dart';
import '../features/teaching/domain/usecases/update_assignment_usecase.dart';
import '../features/teaching/domain/usecases/delete_assignment_usecase.dart';
import '../features/teaching/domain/usecases/get_submissions_usecase.dart';
import '../features/teaching/domain/usecases/grade_submission_usecase.dart';
import '../features/teaching/domain/usecases/mark_attendance_usecase.dart';
import '../features/teaching/domain/usecases/get_attendance_records_usecase.dart';
import '../features/teaching/domain/usecases/get_attendance_statistics_usecase.dart';
import '../features/teaching/presentation/bloc/teacher_bloc.dart';
import '../features/course/data/datasources/major_remote_datasource.dart';

void initTeachingModule(GetIt sl) {
  sl.registerLazySingleton<TeacherRemoteDataSource>(
    () => TeacherRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<TeacherRepository>(
    () => TeacherRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<MajorRemoteDataSource>(
    () => MajorRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton(() => GetTeacherSchedulesUseCase(sl()));
  sl.registerLazySingleton(() => CreateClassUseCase(sl()));
  sl.registerLazySingleton(() => UpdateStudentScoreUseCase(sl()));
  sl.registerLazySingleton(() => ImportSchedulesUseCase(sl()));
  sl.registerLazySingleton(() => RegenerateClassCodeUseCase(sl()));
  sl.registerLazySingleton(() => GetSubjectsUseCase(sl()));
  sl.registerLazySingleton(() => CreateSubjectUseCase(sl()));
  sl.registerLazySingleton(() => GetStudentsInClassUseCase(sl()));
  sl.registerLazySingleton(() => GetAssignmentsUseCase(sl()));
  sl.registerLazySingleton(() => CreateAssignmentUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAssignmentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAssignmentUseCase(sl()));
  sl.registerLazySingleton(() => GetSubmissionsUseCase(sl()));
  sl.registerLazySingleton(() => GradeSubmissionUseCase(sl()));
  sl.registerLazySingleton(() => MarkAttendanceUseCase(sl()));
  sl.registerLazySingleton(() => GetAttendanceRecordsUseCase(sl()));
  sl.registerLazySingleton(() => GetAttendanceStatisticsUseCase(sl()));
  sl.registerFactory(
    () => TeacherBloc(
      getTeacherSchedules: sl(),
      createClass: sl(),
      updateScore: sl(),
      importSchedules: sl(),
      regenerateClassCode: sl(),
      getStudentsInClass: sl(),
      getSubjects: sl(),
      createSubject: sl(),
      getAssignments: sl(),
      createAssignment: sl(),
      updateAssignment: sl(),
      deleteAssignment: sl(),
      updateSchedule: sl(),
      deleteSchedule: sl(),
      getSubmissions: sl(),
      gradeSubmission: sl(),
      markAttendance: sl(),
      getAttendanceRecords: sl(),
      getAttendanceStatistics: sl(),
      teacherRepository: sl(),
    ),
  );
}
