import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:backend/helpers/notification_helper.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final db = context.read<AppDatabase>();
    final body = await context.request.json() as Map<String, dynamic>;

    final studentId = body['studentId'] as int?;
    final courseId = body['courseId'] as int?;
    final teacherId = body['teacherId'] as int?;
    final daysInactive = body['daysInactive'] as int? ?? 0;
    final progressPercent = body['progressPercent'] as int? ?? 0;

    if (studentId == null || courseId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'studentId and courseId are required'},
      );
    }

    final teacher = await (db.select(db.users)
          ..where((u) => u.id.equals(teacherId ?? 0)))
        .getSingleOrNull();

    final course = await (db.select(db.courses)
          ..where((c) => c.id.equals(courseId)))
        .getSingleOrNull();

    final teacherName = teacher?.fullName ?? teacher?.email ?? 'Giảng viên';
    final courseName = course?.title ?? 'khóa học';

    final message = daysInactive > 7
        ? 'Bạn đã không hoạt động $daysInactive ngày trong "$courseName". Hãy quay lại học nhé!'
        : 'Tiến độ của bạn đang ở $progressPercent% trong "$courseName". Cố gắng hoàn thành nhé!';

    await NotificationHelper.createNotification(
      db: db,
      userId: studentId,
      type: 'nudge',
      title: '$teacherName nhắc nhở bạn',
      message: message,
      relatedId: courseId,
      relatedType: 'course',
    );

    return Response.json(
      body: {'message': 'Nudge sent successfully'},
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to send nudge: $e'},
    );
  }
}
