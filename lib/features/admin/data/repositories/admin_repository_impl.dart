import 'package:dartz/dartz.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final ApiClient apiClient;

  AdminRepositoryImpl({required this.apiClient});

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUsers({
    int? role,
    String? search,
    int? departmentId,
    String? studentClass,
  }) async {
    try {
      var path = '/admin/users';
      final params = <String>[];
      if (role != null) params.add('role=$role');
      if (search != null && search.isNotEmpty) params.add('search=$search');
      if (departmentId != null) params.add('departmentId=$departmentId');
      if (studentClass != null && studentClass.isNotEmpty) {
        params.add('studentClass=${Uri.encodeComponent(studentClass)}');
      }
      if (params.isNotEmpty) path += '?${params.join('&')}';
      final response = await apiClient.get(path);
      return Right(response);
    } catch (e) {
      return Left(ServerFailure('Lỗi tải danh sách: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> updateUser(
    int userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await apiClient.put('/admin/users/$userId', data);
      return const Right('Cập nhật thành công');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> deleteUser(int userId) async {
    try {
      final response = await apiClient.delete('/admin/users/$userId');
      return Right(response['message'] as String? ?? 'Đã xoá');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> toggleBan(int userId) async {
    try {
      final response = await apiClient.post('/admin/users/$userId/ban', {});
      return Right(response['message'] as String? ?? 'Thành công');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAdminCourses({
    String? search,
  }) async {
    try {
      var path = '/courses?limit=100';
      if (search != null && search.isNotEmpty) path += '&search=$search';
      final response = await apiClient.get(path);
      final courses = List<Map<String, dynamic>>.from(
        response['courses'] ?? [],
      );
      return Right(courses);
    } catch (e) {
      return Left(ServerFailure('Lỗi tải môn học: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> togglePublish(
    int courseId,
    bool current,
  ) async {
    try {
      await apiClient.put('/courses/$courseId', {'isPublished': !current});
      return Right(current ? 'Đã ẩn môn học' : 'Đã xuất bản môn học');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> deleteCourse(int courseId) async {
    try {
      await apiClient.delete('/courses/$courseId');
      return const Right('Đã xoá môn học');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAnalytics() async {
    try {
      final usersRes = await apiClient.get('/admin/users?limit=9999');
      final courseRes = await apiClient.get('/courses?limit=9999');
      final allUsers = List<Map<String, dynamic>>.from(usersRes['users'] ?? []);
      final allCourses = List<Map<String, dynamic>>.from(
        courseRes['courses'] ?? [],
      );

      final students = allUsers.where((u) => u['role'] == 0).length;
      final teachers = allUsers.where((u) => u['role'] == 1).length;
      final admins = allUsers.where((u) => u['role'] == 2).length;
      final banned = allUsers.where((u) => u['isBanned'] == true).length;
      final published = allCourses
          .where((c) => c['isPublished'] == true)
          .length;
      final totalEnrollments = allCourses.fold<int>(
        0,
        (sum, c) => sum + ((c['studentCount'] as int?) ?? 0),
      );

      return Right({
        'totalUsers': allUsers.length,
        'students': students,
        'teachers': teachers,
        'admins': admins,
        'banned': banned,
        'totalCourses': allCourses.length,
        'publishedCourses': published,
        'totalEnrollments': totalEnrollments,
      });
    } catch (e) {
      return Left(ServerFailure('Lỗi tải thống kê: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAcademicData() async {
    try {
      final deptRes = await apiClient.get('/academic/departments');
      final semRes = await apiClient.get('/academic/semesters');
      final courseRes = await apiClient.get('/academic/courses');
      final classRes = await apiClient.get('/academic/classes');
      return Right({
        'departments': List<Map<String, dynamic>>.from(
          deptRes['departments'] ?? [],
        ),
        'semesters': List<Map<String, dynamic>>.from(semRes['semesters'] ?? []),
        'courses': List<Map<String, dynamic>>.from(courseRes['courses'] ?? []),
        'classes': List<Map<String, dynamic>>.from(classRes['classes'] ?? []),
      });
    } catch (e) {
      return Left(ServerFailure('Lỗi tải dữ liệu học thuật: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> seedUsers() async {
    try {
      final response = await apiClient.post('/admin/seed-users', {});
      return Right(response['message'] as String? ?? 'Seed xong!');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> seedAchievements() async {
    try {
      final response = await apiClient.post('/admin/seed-achievements', {});
      return Right(response['message'] as String? ?? 'Seed achievements xong!');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> seedRoadmap() async {
    try {
      final response = await apiClient.post('/admin/seed_roadmap_courses', {});
      return Right(response['message'] as String? ?? 'Seed roadmap xong!');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> assignRoadmapTeacher(
    String teacherEmail,
  ) async {
    try {
      final response = await apiClient.post('/admin/assign_roadmap_teacher', {
        'teacherEmail': teacherEmail,
      });
      final count = response['updatedCoursesCount'] ?? 0;
      final name = response['teacherName'] ?? '';
      return Right('Đã gán $count môn học cho $name');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> importStudents(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await apiClient.post('/admin/import-students', payload);
      final created = response['created'] ?? 0;
      final skipped = response['skipped'] ?? 0;
      final errors = List<String>.from(response['errors'] ?? []);
      var msg = 'Import: $created tạo mới, $skipped bỏ qua';
      if (errors.isNotEmpty) {
        msg += '\n⚠️ Lỗi:\n${errors.join('\n')}';
      }
      return Right(msg);
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> importTeachers(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await apiClient.post('/admin/import-teachers', payload);
      final created = response['created'] ?? 0;
      final skipped = response['skipped'] ?? 0;
      final errors = List<String>.from(response['errors'] ?? []);
      var msg = 'Import GV: $created tạo mới, $skipped cập nhật';
      if (errors.isNotEmpty) {
        msg += '\n Lỗi:\n${errors.join('\n')}';
      }
      return Right(msg);
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> importSubjects(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await apiClient.post('/admin/import-subjects', payload);
      final created = response['created'] ?? 0;
      final skipped = response['skipped'] ?? 0;
      final errors = List<String>.from(response['errors'] ?? []);
      var msg = 'Import: $created tạo mới, $skipped bỏ qua';
      if (errors.isNotEmpty) {
        msg += '\n Lỗi:\n${errors.join('\n')}';
      }
      return Right(msg);
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getAcademicCoursesWithTeachers() async {
    try {
      final response = await apiClient.get('/admin/academic-courses');
      final courses = List<Map<String, dynamic>>.from(
        response['courses'] ?? [],
      );
      return Right(courses);
    } catch (e) {
      return Left(ServerFailure('Lỗi tải danh sách môn học: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> createCourseClass(
    int academicCourseId,
    String classCode, {
    String? room,
    String? schedule,
    int? maxStudents,
  }) async {
    try {
      final body = <String, dynamic>{
        'academicCourseId': academicCourseId,
        'classCode': classCode,
      };
      if (room != null) body['room'] = room;
      if (schedule != null) body['schedule'] = schedule;
      if (maxStudents != null) body['maxStudents'] = maxStudents;
      final response = await apiClient.post('/admin/create-course-class', body);
      return Right(response['message'] as String? ?? 'Tạo lớp thành công');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> assignCourseTeacher(
    int courseClassId,
    int teacherId, {
    bool force = false,
  }) async {
    try {
      final response = await apiClient.post('/admin/assign-course-teacher', {
        'courseClassId': courseClassId,
        'teacherId': teacherId,
        'force': force,
      });
      return Right(response);
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> unassignCourseTeacher(
    int courseClassId,
  ) async {
    try {
      final response = await apiClient.post('/admin/unassign-course-teacher', {
        'courseClassId': courseClassId,
      });
      return Right(response['message'] as String? ?? 'Đã bỏ phân công');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }
}
