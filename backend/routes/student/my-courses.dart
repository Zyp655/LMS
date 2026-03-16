import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getMyClasses(context);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getMyClasses(RequestContext context) async {
  try {
    final db = context.read<AppDatabase>();
    final params = context.request.uri.queryParameters;
    final userId = int.tryParse(params['userId'] ?? '');
    final semesterId = int.tryParse(params['semesterId'] ?? '');
    final status = params['status'];

    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'userId là bắt buộc'},
      );
    }

    var query = db.select(db.courseClassEnrollments)
      ..where((e) => e.studentId.equals(userId));

    if (status != null) {
      query = query..where((e) => e.status.equals(status));
    }

    final enrollments = await query.get();

    final results = <Map<String, dynamic>>[];
    for (final enrollment in enrollments) {

      final cls = await (db.select(db.courseClasses)
            ..where((c) => c.id.equals(enrollment.courseClassId)))
          .getSingleOrNull();
      if (cls == null) continue;

      if (semesterId != null && cls.semesterId != semesterId) continue;

      final course = await (db.select(db.academicCourses)
            ..where((c) => c.id.equals(cls.academicCourseId)))
          .getSingleOrNull();
      if (course == null) continue;

      final teacher = cls.teacherId != null
          ? await (db.select(db.users)
                ..where((u) => u.id.equals(cls.teacherId!)))
              .getSingleOrNull()
          : null;

      final semester = await (db.select(db.semesters)
            ..where((s) => s.id.equals(cls.semesterId)))
          .getSingleOrNull();

      final dept = await (db.select(db.departments)
            ..where((d) => d.id.equals(course.departmentId)))
          .getSingleOrNull();

      final enrolledCount = await (db.selectOnly(db.courseClassEnrollments)
            ..addColumns([db.courseClassEnrollments.id.count()])
            ..where(
              db.courseClassEnrollments.courseClassId.equals(cls.id) &
                  db.courseClassEnrollments.status.equals('enrolled'),
            ))
          .map((row) => row.read(db.courseClassEnrollments.id.count()) ?? 0)
          .getSingle();

      final moduleCount = await (db.selectOnly(db.modules)
            ..addColumns([db.modules.id.count()])
            ..where(db.modules.academicCourseId.equals(course.id)))
          .map((row) => row.read(db.modules.id.count()) ?? 0)
          .getSingle();

      results.add({
        'enrollmentId': enrollment.id,
        'status': enrollment.status,
        'source': enrollment.source,
        'progressPercent': enrollment.progressPercent,
        'enrolledAt': enrollment.enrolledAt.toIso8601String(),
        'completedAt': enrollment.completedAt?.toIso8601String(),
        'courseClass': {
          'id': cls.id,
          'classCode': cls.classCode,
          'room': cls.room,
          'schedule': cls.schedule,
          'dayOfWeek': cls.dayOfWeek,
          'startDate': cls.startDate?.toIso8601String(),
          'endDate': cls.endDate?.toIso8601String(),
          'maxStudents': cls.maxStudents,
          'enrolledCount': enrolledCount,
        },
        'course': {
          'id': course.id,
          'name': course.name,
          'code': course.code,
          'credits': course.credits,
          'courseType': course.courseType,
          'description': course.description,
          'thumbnailUrl': course.thumbnailUrl,
          'departmentName': dept?.name,
          'moduleCount': moduleCount,
        },
        'teacherName': teacher?.fullName ?? teacher?.email ?? 'N/A',
        'semesterName': semester?.name,
      });
    }

    return Response.json(body: {
      'enrollments': results,
      'total': results.length,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Lỗi khi tải danh sách môn học: $e'},
    );
  }
}
