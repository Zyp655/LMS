import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class AdminRepository {
  Future<Either<Failure, Map<String, dynamic>>> getUsers({
    int? role,
    String? search,
    int? departmentId,
    String? studentClass,
  });

  Future<Either<Failure, String>> updateUser(
    int userId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, String>> deleteUser(int userId);

  Future<Either<Failure, String>> toggleBan(int userId);

  Future<Either<Failure, List<Map<String, dynamic>>>> getAdminCourses({
    String? search,
  });

  Future<Either<Failure, String>> togglePublish(int courseId, bool current);

  Future<Either<Failure, String>> deleteCourse(int courseId);

  Future<Either<Failure, Map<String, dynamic>>> getAnalytics();

  Future<Either<Failure, Map<String, dynamic>>> getAcademicData();

  Future<Either<Failure, String>> seedUsers();

  Future<Either<Failure, String>> seedAchievements();

  Future<Either<Failure, String>> seedRoadmap();

  Future<Either<Failure, String>> assignRoadmapTeacher(String teacherEmail);

  Future<Either<Failure, String>> importStudents(Map<String, dynamic> payload);

  Future<Either<Failure, String>> importTeachers(Map<String, dynamic> payload);

  Future<Either<Failure, String>> importSubjects(Map<String, dynamic> payload);

  Future<Either<Failure, List<Map<String, dynamic>>>>
  getAcademicCoursesWithTeachers();

  Future<Either<Failure, String>> createCourseClass(
    int academicCourseId,
    String classCode, {
    String? room,
    String? schedule,
    int? maxStudents,
  });

  Future<Either<Failure, Map<String, dynamic>>> assignCourseTeacher(
    int courseClassId,
    int teacherId, {
    bool force,
  });

  Future<Either<Failure, String>> unassignCourseTeacher(int courseClassId);
}
