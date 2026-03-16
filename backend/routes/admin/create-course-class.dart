import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:backend/database/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }

  try {
    final db = context.read<AppDatabase>();
    final body = await context.request.json() as Map<String, dynamic>;

    final academicCourseId = body['academicCourseId'] as int?;
    final classCode = body['classCode'] as String?;

    if (academicCourseId == null || classCode == null || classCode.isEmpty) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({
          'success': false,
          'error': 'academicCourseId and classCode are required',
        }),
      );
    }

    final course = await (db.select(db.academicCourses)
          ..where((c) => c.id.equals(academicCourseId)))
        .getSingleOrNull();
    if (course == null) {
      return Response(
        statusCode: HttpStatus.notFound,
        body: jsonEncode({'success': false, 'error': 'Course not found'}),
      );
    }

    final activeSemester = await (db.select(db.semesters)
          ..where((s) => s.isActive.equals(true)))
        .getSingleOrNull();
    if (activeSemester == null) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'success': false, 'error': 'No active semester'}),
      );
    }

    final schedule = body['schedule'] as String?;
    final maxStudents = body['maxStudents'] as int? ?? 50;
    final dayOfWeek = body['dayOfWeek'] as int?;
    final startDateStr = body['startDate'] as String?;
    final endDateStr = body['endDate'] as String?;

    final row = await db.into(db.courseClasses).insertReturning(
          CourseClassesCompanion.insert(
            academicCourseId: academicCourseId,
            semesterId: activeSemester.id,
            teacherId: const Value(null),
            classCode: classCode,
            maxStudents: Value(maxStudents),
            room: const Value(null),
            schedule: Value(schedule),
            dayOfWeek: Value(dayOfWeek),
            startDate: Value(startDateStr != null ? DateTime.parse(startDateStr) : null),
            endDate: Value(endDateStr != null ? DateTime.parse(endDateStr) : null),
            createdAt: DateTime.now(),
          ),
        );

    final normalizedCode =
        classCode.replaceAll(RegExp(r'[-\s]'), '').toLowerCase();

    final allProfiles = await db.select(db.studentProfiles).get();
    int enrolledCount = 0;

    for (final profile in allProfiles) {
      if (profile.studentClass == null || profile.studentClass!.isEmpty)
        continue;

      final normalizedStudentClass =
          profile.studentClass!.replaceAll(RegExp(r'[-\s]'), '').toLowerCase();

      if (normalizedStudentClass == normalizedCode) {
        final existing = await (db.select(db.courseClassEnrollments)
              ..where((e) =>
                  e.courseClassId.equals(row.id) &
                  e.studentId.equals(profile.userId)))
            .getSingleOrNull();

        if (existing == null) {
          await db.into(db.courseClassEnrollments).insert(
                CourseClassEnrollmentsCompanion.insert(
                  courseClassId: row.id,
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
      body: {
        'success': true,
        'message':
            'Tạo lớp $classCode thành công. Đã tự đăng ký $enrolledCount sinh viên.',
        'courseClass': {
          'id': row.id,
          'classCode': row.classCode,
          'academicCourseId': row.academicCourseId,
          'schedule': row.schedule,
          'dayOfWeek': row.dayOfWeek,
          'startDate': row.startDate?.toIso8601String(),
          'endDate': row.endDate?.toIso8601String(),
          'maxStudents': row.maxStudents,
          'teacherId': row.teacherId,
          'enrolledCount': enrolledCount,
        },
      },
    );
  } catch (e) {
    final errorStr = '$e';
    String userMessage;
    int statusCode = HttpStatus.internalServerError;

    if (errorStr.contains('23505') || errorStr.contains('unique constraint')) {
      userMessage =
          'Mã lớp này đã tồn tại cho môn học này. Vui lòng kiểm tra lại.';
      statusCode = HttpStatus.conflict; // 409
    } else if (errorStr.contains('23503') || errorStr.contains('foreign key')) {
      userMessage = 'Dữ liệu tham chiếu không hợp lệ. Vui lòng kiểm tra lại.';
      statusCode = HttpStatus.badRequest;
    } else if (errorStr.contains('23502') || errorStr.contains('not-null')) {
      userMessage = 'Thiếu thông tin bắt buộc. Vui lòng điền đầy đủ.';
      statusCode = HttpStatus.badRequest;
    } else {
      userMessage = 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.';
    }

    return Response(
      statusCode: statusCode,
      body: jsonEncode({
        'success': false,
        'error': userMessage,
        'errorCode':
            errorStr.contains('23505') ? 'DUPLICATE_CLASS_CODE' : 'UNKNOWN',
      }),
    );
  }
}
