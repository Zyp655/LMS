import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:alarmm/core/error/failures.dart';
import 'package:alarmm/features/schedule/domain/enitities/schedule_entity.dart';
import 'package:alarmm/features/schedule/domain/usecases/update_schedule_usecase.dart';
import 'package:alarmm/features/schedule/domain/usecases/delete_schedule_usecase.dart';
import 'package:alarmm/features/teaching/domain/entities/subject_entity.dart';
import 'package:alarmm/features/teaching/domain/entities/student_entity.dart';
import 'package:alarmm/features/teaching/domain/entities/assignment_entity.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_teacher_schedules_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/create_class_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/update_student_score_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/import_schedules_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/regenerate_class_code_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_students_in_class_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_subject_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/create_subject_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_assignments_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/create_assignment_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/update_assignment_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/delete_assignment_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_submissions_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/grade_submission_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/mark_attendance_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_attendance_records_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_attendance_statistics_usecase.dart';
import 'package:alarmm/features/teaching/presentation/bloc/teacher_bloc.dart';
import 'package:alarmm/features/teaching/presentation/bloc/teacher_event.dart';
import 'package:alarmm/features/teaching/presentation/bloc/teacher_state.dart';
import 'package:alarmm/features/teaching/domain/repositories/teacher_repository.dart';

// ── Mocks ──────────────────────────────────────────────────────────
class MockGetTeacherSchedules extends Mock
    implements GetTeacherSchedulesUseCase {}

class MockCreateClass extends Mock implements CreateClassUseCase {}

class MockUpdateScore extends Mock implements UpdateStudentScoreUseCase {}

class MockImportSchedules extends Mock implements ImportSchedulesUseCase {}

class MockRegenerateClassCode extends Mock
    implements RegenerateClassCodeUseCase {}

class MockGetStudentsInClass extends Mock
    implements GetStudentsInClassUseCase {}

class MockGetSubjects extends Mock implements GetSubjectsUseCase {}

class MockCreateSubject extends Mock implements CreateSubjectUseCase {}

class MockGetAssignments extends Mock implements GetAssignmentsUseCase {}

class MockCreateAssignment extends Mock implements CreateAssignmentUseCase {}

class MockUpdateAssignment extends Mock implements UpdateAssignmentUseCase {}

class MockDeleteAssignment extends Mock implements DeleteAssignmentUseCase {}

class MockUpdateSchedule extends Mock implements UpdateScheduleUseCase {}

class MockDeleteSchedule extends Mock implements DeleteScheduleUseCase {}

class MockGetSubmissions extends Mock implements GetSubmissionsUseCase {}

class MockGradeSubmission extends Mock implements GradeSubmissionUseCase {}

class MockMarkAttendance extends Mock implements MarkAttendanceUseCase {}

class MockGetAttendanceRecords extends Mock
    implements GetAttendanceRecordsUseCase {}

class MockGetAttendanceStatistics extends Mock
    implements GetAttendanceStatisticsUseCase {}

class MockTeacherRepository extends Mock implements TeacherRepository {}

// ── Fake values for mocktail ───────────────────────────────────────
class FakeScheduleEntity extends Fake implements ScheduleEntity {}

class FakeAssignmentEntity extends Fake implements AssignmentEntity {}

// ── Test data ──────────────────────────────────────────────────────
final tNow = DateTime(2026, 3, 1);
const tTeacherId = 1;
const tClassId = 10;

final tSchedule = ScheduleEntity(
  id: 1,
  subject: 'Flutter',
  room: 'A101',
  start: DateTime(2026, 3, 1, 8),
  end: DateTime(2026, 3, 1, 10),
);

final tSubject = SubjectEntity(
  id: 1,
  name: 'Flutter',
  credits: 3,
  code: 'CS101',
);

const tStudent = StudentEntity(
  scheduleId: 1,
  userId: 2,
  studentName: 'Nguyễn Văn A',
  studentId: 'SV001',
  email: 'a@edu.vn',
  currentAbsences: 0,
  maxAbsences: 3,
  targetScore: 4.0,
);

final tAssignment = AssignmentEntity(
  id: 1,
  classId: tClassId,
  title: 'Bài tập 1',
  dueDate: DateTime(2026, 3, 15),
);

// ── Helper ─────────────────────────────────────────────────────────
TeacherBloc _createBloc({
  required MockGetTeacherSchedules getTeacherSchedules,
  required MockCreateClass createClass,
  required MockUpdateScore updateScore,
  required MockImportSchedules importSchedules,
  required MockRegenerateClassCode regenerateClassCode,
  required MockGetStudentsInClass getStudentsInClass,
  required MockGetSubjects getSubjects,
  required MockCreateSubject createSubject,
  required MockGetAssignments getAssignments,
  required MockCreateAssignment createAssignment,
  required MockUpdateAssignment updateAssignment,
  required MockDeleteAssignment deleteAssignment,
  required MockUpdateSchedule updateSchedule,
  required MockDeleteSchedule deleteSchedule,
  required MockGetSubmissions getSubmissions,
  required MockGradeSubmission gradeSubmission,
  required MockMarkAttendance markAttendance,
  required MockGetAttendanceRecords getAttendanceRecords,
  required MockGetAttendanceStatistics getAttendanceStatistics,
  required MockTeacherRepository teacherRepository,
}) {
  return TeacherBloc(
    getTeacherSchedules: getTeacherSchedules,
    createClass: createClass,
    updateScore: updateScore,
    importSchedules: importSchedules,
    regenerateClassCode: regenerateClassCode,
    getStudentsInClass: getStudentsInClass,
    getSubjects: getSubjects,
    createSubject: createSubject,
    getAssignments: getAssignments,
    createAssignment: createAssignment,
    updateAssignment: updateAssignment,
    deleteAssignment: deleteAssignment,
    updateSchedule: updateSchedule,
    deleteSchedule: deleteSchedule,
    getSubmissions: getSubmissions,
    gradeSubmission: gradeSubmission,
    markAttendance: markAttendance,
    getAttendanceRecords: getAttendanceRecords,
    getAttendanceStatistics: getAttendanceStatistics,
    teacherRepository: teacherRepository,
  );
}

void main() {
  late MockGetTeacherSchedules mockGetTeacherSchedules;
  late MockCreateClass mockCreateClass;
  late MockUpdateScore mockUpdateScore;
  late MockImportSchedules mockImportSchedules;
  late MockRegenerateClassCode mockRegenerateClassCode;
  late MockGetStudentsInClass mockGetStudentsInClass;
  late MockGetSubjects mockGetSubjects;
  late MockCreateSubject mockCreateSubject;
  late MockGetAssignments mockGetAssignments;
  late MockCreateAssignment mockCreateAssignment;
  late MockUpdateAssignment mockUpdateAssignment;
  late MockDeleteAssignment mockDeleteAssignment;
  late MockUpdateSchedule mockUpdateSchedule;
  late MockDeleteSchedule mockDeleteSchedule;
  late MockGetSubmissions mockGetSubmissions;
  late MockGradeSubmission mockGradeSubmission;
  late MockMarkAttendance mockMarkAttendance;
  late MockGetAttendanceRecords mockGetAttendanceRecords;
  late MockGetAttendanceStatistics mockGetAttendanceStatistics;
  late MockTeacherRepository mockTeacherRepository;

  setUpAll(() {
    registerFallbackValue(FakeScheduleEntity());
    registerFallbackValue(FakeAssignmentEntity());
  });

  setUp(() {
    mockGetTeacherSchedules = MockGetTeacherSchedules();
    mockCreateClass = MockCreateClass();
    mockUpdateScore = MockUpdateScore();
    mockImportSchedules = MockImportSchedules();
    mockRegenerateClassCode = MockRegenerateClassCode();
    mockGetStudentsInClass = MockGetStudentsInClass();
    mockGetSubjects = MockGetSubjects();
    mockCreateSubject = MockCreateSubject();
    mockGetAssignments = MockGetAssignments();
    mockCreateAssignment = MockCreateAssignment();
    mockUpdateAssignment = MockUpdateAssignment();
    mockDeleteAssignment = MockDeleteAssignment();
    mockUpdateSchedule = MockUpdateSchedule();
    mockDeleteSchedule = MockDeleteSchedule();
    mockGetSubmissions = MockGetSubmissions();
    mockGradeSubmission = MockGradeSubmission();
    mockMarkAttendance = MockMarkAttendance();
    mockGetAttendanceRecords = MockGetAttendanceRecords();
    mockGetAttendanceStatistics = MockGetAttendanceStatistics();
    mockTeacherRepository = MockTeacherRepository();
  });

  TeacherBloc buildBloc() => _createBloc(
    getTeacherSchedules: mockGetTeacherSchedules,
    createClass: mockCreateClass,
    updateScore: mockUpdateScore,
    importSchedules: mockImportSchedules,
    regenerateClassCode: mockRegenerateClassCode,
    getStudentsInClass: mockGetStudentsInClass,
    getSubjects: mockGetSubjects,
    createSubject: mockCreateSubject,
    getAssignments: mockGetAssignments,
    createAssignment: mockCreateAssignment,
    updateAssignment: mockUpdateAssignment,
    deleteAssignment: mockDeleteAssignment,
    updateSchedule: mockUpdateSchedule,
    deleteSchedule: mockDeleteSchedule,
    getSubmissions: mockGetSubmissions,
    gradeSubmission: mockGradeSubmission,
    markAttendance: mockMarkAttendance,
    getAttendanceRecords: mockGetAttendanceRecords,
    getAttendanceStatistics: mockGetAttendanceStatistics,
    teacherRepository: mockTeacherRepository,
  );

  test('initial state is TeacherInitial', () {
    final bloc = buildBloc();
    expect(bloc.state, isA<TeacherInitial>());
    bloc.close();
  });

  // ══════════════════════════════════════════════════════════════════
  //  LoadSubjects
  // ══════════════════════════════════════════════════════════════════

  group('LoadSubjects', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, SubjectsLoaded] on success',
      build: () {
        when(
          () => mockGetSubjects(tTeacherId),
        ).thenAnswer((_) async => Right([tSubject]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadSubjects(tTeacherId)),
      expect: () => [isA<TeacherLoading>(), isA<SubjectsLoaded>()],
    );

    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockGetSubjects(tTeacherId),
        ).thenAnswer((_) async => Left(ServerFailure('Lỗi server')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadSubjects(tTeacherId)),
      expect: () => [isA<TeacherLoading>(), isA<TeacherError>()],
      verify: (bloc) {
        final errorState = bloc.state as TeacherError;
        expect(errorState.message, 'Lỗi server');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════
  //  LoadTeacherClasses
  // ══════════════════════════════════════════════════════════════════

  group('LoadTeacherClasses', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, TeacherLoaded] on success',
      build: () {
        when(
          () => mockGetTeacherSchedules(tTeacherId),
        ).thenAnswer((_) async => Right([tSchedule]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadTeacherClasses(tTeacherId)),
      expect: () => [isA<TeacherLoading>(), isA<TeacherLoaded>()],
      verify: (bloc) {
        final loaded = bloc.state as TeacherLoaded;
        expect(loaded.schedules.length, 1);
        expect(loaded.schedules.first.subject, 'Flutter');
      },
    );

    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockGetTeacherSchedules(tTeacherId),
        ).thenAnswer((_) async => Left(ServerFailure('Network error')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadTeacherClasses(tTeacherId)),
      expect: () => [isA<TeacherLoading>(), isA<TeacherError>()],
    );
  });

  // ══════════════════════════════════════════════════════════════════
  //  CreateClassRequested
  // ══════════════════════════════════════════════════════════════════

  group('CreateClassRequested', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [ClassCreatedSuccess, Loading, TeacherLoaded] on success',
      build: () {
        when(
          () => mockCreateClass(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetTeacherSchedules(tTeacherId),
        ).thenAnswer((_) async => Right([tSchedule]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        CreateClassRequested(
          className: 'Lớp A',
          teacherId: tTeacherId,
          subjectName: 'Flutter',
          room: 'A101',
          startTime: tNow,
          endTime: tNow.add(const Duration(hours: 2)),
          startDate: tNow,
          repeatWeeks: 15,
          notificationMinutes: 30,
          credits: 3,
        ),
      ),
      expect: () => [
        isA<ClassCreatedSuccess>(),
        isA<TeacherLoading>(),
        isA<TeacherLoaded>(),
      ],
    );

    blocTest<TeacherBloc, TeacherState>(
      'emits [Error] on failure',
      build: () {
        when(
          () => mockCreateClass(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => Left(ServerFailure('Trùng tên lớp')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        CreateClassRequested(
          className: 'Lớp A',
          teacherId: tTeacherId,
          subjectName: 'Flutter',
          room: 'A101',
          startTime: tNow,
          endTime: tNow.add(const Duration(hours: 2)),
          startDate: tNow,
          repeatWeeks: 15,
          notificationMinutes: 30,
          credits: 3,
        ),
      ),
      expect: () => [isA<TeacherError>()],
    );
  });

  // ══════════════════════════════════════════════════════════════════
  //  GetStudentsInClass
  // ══════════════════════════════════════════════════════════════════

  group('GetStudentsInClass', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, StudentsLoaded] on success',
      build: () {
        when(
          () => mockGetStudentsInClass(tClassId),
        ).thenAnswer((_) async => const Right([tStudent]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetStudentsInClass(tClassId)),
      expect: () => [isA<TeacherLoading>(), isA<StudentsLoaded>()],
      verify: (bloc) {
        final loaded = bloc.state as StudentsLoaded;
        expect(loaded.students.length, 1);
        expect(loaded.students.first.studentName, 'Nguyễn Văn A');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════
  //  Assignments CRUD
  // ══════════════════════════════════════════════════════════════════

  group('LoadAssignments', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, AssignmentsLoaded] on success',
      build: () {
        when(
          () => mockGetAssignments(tTeacherId),
        ).thenAnswer((_) async => Right([tAssignment]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadAssignments(tTeacherId)),
      expect: () => [isA<TeacherLoading>(), isA<AssignmentsLoaded>()],
    );
  });

  group('CreateAssignmentRequested', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, Created, Loading, Loaded] on success',
      build: () {
        when(
          () => mockCreateAssignment(any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetAssignments(tTeacherId),
        ).thenAnswer((_) async => Right([tAssignment]));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(CreateAssignmentRequested(tAssignment, tTeacherId)),
      expect: () => [
        isA<TeacherLoading>(),
        isA<AssignmentCreatedSuccess>(),
        isA<TeacherLoading>(),
        isA<AssignmentsLoaded>(),
      ],
    );
  });

  group('DeleteAssignmentRequested', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, AssignmentsLoaded] on success (re-fetches list)',
      build: () {
        when(
          () => mockDeleteAssignment(1, tTeacherId),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetAssignments(tTeacherId),
        ).thenAnswer((_) async => const Right([]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DeleteAssignmentRequested(1, tTeacherId)),
      expect: () => [
        // bloc_test deduplicates consecutive equal states,
        // so two TeacherLoading() collapses into one
        isA<TeacherLoading>(),
        isA<AssignmentsLoaded>(),
      ],
    );
  });

  // ══════════════════════════════════════════════════════════════════
  //  Submissions & Grading
  // ══════════════════════════════════════════════════════════════════

  group('GetSubmissions', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, SubmissionsLoaded] on success',
      build: () {
        when(() => mockGetSubmissions(1)).thenAnswer(
          (_) async => const Right([
            {'id': 1, 'grade': null},
          ]),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetSubmissions(1)),
      expect: () => [isA<TeacherLoading>(), isA<SubmissionsLoaded>()],
    );
  });

  group('GradeSubmission', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, GradedSuccess] on success',
      build: () {
        when(
          () => mockGradeSubmission(1, 9.0, 'Tốt', tTeacherId),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const GradeSubmission(
          submissionId: 1,
          grade: 9.0,
          feedback: 'Tốt',
          teacherId: tTeacherId,
        ),
      ),
      expect: () => [isA<TeacherLoading>(), isA<SubmissionGradedSuccess>()],
    );

    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockGradeSubmission(1, 9.0, 'Tốt', tTeacherId),
        ).thenAnswer((_) async => Left(ServerFailure('Không tìm thấy')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const GradeSubmission(
          submissionId: 1,
          grade: 9.0,
          feedback: 'Tốt',
          teacherId: tTeacherId,
        ),
      ),
      expect: () => [isA<TeacherLoading>(), isA<TeacherError>()],
    );
  });

  // ══════════════════════════════════════════════════════════════════
  //  Attendance
  // ══════════════════════════════════════════════════════════════════

  group('MarkAttendanceRequested', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, AttendanceMarkedSuccess] on success',
      build: () {
        when(
          () => mockMarkAttendance(
            classId: tClassId,
            date: tNow,
            teacherId: tTeacherId,
            attendances: any(named: 'attendances'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        MarkAttendanceRequested(
          classId: tClassId,
          date: tNow,
          teacherId: tTeacherId,
          attendances: const [
            {'studentId': 2, 'status': 'present'},
          ],
        ),
      ),
      expect: () => [isA<TeacherLoading>(), isA<AttendanceMarkedSuccess>()],
    );
  });

  group('LoadAttendanceRecords', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, AttendanceRecordsLoaded] on success',
      build: () {
        when(
          () => mockGetAttendanceRecords(classId: tClassId, date: tNow),
        ).thenAnswer(
          (_) async => const Right([
            {'studentId': 2, 'status': 'present'},
          ]),
        );
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(LoadAttendanceRecords(classId: tClassId, date: tNow)),
      expect: () => [isA<TeacherLoading>(), isA<AttendanceRecordsLoaded>()],
    );
  });

  group('LoadAttendanceStatistics', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [AttendanceStatisticsLoaded] on success',
      build: () {
        when(() => mockGetAttendanceStatistics(tClassId)).thenAnswer(
          (_) async => const Right([
            {'studentId': 2, 'attendanceRate': 0.95},
          ]),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadAttendanceStatistics(tClassId)),
      expect: () => [isA<AttendanceStatisticsLoaded>()],
    );
  });

  // ══════════════════════════════════════════════════════════════════
  //  RegenerateCode
  // ══════════════════════════════════════════════════════════════════

  group('RegenerateCodeRequested', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [CodeRegeneratedSuccess, Loading, Loaded] on success',
      build: () {
        when(
          () => mockRegenerateClassCode(tTeacherId, 'Flutter', false),
        ).thenAnswer((_) async => const Right('NEW-CODE'));
        when(
          () => mockGetTeacherSchedules(tTeacherId),
        ).thenAnswer((_) async => Right([tSchedule]));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const RegenerateCodeRequested(tTeacherId, 'Flutter', false)),
      expect: () => [
        isA<CodeRegeneratedSuccess>(),
        isA<TeacherLoading>(),
        isA<TeacherLoaded>(),
      ],
      verify: (bloc) {
        // The first state should have been CodeRegeneratedSuccess
      },
    );

    blocTest<TeacherBloc, TeacherState>(
      'emits [Error] on failure',
      build: () {
        when(
          () => mockRegenerateClassCode(tTeacherId, 'Flutter', false),
        ).thenAnswer((_) async => Left(ServerFailure('Lỗi')));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const RegenerateCodeRequested(tTeacherId, 'Flutter', false)),
      expect: () => [isA<TeacherError>()],
    );
  });

  // ══════════════════════════════════════════════════════════════════
  //  UpdateScore
  // ══════════════════════════════════════════════════════════════════

  group('UpdateScoreRequested', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, ScoreUpdatedSuccess, Loading, Loaded] on success',
      build: () {
        when(
          () => mockUpdateScore(1, null, 8.5, null, null),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetTeacherSchedules(tTeacherId),
        ).thenAnswer((_) async => Right([tSchedule]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const UpdateScoreRequested(
          teacherId: tTeacherId,
          scheduleId: 1,
          midtermScore: 8.5,
        ),
      ),
      expect: () => [
        isA<TeacherLoading>(),
        isA<ScoreUpdatedSuccess>(),
        isA<TeacherLoading>(),
        isA<TeacherLoaded>(),
      ],
    );
  });

  // ══════════════════════════════════════════════════════════════════
  //  ImportSchedules
  // ══════════════════════════════════════════════════════════════════

  group('ImportSchedulesRequested', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, ImportSuccess, Loading, Loaded] on success',
      build: () {
        when(
          () => mockImportSchedules(tTeacherId, any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetTeacherSchedules(tTeacherId),
        ).thenAnswer((_) async => Right([tSchedule]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        ImportSchedulesRequested(tTeacherId, [
          {'subject': 'Flutter', 'room': 'A101'},
        ]),
      ),
      expect: () => [
        isA<TeacherLoading>(),
        isA<ImportSuccess>(),
        isA<TeacherLoading>(),
        isA<TeacherLoaded>(),
      ],
    );
  });

  // ══════════════════════════════════════════════════════════════════
  //  DeleteClass
  // ══════════════════════════════════════════════════════════════════

  group('DeleteClassRequested', () {
    blocTest<TeacherBloc, TeacherState>(
      'emits [Loading, ClassDeletedSuccess, Loading, Loaded] on success',
      build: () {
        when(
          () => mockDeleteSchedule(1),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetTeacherSchedules(tTeacherId),
        ).thenAnswer((_) async => const Right([]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DeleteClassRequested(1, tTeacherId)),
      expect: () => [
        isA<TeacherLoading>(),
        isA<ClassDeletedSuccess>(),
        isA<TeacherLoading>(),
        isA<TeacherLoaded>(),
      ],
    );
  });
}
