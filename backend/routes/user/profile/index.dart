import 'package:backend/database/database.dart';
import 'package:backend/repositories/student_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  final userId = context.read<int>();
  final repo = context.read<StudentRepository>();
  final db = context.read<AppDatabase>();

  if (context.request.method == HttpMethod.get) {
    final user = await (db.select(db.users)..where((t) => t.id.equals(userId)))
        .getSingleOrNull();
    if (user == null) {
      return Response.json(body: {});
    }

    final isTeacher = user.role == 1 || user.role == 2;

    if (isTeacher) {
      String? departmentName;
      String? teacherCode;
      if (user.departmentId != null) {
        final dept = await (db.select(db.departments)
              ..where((t) => t.id.equals(user.departmentId!)))
            .getSingleOrNull();
        departmentName = dept?.name;
      }

      teacherCode = user.resetToken;

      return Response.json(body: {
        'fullName': user.fullName,
        'department': departmentName,
        'teacherId': teacherCode,
      });
    } else {
      final profile = await repo.getProfile(userId);
      if (profile == null) {
        return Response.json(body: {});
      }
      return Response.json(body: {
        'fullName': profile.fullName,
        'studentId': profile.studentId,
        'major': profile.major,
        'avatarUrl': profile.avatarUrl,
      });
    }
  }

  if (context.request.method == HttpMethod.post) {
    final body = await context.request.json() as Map<String, dynamic>;
    final user = await (db.select(db.users)..where((t) => t.id.equals(userId)))
        .getSingleOrNull();
    final isTeacher = user != null && (user.role == 1 || user.role == 2);

    if (isTeacher) {
      final department = body['department'] as String? ?? '';
      final teacherId = body['teacherId'] as String? ?? '';

      int? departmentId;
      if (department.isNotEmpty) {
        final dept = await (db.select(db.departments)
              ..where((t) => t.name.equals(department)))
            .getSingleOrNull();
        departmentId = dept?.id;
      }

      await (db.update(db.users)..where((t) => t.id.equals(userId))).write(
        UsersCompanion(
          fullName: Value(body['fullName'] as String? ?? user.fullName ?? ''),
          resetToken:
              teacherId.isNotEmpty ? Value(teacherId) : const Value.absent(),
          departmentId:
              departmentId != null ? Value(departmentId) : const Value.absent(),
        ),
      );
      return Response.json(body: {'message': 'Cập nhật hồ sơ thành công'});
    } else {
      await repo.updateProfile(
        userId,
        body['fullName'] as String,
        body['studentId'] as String? ?? '',
        body['major'] as String? ?? '',
      );
      return Response.json(body: {'message': 'Cập nhật hồ sơ thành công'});
    }
  }

  return Response(statusCode: 405);
}
