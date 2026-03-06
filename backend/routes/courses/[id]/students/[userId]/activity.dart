import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';
Future<Response> onRequest(
    RequestContext context, String id, String userId) async {
  final courseId = int.tryParse(id);
  final studentId = int.tryParse(userId);
  if (courseId == null || studentId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid course ID or user ID'},
    );
  }
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  try {
    final db = context.read<AppDatabase>();
    final activities = await (db.select(db.studentActivityLogs)
          ..where(
              (a) => a.userId.equals(studentId) & a.courseId.equals(courseId))
          ..orderBy([(a) => OrderingTerm.desc(a.timestamp)])
          ..limit(100))
        .get();
    final user = await (db.select(db.users)
          ..where((u) => u.id.equals(studentId)))
        .getSingleOrNull();
    final enrollment = await (db.select(db.enrollments)
          ..where(
              (e) => e.userId.equals(studentId) & e.courseId.equals(courseId)))
        .getSingleOrNull();
    final modules = await (db.select(db.modules)
          ..where((m) => m.courseId.equals(courseId)))
        .get();
    final moduleIds = modules.map((m) => m.id).toList();
    List<Map<String, dynamic>> lessonProgressList = [];
    if (moduleIds.isNotEmpty) {
      final lessons = await (db.select(db.lessons)
            ..where((l) => l.moduleId.isIn(moduleIds)))
          .get();
      for (final lesson in lessons) {
        final progress = await (db.select(db.lessonProgress)
              ..where((p) =>
                  p.userId.equals(studentId) & p.lessonId.equals(lesson.id)))
            .getSingleOrNull();
        lessonProgressList.add({
          'lessonId': lesson.id,
          'lessonTitle': lesson.title,
          'lessonType': lesson.type,
          'isCompleted': progress?.isCompleted ?? false,
          'completedAt': progress?.completedAt?.toIso8601String(),
          'lastWatchedPosition': progress?.lastWatchedPosition ?? 0,
        });
      }
    }
    return Response.json(
      body: {
        'userId': studentId,
        'courseId': courseId,
        'user': user != null
            ? {
                'email': user.email,
                'fullName': user.fullName,
              }
            : null,
        'enrollment': enrollment != null
            ? {
                'enrolledAt': enrollment.enrolledAt.toIso8601String(),
                'lastAccessedAt': enrollment.lastAccessedAt?.toIso8601String(),
                'completedAt': enrollment.completedAt?.toIso8601String(),
                'progressPercent': enrollment.progressPercent,
              }
            : null,
        'lessonProgress': lessonProgressList,
        'activityLog': activities
            .map((a) => {
                  'id': a.id,
                  'action': a.action,
                  'lessonId': a.lessonId,
                  'timestamp': a.timestamp.toIso8601String(),
                  'metadata': a.metadata,
                })
            .toList(),
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
