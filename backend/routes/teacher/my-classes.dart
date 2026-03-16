import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final params = context.request.uri.queryParameters;
  final teacherIdStr = params['teacherId'];
  if (teacherIdStr == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'teacherId is required'},
    );
  }
  final teacherId = int.tryParse(teacherIdStr);
  if (teacherId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'teacherId must be an integer'},
    );
  }

  final db = context.read<AppDatabase>();

  final classes = await (db.select(db.courseClasses)
        ..where((c) => c.teacherId.equals(teacherId)))
      .get();

  if (classes.isEmpty) {
    return Response.json(body: []);
  }

  final courseIds = classes.map((c) => c.academicCourseId).toSet();
  final semesterIds = classes.map((c) => c.semesterId).toSet();

  final courses = await (db.select(db.academicCourses)
        ..where((c) => c.id.isIn(courseIds)))
      .get();
  final courseMap = {for (final c in courses) c.id: c};

  final semesters = await (db.select(db.semesters)
        ..where((s) => s.id.isIn(semesterIds)))
      .get();
  final semMap = {for (final s in semesters) s.id: s};

  final departments = await db.select(db.departments).get();
  final deptMap = {for (final d in departments) d.id: d};

  final enrollments = await db.select(db.courseClassEnrollments).get();
  final enrollCountMap = <int, int>{};
  for (final e in enrollments) {
    enrollCountMap[e.courseClassId] =
        (enrollCountMap[e.courseClassId] ?? 0) + 1;
  }

  final result = classes.map((cc) {
    final course = courseMap[cc.academicCourseId];
    final semester = semMap[cc.semesterId];
    final dept = course != null ? deptMap[course.departmentId] : null;

    return {
      'id': cc.id,
      'academicCourseId': cc.academicCourseId,
      'courseName': course?.name ?? '',
      'courseCode': course?.code ?? '',
      'credits': course?.credits ?? 3,
      'classCode': cc.classCode,
      'semesterId': cc.semesterId,
      'semester': semester?.name ?? '',
      'departmentId': course?.departmentId,
      'department': dept?.name ?? '',
      'room': cc.room,
      'schedule': cc.schedule,
      'dayOfWeek': cc.dayOfWeek,
      'startDate': cc.startDate?.toIso8601String(),
      'endDate': cc.endDate?.toIso8601String(),
      'maxStudents': cc.maxStudents,
      'studentCount': enrollCountMap[cc.id] ?? 0,
    };
  }).toList();

  return Response.json(body: result);
}
