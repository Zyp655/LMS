import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:backend/database/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final db = context.read<AppDatabase>();
    final activities = <Map<String, dynamic>>[];

    final allDepts = await db.select(db.departments).get();
    final deptMap = <int, String>{};
    for (final d in allDepts) {
      deptMap[d.id] = d.name;
    }

    final recentDepts = await (db.select(db.departments)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(3))
        .get();
    for (final d in recentDepts) {
      activities.add({
        'type': 'department',
        'title': 'Tạo Khoa ${d.name}',
        'subtitle': 'Mã: ${d.code}',
        'timestamp': d.createdAt.toIso8601String(),
      });
    }

    final recentSemesters = await (db.select(db.semesters)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(3))
        .get();
    for (final s in recentSemesters) {
      activities.add({
        'type': 'semester',
        'title': 'Tạo ${s.name}',
        'subtitle': 'Năm ${s.year} · HK${s.term}',
        'timestamp': s.startDate.toIso8601String(),
      });
    }

    final recentCourses = await (db.select(db.academicCourses)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(5))
        .get();
    for (final c in recentCourses) {
      activities.add({
        'type': 'course',
        'title': 'Thêm học phần ${c.name}',
        'subtitle':
            '${c.code} · ${c.credits} TC · ${deptMap[c.departmentId] ?? ""}',
        'timestamp': c.createdAt.toIso8601String(),
      });
    }

    final recentClasses = await (db.select(db.courseClasses)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(3))
        .get();
    for (final cc in recentClasses) {
      final course = await (db.select(db.academicCourses)
            ..where((t) => t.id.equals(cc.academicCourseId)))
          .getSingleOrNull();
      activities.add({
        'type': 'class',
        'title': 'Tạo lớp HP ${cc.classCode}',
        'subtitle': course?.name ?? '',
        'timestamp': cc.createdAt.toIso8601String(),
      });
    }

    final studentCount = await (db.selectOnly(db.users)
          ..addColumns([countAll()])
          ..where(db.users.role.equals(0)))
        .map((row) => row.read(countAll()) ?? 0)
        .getSingle();
    final teacherCount = await (db.selectOnly(db.users)
          ..addColumns([countAll()])
          ..where(db.users.role.equals(1)))
        .map((row) => row.read(countAll()) ?? 0)
        .getSingle();

    activities.add({
      'type': 'users',
      'title': 'Tổng $studentCount sinh viên, $teacherCount giảng viên',
      'subtitle': 'Trong hệ thống',
      'timestamp': DateTime.now().toIso8601String(),
    });

    activities.sort((a, b) {
      final ta = DateTime.tryParse(a['timestamp'] as String? ?? '') ??
          DateTime(2000);
      final tb = DateTime.tryParse(b['timestamp'] as String? ?? '') ??
          DateTime(2000);
      return tb.compareTo(ta);
    });

    return Response.json(body: {'activities': activities.take(10).toList()});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': '$e'},
    );
  }
}
