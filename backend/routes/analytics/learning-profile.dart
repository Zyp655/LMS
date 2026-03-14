import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final params = context.request.uri.queryParameters;
  final userId = int.tryParse(params['userId'] ?? '');

  if (userId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'userId is required'},
    );
  }

  try {
    final db = context.read<AppDatabase>();

    final enrollments = await (db.select(db.enrollments)
          ..where((e) => e.userId.equals(userId)))
        .get();

    final quizStats = await (db.select(db.quizStatistics)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([(s) => OrderingTerm.desc(s.totalAttempts)]))
        .get();

    final streak = await (db.select(db.userStreaks)
          ..where((s) => s.userId.equals(userId)))
        .getSingleOrNull();

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentActivities = await (db.select(db.learningActivities)
          ..where((a) => a.userId.equals(userId))
          ..where((a) => a.createdAt.isBiggerOrEqualValue(thirtyDaysAgo)))
        .get();

    final totalStudyMinutes = recentActivities.fold<int>(
      0,
      (sum, a) => sum + a.durationMinutes,
    );

    final completedLessons = await (db.select(db.lessonProgress)
          ..where((p) => p.userId.equals(userId))
          ..where((p) => p.isCompleted.equals(true)))
        .get();

    double overallAvgScore = 0;
    if (quizStats.isNotEmpty) {
      overallAvgScore = quizStats.fold<double>(
            0,
            (sum, s) => sum + s.averageScore * s.totalAttempts,
          ) /
          quizStats.fold<int>(0, (sum, s) => sum + s.totalAttempts);
    }

    final weakTopics = quizStats
        .where((s) => s.skillLevel < 0.5)
        .map((s) => {
              'topic': s.topic,
              'skillLevel': s.skillLevel,
              'averageScore': s.averageScore,
              'totalAttempts': s.totalAttempts,
            })
        .toList();

    final strongTopics = quizStats
        .where((s) => s.skillLevel >= 0.7)
        .map((s) => {
              'topic': s.topic,
              'skillLevel': s.skillLevel,
              'averageScore': s.averageScore,
            })
        .toList();

    final improvingTopics = quizStats
        .where((s) => s.skillLevel >= 0.5 && s.skillLevel < 0.7)
        .map((s) => {
              'topic': s.topic,
              'skillLevel': s.skillLevel,
              'averageScore': s.averageScore,
            })
        .toList();

    final activityByType = <String, int>{};
    for (final a in recentActivities) {
      activityByType[a.activityType] =
          (activityByType[a.activityType] ?? 0) + 1;
    }

    final engagementLevel = _calcEngagementLevel(
      totalStudyMinutes: totalStudyMinutes,
      currentStreak: streak?.currentStreak ?? 0,
      completedLessons: completedLessons.length,
      recentActivityCount: recentActivities.length,
    );

    return Response.json(body: {
      'userId': userId,
      'overview': {
        'enrolledCourses': enrollments.length,
        'completedLessons': completedLessons.length,
        'totalStudyMinutes30d': totalStudyMinutes,
        'overallAvgScore': overallAvgScore,
        'currentStreak': streak?.currentStreak ?? 0,
        'longestStreak': streak?.longestStreak ?? 0,
        'totalDaysActive': streak?.totalDaysActive ?? 0,
        'engagementLevel': engagementLevel,
      },
      'skillProfile': {
        'totalTopics': quizStats.length,
        'weakTopics': weakTopics,
        'strongTopics': strongTopics,
        'improvingTopics': improvingTopics,
      },
      'activityBreakdown': activityByType,
      'recentActivityCount': recentActivities.length,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Lỗi: $e'},
    );
  }
}

String _calcEngagementLevel({
  required int totalStudyMinutes,
  required int currentStreak,
  required int completedLessons,
  required int recentActivityCount,
}) {
  var score = 0;
  if (totalStudyMinutes > 300) {
    score += 3;
  } else if (totalStudyMinutes > 120) {
    score += 2;
  } else if (totalStudyMinutes > 30) {
    score += 1;
  }

  if (currentStreak > 7) {
    score += 3;
  } else if (currentStreak > 3) {
    score += 2;
  } else if (currentStreak > 0) {
    score += 1;
  }

  if (recentActivityCount > 20) {
    score += 2;
  } else if (recentActivityCount > 5) {
    score += 1;
  }

  if (score >= 6) return 'excellent';
  if (score >= 4) return 'good';
  if (score >= 2) return 'fair';
  return 'low';
}
