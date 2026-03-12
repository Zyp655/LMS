import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:alarmm/core/error/failures.dart';
import 'package:alarmm/features/schedule/domain/enitities/schedule_entity.dart';
import 'package:alarmm/features/teaching/domain/entities/subject_entity.dart';
import 'package:alarmm/features/teaching/domain/entities/student_entity.dart';
import 'package:alarmm/features/teaching/domain/entities/assignment_entity.dart';
import 'package:alarmm/features/teaching/domain/repositories/teacher_repository.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_teacher_schedules_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/create_class_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_students_in_class_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_subject_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_assignments_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_submissions_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/grade_submission_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/mark_attendance_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_attendance_records_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/get_attendance_statistics_usecase.dart';
import 'package:alarmm/features/teaching/domain/usecases/regenerate_class_code_usecase.dart';

class MockTeacherRepository extends Mock implements TeacherRepository {}

void main() {
  late MockTeacherRepository mockRepo;

  setUp(() {
    mockRepo = MockTeacherRepository();
  });

  final tNow = DateTime(2026, 3, 1);

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
    classId: 10,
    title: 'Bài tập 1',
    dueDate: DateTime(2026, 3, 15),
  );

  // ══════════════════════════════════════════════════════════════════
  //  GetTeacherSchedulesUseCase
  // ══════════════════════════════════════════════════════════════════

  group('GetTeacherSchedulesUseCase', () {
    late GetTeacherSchedulesUseCase useCase;
    setUp(() => useCase = GetTeacherSchedulesUseCase(mockRepo));

    test('returns list of schedules on success', () async {
      when(
        () => mockRepo.getAllSchedules(1),
      ).thenAnswer((_) async => Right([tSchedule]));

      final result = await useCase(1);

      expect(result, isA<Right>());
      result.fold((_) => fail('should be Right'), (list) {
        expect(list.length, 1);
        expect(list.first.subject, 'Flutter');
      });
      verify(() => mockRepo.getAllSchedules(1)).called(1);
    });

    test('returns failure on error', () async {
      when(
        () => mockRepo.getAllSchedules(1),
      ).thenAnswer((_) async => Left(ServerFailure('Error')));

      final result = await useCase(1);

      expect(result, isA<Left>());
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  CreateClassUseCase
  // ══════════════════════════════════════════════════════════════════

  group('CreateClassUseCase', () {
    late CreateClassUseCase useCase;
    setUp(() => useCase = CreateClassUseCase(mockRepo));

    test('delegates to repository correctly', () async {
      when(
        () => mockRepo.createClass(
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

      final result = await useCase(
        'Lớp A',
        1,
        'Flutter',
        'A101',
        tNow,
        tNow,
        tNow,
        15,
        30,
        3,
      );

      expect(result, isA<Right>());
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  GetSubjectsUseCase
  // ══════════════════════════════════════════════════════════════════

  group('GetSubjectsUseCase', () {
    late GetSubjectsUseCase useCase;
    setUp(() => useCase = GetSubjectsUseCase(mockRepo));

    test('returns subjects on success', () async {
      when(
        () => mockRepo.getSubjects(1),
      ).thenAnswer((_) async => Right([tSubject]));

      final result = await useCase(1);

      result.fold((_) => fail('should be Right'), (subjects) {
        expect(subjects.length, 1);
        expect(subjects.first.name, 'Flutter');
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  GetStudentsInClassUseCase
  // ══════════════════════════════════════════════════════════════════

  group('GetStudentsInClassUseCase', () {
    late GetStudentsInClassUseCase useCase;
    setUp(() => useCase = GetStudentsInClassUseCase(mockRepo));

    test('returns students on success', () async {
      when(
        () => mockRepo.getStudentsInClass(10),
      ).thenAnswer((_) async => const Right([tStudent]));

      final result = await useCase(10);

      result.fold((_) => fail('should be Right'), (students) {
        expect(students.length, 1);
        expect(students.first.studentId, 'SV001');
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  GetAssignmentsUseCase
  // ══════════════════════════════════════════════════════════════════

  group('GetAssignmentsUseCase', () {
    late GetAssignmentsUseCase useCase;
    setUp(() => useCase = GetAssignmentsUseCase(mockRepo));

    test('returns assignments on success', () async {
      when(
        () => mockRepo.getAssignments(1),
      ).thenAnswer((_) async => Right([tAssignment]));

      final result = await useCase(1);

      result.fold((_) => fail('should be Right'), (list) {
        expect(list.first.title, 'Bài tập 1');
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  GetSubmissionsUseCase
  // ══════════════════════════════════════════════════════════════════

  group('GetSubmissionsUseCase', () {
    late GetSubmissionsUseCase useCase;
    setUp(() => useCase = GetSubmissionsUseCase(mockRepo));

    test('returns submissions on success', () async {
      when(() => mockRepo.getSubmissions(1)).thenAnswer(
        (_) async => const Right([
          {'id': 1, 'grade': 8.5},
        ]),
      );

      final result = await useCase(1);

      result.fold((_) => fail('should be Right'), (subs) {
        expect(subs.length, 1);
        expect(subs.first['grade'], 8.5);
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  GradeSubmissionUseCase
  // ══════════════════════════════════════════════════════════════════

  group('GradeSubmissionUseCase', () {
    late GradeSubmissionUseCase useCase;
    setUp(() => useCase = GradeSubmissionUseCase(mockRepo));

    test('returns Right on success', () async {
      when(
        () => mockRepo.gradeSubmission(1, 9.0, 'Good', 1),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(1, 9.0, 'Good', 1);

      expect(result, isA<Right>());
      verify(() => mockRepo.gradeSubmission(1, 9.0, 'Good', 1)).called(1);
    });

    test('returns Left on failure', () async {
      when(
        () => mockRepo.gradeSubmission(1, 9.0, null, 1),
      ).thenAnswer((_) async => Left(ServerFailure('Not found')));

      final result = await useCase(1, 9.0, null, 1);

      expect(result, isA<Left>());
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  MarkAttendanceUseCase
  // ══════════════════════════════════════════════════════════════════

  group('MarkAttendanceUseCase', () {
    late MarkAttendanceUseCase useCase;
    setUp(() => useCase = MarkAttendanceUseCase(mockRepo));

    test('passes named params correctly', () async {
      when(
        () => mockRepo.markAttendance(
          classId: 10,
          date: tNow,
          teacherId: 1,
          attendances: any(named: 'attendances'),
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        classId: 10,
        date: tNow,
        teacherId: 1,
        attendances: const [
          {'studentId': 2, 'status': 'present'},
        ],
      );

      expect(result, isA<Right>());
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  GetAttendanceRecordsUseCase
  // ══════════════════════════════════════════════════════════════════

  group('GetAttendanceRecordsUseCase', () {
    late GetAttendanceRecordsUseCase useCase;
    setUp(() => useCase = GetAttendanceRecordsUseCase(mockRepo));

    test('returns records on success', () async {
      when(
        () => mockRepo.getAttendanceRecords(classId: 10, date: tNow),
      ).thenAnswer(
        (_) async => const Right([
          {'studentId': 2, 'status': 'present'},
        ]),
      );

      final result = await useCase(classId: 10, date: tNow);

      result.fold((_) => fail('should be Right'), (records) {
        expect(records.length, 1);
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  GetAttendanceStatisticsUseCase
  // ══════════════════════════════════════════════════════════════════

  group('GetAttendanceStatisticsUseCase', () {
    late GetAttendanceStatisticsUseCase useCase;
    setUp(() => useCase = GetAttendanceStatisticsUseCase(mockRepo));

    test('returns statistics on success', () async {
      when(() => mockRepo.getAttendanceStatistics(10)).thenAnswer(
        (_) async => const Right([
          {'studentId': 2, 'attendanceRate': 0.95},
        ]),
      );

      final result = await useCase(10);

      result.fold((_) => fail('should be Right'), (stats) {
        expect(stats.first['attendanceRate'], 0.95);
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════
  //  RegenerateClassCodeUseCase
  // ══════════════════════════════════════════════════════════════════

  group('RegenerateClassCodeUseCase', () {
    late RegenerateClassCodeUseCase useCase;
    setUp(() => useCase = RegenerateClassCodeUseCase(mockRepo));

    test('wraps repo result in Right on success', () async {
      when(
        () => mockRepo.regenerateClassCode(1, 'Flutter', false),
      ).thenAnswer((_) async => 'NEW-CODE');

      final result = await useCase(1, 'Flutter', false);

      result.fold((_) => fail('should be Right'), (code) {
        expect(code, 'NEW-CODE');
      });
    });

    test('wraps exception in Left(ServerFailure) on error', () async {
      when(
        () => mockRepo.regenerateClassCode(1, 'X', false),
      ).thenThrow(Exception('Server down'));

      final result = await useCase(1, 'X', false);

      expect(result, isA<Left>());
    });
  });
}
