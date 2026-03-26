import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:backend/services/ai_service.dart';
import 'package:drift/drift.dart';
import 'package:backend/helpers/env_helper.dart';
Future<Response> onRequest(RequestContext context, String id) async {
  final courseId = int.tryParse(id);
  if (courseId == null) {
    return Response(
        statusCode: HttpStatus.badRequest, body: 'Invalid Course ID');
  }
  if (context.request.method == HttpMethod.post) {
    return _generateNudge(context, courseId);
  } else if (context.request.method == HttpMethod.put) {
    return _markAsNudged(context, courseId);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}
Future<Response> _generateNudge(RequestContext context, int courseId) async {
  final db = context.read<AppDatabase>();
  final body = await context.request.json() as Map<String, dynamic>;
  final userId = body['userId'] as int?;
  if (userId == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'Missing userId');
  }
  try {
    final user = await (db.select(db.users)..where((u) => u.id.equals(userId)))
        .getSingle();

    String courseName = 'khóa học';
    int daysInactive = 0;
    int progressPercent = 0;

    final enrollment = await (db.select(db.enrollments)
          ..where((e) => e.courseId.equals(courseId))
          ..where((e) => e.userId.equals(userId)))
        .getSingleOrNull();

    if (enrollment != null) {
      final course = await (db.select(db.courses)
            ..where((c) => c.id.equals(courseId)))
          .getSingle();
      courseName = course.title;
      final now = DateTime.now();
      daysInactive = enrollment.lastAccessedAt != null
          ? now.difference(enrollment.lastAccessedAt!).inDays
          : 0;
      progressPercent = enrollment.progressPercent.round();
    } else {
      final academicCourse = await (db.select(db.academicCourses)
            ..where((c) => c.id.equals(courseId)))
          .getSingleOrNull();
      if (academicCourse == null) {
        return Response(
            statusCode: HttpStatus.notFound, body: 'Course not found');
      }
      courseName = academicCourse.name;

      final ccEnrollment = await (db.select(db.courseClassEnrollments).join([
        innerJoin(db.courseClasses,
            db.courseClasses.id.equalsExp(db.courseClassEnrollments.courseClassId)),
      ])
            ..where(db.courseClasses.academicCourseId.equals(courseId))
            ..where(db.courseClassEnrollments.studentId.equals(userId)))
          .getSingleOrNull();

      if (ccEnrollment != null) {
        final e = ccEnrollment.readTable(db.courseClassEnrollments);
        progressPercent = e.progressPercent.round();
      }
    }

    final env = loadEnv();
    final apiKey = env['OPENAI_API_KEY'];
    if (apiKey == null) {
      return Response(
          statusCode: HttpStatus.internalServerError,
          body: 'OpenAI API Key not configured');
    }
    final aiService = AIService(openaiApiKey: apiKey);
    final message = await aiService.generateNudgeMessage(
      studentName: user.fullName ?? 'Bạn',
      courseName: courseName,
      daysInactive: daysInactive,
      progressPercent: progressPercent,
      nextLessonTitle: "Bài học tiếp theo",
      nextLessonDeepLink: "alarmm://lesson/0",
    );
    return Response.json(body: {'message': message});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
Future<Response> _markAsNudged(RequestContext context, int courseId) async {
  final db = context.read<AppDatabase>();
  final body = await context.request.json() as Map<String, dynamic>;
  final userId = body['userId'] as int?;
  if (userId == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'Missing userId');
  }
  try {
    await (db.update(db.enrollments)
          ..where((e) => e.courseId.equals(courseId))
          ..where((e) => e.userId.equals(userId)))
        .write(EnrollmentsCompanion(
      lastNudgedAt: Value(DateTime.now()),
    ));
    return Response.json(body: {'success': true});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
