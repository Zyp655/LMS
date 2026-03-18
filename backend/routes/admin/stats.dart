import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  try {
    final db = context.read<AppDatabase>();

    final totalUsers = await (db.selectOnly(db.users)
          ..addColumns([countAll()]))
        .map((row) => row.read(countAll()))
        .getSingle();

    final students = await (db.selectOnly(db.users)
          ..addColumns([countAll()])
          ..where(db.users.role.equals(0)))
        .map((row) => row.read(countAll()))
        .getSingle();

    final teachers = await (db.selectOnly(db.users)
          ..addColumns([countAll()])
          ..where(db.users.role.equals(1)))
        .map((row) => row.read(countAll()))
        .getSingle();

    final admins = await (db.selectOnly(db.users)
          ..addColumns([countAll()])
          ..where(db.users.role.equals(2)))
        .map((row) => row.read(countAll()))
        .getSingle();

    final banned = await (db.selectOnly(db.users)
          ..addColumns([countAll()])
          ..where(db.users.isBanned.equals(true)))
        .map((row) => row.read(countAll()))
        .getSingle();

    final totalCourses = await (db.selectOnly(db.courses)
          ..addColumns([countAll()]))
        .map((row) => row.read(countAll()))
        .getSingle();

    final publishedCourses = await (db.selectOnly(db.courses)
          ..addColumns([countAll()])
          ..where(db.courses.isPublished.equals(true)))
        .map((row) => row.read(countAll()))
        .getSingle();

    final totalEnrollments = await (db.selectOnly(db.enrollments)
          ..addColumns([countAll()]))
        .map((row) => row.read(countAll()))
        .getSingle();

    final departments = await db.select(db.departments).get();
    final deptStats = <Map<String, dynamic>>[];
    for (final dept in departments) {
      final deptStudents = await (db.selectOnly(db.users)
            ..addColumns([countAll()])
            ..where(db.users.role.equals(0) & db.users.departmentId.equals(dept.id)))
          .map((row) => row.read(countAll()))
          .getSingle();
      final deptTeachers = await (db.selectOnly(db.users)
            ..addColumns([countAll()])
            ..where(db.users.role.equals(1) & db.users.departmentId.equals(dept.id)))
          .map((row) => row.read(countAll()))
          .getSingle();
      deptStats.add({
        'id': dept.id,
        'name': dept.name,
        'code': dept.code,
        'students': deptStudents,
        'teachers': deptTeachers,
      });
    }

    return Response.json(body: {
      'totalUsers': totalUsers,
      'students': students,
      'teachers': teachers,
      'admins': admins,
      'banned': banned,
      'totalCourses': totalCourses,
      'publishedCourses': publishedCourses,
      'totalEnrollments': totalEnrollments,
      'departments': deptStats,
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': 'Error: $e'},
    );
  }
}
