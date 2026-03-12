import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../schedule/domain/enitities/schedule_entity.dart';
import '../entities/subject_entity.dart';
import '../entities/student_entity.dart';
import '../entities/assignment_entity.dart';

abstract class TeacherRepository {
  Future<Either<Failure, List<AssignmentEntity>>> getAssignments(int teacherId);

  Future<Either<Failure, void>> createAssignment(
    AssignmentEntity assignment,
    int teacherId,
  );

  Future<Either<Failure, void>> updateAssignment(
    AssignmentEntity assignment,
    int teacherId,
  );

  Future<Either<Failure, void>> deleteAssignment(
    int assignmentId,
    int teacherId,
  );
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
  );

  Future<Either<Failure, List<ScheduleEntity>>> getAllSchedules(int teacherId);

  Future<Either<Failure, void>> updateScore(
    int scheduleId,
    int? absences,
    double? midtermScore,
    double? finalScore,
    double? examScore,
  );

  Future<Either<Failure, void>> importSchedules(
    int teacherId,
    List<Map<String, dynamic>> schedules,
  );

  Future<String> regenerateClassCode(
    int teacherId,
    String subjectName,
    bool isRefresh,
  );

  Future<Either<Failure, List<SubjectEntity>>> getSubjects(int teacherId);

  Future<Either<Failure, void>> createSubject(
    int teacherId,
    String name,
    int credits,
    String? code,
  );

  Future<Either<Failure, List<StudentEntity>>> getStudentsInClass(int classId);

  Future<Either<Failure, List<Map<String, dynamic>>>> getSubmissions(
    int assignmentId,
  );

  Future<Either<Failure, void>> gradeSubmission(
    int submissionId,
    double grade,
    String? feedback,
    int teacherId,
  );

  Future<Either<Failure, void>> markAttendance({
    required int classId,
    required DateTime date,
    required int teacherId,
    required List<Map<String, dynamic>> attendances,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getAttendanceRecords({
    required int classId,
    required DateTime date,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getAttendanceStatistics(
    int classId,
  );

  Future<Either<Failure, Map<String, dynamic>>> enrollStudentsByIdentifier(
    int classId,
    int teacherId,
    List<String> identifiers,
  );
}
