import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../schedule/domain/enitities/schedule_entity.dart';
import '../../domain/entities/subject_entity.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/teacher_remote_data_source.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/entities/assignment_entity.dart';
import '../models/assignment_model.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  final TeacherRemoteDataSource remoteDataSource;

  TeacherRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<SubjectEntity>>> getSubjects(
    int teacherId,
  ) async {
    try {
      final result = await remoteDataSource.getSubjects(teacherId);
      return Right(result);
    } on ServerException {
      return Left(ServerFailure("Không thể tải danh sách môn học"));
    }
  }

  @override
  Future<Either<Failure, void>> createSubject(
    int teacherId,
    String name,
    int credits,
    String? code,
  ) async {
    try {
      await remoteDataSource.createSubject(teacherId, name, credits, code);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> createClass(
    String className,
    int teacherId,
    String subjectName,
    String room,
    DateTime startTime,
    DateTime endTime,
    DateTime startDate,
    int repeatWeeks,
    int notificationMinutes,
    int credits,
  ) async {
    try {
      await remoteDataSource.createClass(
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
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ScheduleEntity>>> getAllSchedules(
    int teacherId,
  ) async {
    try {
      final result = await remoteDataSource.getAllSchedules(teacherId);
      return Right(result);
    } on ServerException {
      return Left(ServerFailure("Không thể tải danh sách lớp"));
    }
  }

  @override
  Future<Either<Failure, void>> updateScore(
    int scheduleId,
    int? absences,
    double? midtermScore,
    double? finalScore,
    double? examScore,
  ) async {
    try {
      await remoteDataSource.updateScore(
        scheduleId,
        absences,
        midtermScore,
        finalScore,
        examScore,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> importSchedules(
    int teacherId,
    List<Map<String, dynamic>> schedules,
  ) async {
    try {
      await remoteDataSource.importSchedules(teacherId, schedules);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Lỗi không xác định khi import lịch'));
    }
  }

  @override
  Future<String> regenerateClassCode(
    int teacherId,
    String subjectName,
    bool isRefresh,
  ) async {
    try {
      return await remoteDataSource.regenerateClassCode(
        teacherId,
        subjectName,
        isRefresh,
      );
    } catch (e) {
      throw Exception("Lỗi Repository: $e");
    }
  }

  @override
  Future<Either<Failure, List<StudentEntity>>> getStudentsInClass(
    int classId,
  ) async {
    try {
      final result = await remoteDataSource.getStudentsInClass(classId);
      final entities = result.map((e) {
        return StudentEntity(
          scheduleId: e['id'],
          userId: e['userId'],
          studentName: e['fullName'] ?? 'Unknown',
          studentId: e['studentId'] ?? '',
          email: e['email'] ?? '',
          currentAbsences: e['currentAbsences'] ?? 0,
          maxAbsences: e['maxAbsences'] ?? 0,
          midtermScore: (e['midtermScore'] as num?)?.toDouble(),
          finalScore: (e['finalScore'] as num?)?.toDouble(),
          examScore: (e['examScore'] as num?)?.toDouble(),
          targetScore: (e['targetScore'] as num).toDouble(),
        );
      }).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<AssignmentEntity>>> getAssignments(
    int teacherId,
  ) async {
    try {
      final result = await remoteDataSource.getAssignments(teacherId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> createAssignment(
    AssignmentEntity assignment,
    int teacherId,
  ) async {
    try {
      final model = AssignmentModel(
        id: assignment.id ?? 0,
        classId: assignment.classId,
        title: assignment.title,
        description: assignment.description,
        dueDate: assignment.dueDate,
        rewardPoints: assignment.rewardPoints,
        createdAt: assignment.createdAt ?? DateTime.now(),
      );
      await remoteDataSource.createAssignment(model, teacherId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateAssignment(
    AssignmentEntity assignment,
    int teacherId,
  ) async {
    try {
      final model = AssignmentModel(
        id: assignment.id ?? 0,
        classId: assignment.classId,
        title: assignment.title,
        description: assignment.description,
        dueDate: assignment.dueDate,
        rewardPoints: assignment.rewardPoints,
        createdAt: assignment.createdAt ?? DateTime.now(),
      );
      await remoteDataSource.updateAssignment(model, teacherId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAssignment(
    int assignmentId,
    int teacherId,
  ) async {
    try {
      await remoteDataSource.deleteAssignment(assignmentId, teacherId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSubmissions(
    int assignmentId,
  ) async {
    try {
      final result = await remoteDataSource.getSubmissions(assignmentId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> gradeSubmission(
    int submissionId,
    double grade,
    String? feedback,
    int teacherId,
  ) async {
    try {
      await remoteDataSource.gradeSubmission(
        submissionId: submissionId,
        teacherId: teacherId,
        grade: grade,
        feedback: feedback,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> markAttendance({
    required int classId,
    required DateTime date,
    required int teacherId,
    required List<Map<String, dynamic>> attendances,
  }) async {
    try {
      await remoteDataSource.markAttendance(
        classId: classId,
        date: date,
        teacherId: teacherId,
        attendances: attendances,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAttendanceRecords({
    required int classId,
    required DateTime date,
  }) async {
    try {
      final result = await remoteDataSource.getAttendanceRecords(
        classId: classId,
        date: date,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAttendanceStatistics(
    int classId,
  ) async {
    try {
      final result = await remoteDataSource.getAttendanceStatistics(classId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> enrollStudentsByIdentifier(
    int classId,
    int teacherId,
    List<String> identifiers,
  ) async {
    try {
      final result = await remoteDataSource.enrollStudentsByIdentifier(
        classId,
        teacherId,
        identifiers,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
