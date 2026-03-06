import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
Future<Response> onRequest(RequestContext context, String id) async {
  final courseId = int.tryParse(id);
  if (courseId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid course ID'},
    );
  }
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  try {
    final db = context.read<AppDatabase>();
    final course = await (db.select(db.courses)
          ..where((c) => c.id.equals(courseId)))
        .getSingleOrNull();
    if (course == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Course not found'},
      );
    }
    final enrollments = await (db.select(db.enrollments)
          ..where((e) => e.courseId.equals(courseId)))
        .get();
    final modules = await (db.select(db.modules)
          ..where((m) => m.courseId.equals(courseId)))
        .get();
    final moduleIds = modules.map((m) => m.id).toList();
    int totalLessons = 0;
    if (moduleIds.isNotEmpty) {
      final lessons = await (db.select(db.lessons)
            ..where((l) => l.moduleId.isIn(moduleIds)))
          .get();
      totalLessons = lessons.length;
    }
    int notStarted = 0;
    int inProgress = 0;
    int completed = 0;
    for (final enrollment in enrollments) {
      if (enrollment.completedAt != null) {
        completed++;
      } else if (enrollment.progressPercent > 0) {
        inProgress++;
      } else {
        notStarted++;
      }
    }
    final reviews = await (db.select(db.courseReviews)
          ..where((r) => r.courseId.equals(courseId)))
        .get();
    double avgRating = 0;
    if (reviews.isNotEmpty) {
      final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
      avgRating = total / reviews.length;
    }
    final recentActivity = await (db.select(db.studentActivityLogs)
          ..where((a) => a.courseId.equals(courseId)))
        .get();
    return Response.json(
      body: {
        'courseId': courseId,
        'courseName': course.title,
        'totalEnrollments': enrollments.length,
        'totalModules': modules.length,
        'totalLessons': totalLessons,
        'studentStatus': {
          'notStarted': notStarted,
          'inProgress': inProgress,
          'completed': completed,
        },
        'completionRate': enrollments.isNotEmpty
            ? (completed / enrollments.length * 100).round()
            : 0,
        'rating': {
          'average': double.parse(avgRating.toStringAsFixed(1)),
          'totalReviews': reviews.length,
        },
        'recentActivityCount': recentActivity.length,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
