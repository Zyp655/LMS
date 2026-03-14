import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final db = context.read<AppDatabase>();
    final params = context.request.uri.queryParameters;
    final userId = int.tryParse(params['userId'] ?? '');

    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'userId is required'},
      );
    }

    final streak = await (db.select(db.userStreaks)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();

    final weekStart =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final weekStartDate =
        DateTime(weekStart.year, weekStart.month, weekStart.day);

    final weekTimeQuery = db.selectOnly(db.learningActivities)
      ..addColumns([db.learningActivities.durationMinutes.sum()])
      ..where(db.learningActivities.userId.equals(userId))
      ..where(
          db.learningActivities.createdAt.isBiggerOrEqualValue(weekStartDate));

    final weekTimeResult = await weekTimeQuery.getSingle();
    final weekMinutes =
        weekTimeResult.read(db.learningActivities.durationMinutes.sum()) ?? 0;

    final todayStart =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayTimeQuery = db.selectOnly(db.learningActivities)
      ..addColumns([db.learningActivities.durationMinutes.sum()])
      ..where(db.learningActivities.userId.equals(userId))
      ..where(
          db.learningActivities.createdAt.isBiggerOrEqualValue(todayStart));
    final todayTimeResult = await todayTimeQuery.getSingle();
    final todayMinutes =
        todayTimeResult.read(db.learningActivities.durationMinutes.sum()) ?? 0;

    final weekLessonsQuery = db.selectOnly(db.lessonProgress)
      ..addColumns([db.lessonProgress.id.count()])
      ..where(db.lessonProgress.userId.equals(userId))
      ..where(db.lessonProgress.isCompleted.equals(true))
      ..where(
          db.lessonProgress.completedAt.isBiggerOrEqualValue(weekStartDate));
    final weekLessonsResult = await weekLessonsQuery.getSingle();
    final weekCompletedLessons =
        weekLessonsResult.read(db.lessonProgress.id.count()) ?? 0;

    var enrollmentsQuery = db.select(db.enrollments)
      ..where((t) => t.userId.equals(userId))
      ..where((t) => t.completedAt.isNull());
    final enrollments = await enrollmentsQuery.get();

    final overallProgress = enrollments.isNotEmpty
        ? enrollments.fold<double>(0, (s, e) => s + e.progressPercent) /
            enrollments.length
        : 0.0;

    final completedQuery = db.selectOnly(db.lessonProgress)
      ..addColumns([db.lessonProgress.id.count()])
      ..where(db.lessonProgress.userId.equals(userId))
      ..where(db.lessonProgress.isCompleted.equals(true));
    final completedResult = await completedQuery.getSingle();
    final completedLessons =
        completedResult.read(db.lessonProgress.id.count()) ?? 0;

    final todayActivityQuery = db.selectOnly(db.learningActivities)
      ..addColumns([db.learningActivities.id.count()])
      ..where(db.learningActivities.userId.equals(userId))
      ..where(db.learningActivities.createdAt.isBiggerOrEqualValue(todayStart));
    final todayResult = await todayActivityQuery.getSingle();
    final todayActivities =
        todayResult.read(db.learningActivities.id.count()) ?? 0;

    return Response.json(body: {
      'currentStreak': streak?.currentStreak ?? 0,
      'longestStreak': streak?.longestStreak ?? 0,
      'weekStudyMinutes': weekMinutes,
      'todayStudyMinutes': todayMinutes,
      'weekCompletedLessons': weekCompletedLessons,
      'activeCourses': enrollments.length,
      'overallProgress': overallProgress,
      'completedLessons': completedLessons,
      'todayActivities': todayActivities,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
