import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }

  try {
    final db = context.read<AppDatabase>();

    final courses = await db.select(db.academicCourses).get();
    final departments = await db.select(db.departments).get();
    final courseClasses = await db.select(db.courseClasses).get();

    final teachers =
        await (db.select(db.users)..where((u) => u.role.equals(1))).get();

    final deptMap = {for (final d in departments) d.id: d};
    final teacherMap = {for (final t in teachers) t.id: t};

    final result = courses.map((c) {
      final dept = deptMap[c.departmentId];
      final assignedClasses =
          courseClasses.where((cc) => cc.academicCourseId == c.id).toList();

      final assignedTeachers = assignedClasses.map((cc) {
        final teacher = teacherMap[cc.teacherId];
        return {
          'courseClassId': cc.id,
          'teacherId': cc.teacherId,
          'teacherName': teacher?.fullName ?? 'Unknown',
          'teacherEmail': teacher?.email ?? '',
          'classCode': cc.classCode,
          'room': cc.room,
          'schedule': cc.schedule,
          'dayOfWeek': cc.dayOfWeek,
          'startDate': cc.startDate?.toIso8601String(),
          'endDate': cc.endDate?.toIso8601String(),
        };
      }).toList();

      return {
        'id': c.id,
        'name': c.name,
        'code': c.code,
        'credits': c.credits,
        'departmentId': c.departmentId,
        'departmentName': dept?.name ?? '',
        'departmentCode': dept?.code ?? '',
        'description': c.description,
        'courseType': c.courseType,
        'isPublished': c.isPublished,
        'assignedTeachers': assignedTeachers,
        'teacherCount': assignedTeachers.length,
      };
    }).toList();

    return Response.json(body: {'success': true, 'courses': result});
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'success': false, 'error': '$e'}),
    );
  }
}
