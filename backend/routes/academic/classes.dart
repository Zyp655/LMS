import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:backend/database/database.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<AppDatabase>();

  switch (context.request.method) {
    case HttpMethod.get:
      return _getAll(db);
    case HttpMethod.post:
      return _create(context, db);
    case HttpMethod.put:
      return _update(context, db);
    case HttpMethod.delete:
      return _delete(context, db);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getAll(AppDatabase db) async {
  final rows = await db.select(db.courseClasses).get();

  final courses = await db.select(db.academicCourses).get();
  final semesters = await db.select(db.semesters).get();
  final users = await db.select(db.users).get();

  final courseMap = {for (final c in courses) c.id: c};
  final semMap = {for (final s in semesters) s.id: s};
  final userMap = {for (final u in users) u.id: u};

  return Response.json(
    body: {
      'classes': rows
          .map((c) => {
                'id': c.id,
                'academicCourseId': c.academicCourseId,
                'courseName': courseMap[c.academicCourseId]?.name ?? '',
                'courseCode': courseMap[c.academicCourseId]?.code ?? '',
                'semesterId': c.semesterId,
                'semesterName': semMap[c.semesterId]?.name ?? '',
                'teacherId': c.teacherId,
                'teacherName': userMap[c.teacherId]?.fullName ??
                    userMap[c.teacherId]?.email ??
                    '',
                'classCode': c.classCode,
                'maxStudents': c.maxStudents,
                'room': c.room,
                'schedule': c.schedule,
                'dayOfWeek': c.dayOfWeek,
                'startDate': c.startDate?.toIso8601String(),
                'endDate': c.endDate?.toIso8601String(),
                'createdAt': c.createdAt.toIso8601String(),
              })
          .toList(),
    },
  );
}

Future<Response> _create(RequestContext context, AppDatabase db) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final academicCourseId = body['academicCourseId'] as int?;
  final semesterId = body['semesterId'] as int?;
  final teacherId = body['teacherId'] as int?;
  final classCode = body['classCode'] as String?;

  if (academicCourseId == null ||
      semesterId == null ||
      teacherId == null ||
      classCode == null) {
    return Response.json(
      statusCode: 400,
      body: {
        'error':
            'academicCourseId, semesterId, teacherId, classCode là bắt buộc'
      },
    );
  }

  try {
    final row = await db.into(db.courseClasses).insert(
          CourseClassesCompanion.insert(
            academicCourseId: academicCourseId,
            semesterId: semesterId,
            teacherId: Value(teacherId),
            classCode: classCode,
            maxStudents: Value(body['maxStudents'] as int? ?? 50),
            room: Value(body['room'] as String?),
            schedule: Value(body['schedule'] as String?),
            dayOfWeek: Value(body['dayOfWeek'] as int?),
            startDate: Value(body['startDate'] != null ? DateTime.parse(body['startDate'] as String) : null),
            endDate: Value(body['endDate'] != null ? DateTime.parse(body['endDate'] as String) : null),
            createdAt: DateTime.now(),
          ),
        );

    final normalizedCode =
        classCode.replaceAll(RegExp(r'[-\s]'), '').toLowerCase();
    final allProfiles = await db.select(db.studentProfiles).get();
    int enrolledCount = 0;

    for (final profile in allProfiles) {
      if (profile.studentClass == null || profile.studentClass!.isEmpty) {
        continue;
      }
      final normalizedStudentClass =
          profile.studentClass!.replaceAll(RegExp(r'[-\s]'), '').toLowerCase();
      if (normalizedStudentClass == normalizedCode) {
        final existing = await (db.select(db.courseClassEnrollments)
              ..where((e) =>
                  e.courseClassId.equals(row) &
                  e.studentId.equals(profile.userId)))
            .getSingleOrNull();
        if (existing == null) {
          await db.into(db.courseClassEnrollments).insert(
                CourseClassEnrollmentsCompanion.insert(
                  courseClassId: row,
                  studentId: profile.userId,
                  status: const Value('enrolled'),
                  source: const Value('auto'),
                  enrolledAt: DateTime.now(),
                ),
              );
          enrolledCount++;
        }
      }
    }

    return Response.json(
      statusCode: 201,
      body: {
        'id': row,
        'message':
            'Tạo lớp học phần thành công. Đã tự đăng ký $enrolledCount sinh viên.',
        'enrolledCount': enrolledCount,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 409,
      body: {'error': 'Mã lớp đã tồn tại cho môn học này hoặc lỗi: $e'},
    );
  }
}

Future<Response> _update(RequestContext context, AppDatabase db) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final id = body['id'] as int?;
  if (id == null) {
    return Response.json(statusCode: 400, body: {'error': 'id là bắt buộc'});
  }

  try {
    final stmt = db.update(db.courseClasses)..where((t) => t.id.equals(id));
    await stmt.write(CourseClassesCompanion(
      classCode: body['classCode'] != null
          ? Value(body['classCode'] as String)
          : const Value.absent(),
      room: body.containsKey('room')
          ? Value(body['room'] as String?)
          : const Value.absent(),
      schedule: body.containsKey('schedule')
          ? Value(body['schedule'] as String?)
          : const Value.absent(),
      teacherId: body['teacherId'] != null
          ? Value(body['teacherId'] as int)
          : const Value.absent(),
      maxStudents: body['maxStudents'] != null
          ? Value(body['maxStudents'] as int)
          : const Value.absent(),
      academicCourseId: body['academicCourseId'] != null
          ? Value(body['academicCourseId'] as int)
          : const Value.absent(),
      semesterId: body['semesterId'] != null
          ? Value(body['semesterId'] as int)
          : const Value.absent(),
      dayOfWeek: body.containsKey('dayOfWeek')
          ? Value(body['dayOfWeek'] as int?)
          : const Value.absent(),
      startDate: body.containsKey('startDate')
          ? Value(body['startDate'] != null ? DateTime.parse(body['startDate'] as String) : null)
          : const Value.absent(),
      endDate: body.containsKey('endDate')
          ? Value(body['endDate'] != null ? DateTime.parse(body['endDate'] as String) : null)
          : const Value.absent(),
    ));
    return Response.json(body: {'message': 'Cập nhật lớp học phần thành công'});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': 'Lỗi cập nhật: $e'});
  }
}

Future<Response> _delete(RequestContext context, AppDatabase db) async {
  final idStr = context.request.uri.queryParameters['id'];
  final id = int.tryParse(idStr ?? '');
  if (id == null) {
    return Response.json(statusCode: 400, body: {'error': 'id là bắt buộc'});
  }

  try {
    final deleted =
        await (db.delete(db.courseClasses)..where((t) => t.id.equals(id))).go();
    if (deleted == 0) {
      return Response.json(
          statusCode: 404, body: {'error': 'Không tìm thấy lớp'});
    }
    return Response.json(body: {'message': 'Xóa lớp học phần thành công'});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': 'Lỗi xóa: $e'});
  }
}
