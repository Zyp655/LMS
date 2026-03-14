import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final courseId = int.tryParse(id);
  if (courseId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid course ID'},
    );
  }

  try {
    final db = context.read<AppDatabase>();

    final enrollments = await (db.select(db.enrollments)
          ..where((e) => e.courseId.equals(courseId)))
        .get();

    if (enrollments.isEmpty) {
      return Response.json(body: {
        'courseId': courseId,
        'totalStudents': 0,
        'atRiskStudents': <Map<String, dynamic>>[],
        'summary': {'atRiskCount': 0, 'atRiskPercent': 0.0},
      });
    }

    final modules = await (db.select(db.modules)
          ..where((m) => m.courseId.equals(courseId))
          ..orderBy([(m) => OrderingTerm.asc(m.orderIndex)]))
        .get();

    var totalLessons = 0;
    for (final m in modules) {
      final count = await (db.select(db.lessons)
            ..where((l) => l.moduleId.equals(m.id)))
          .get();
      totalLessons += count.length;
    }

    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    final results = <Map<String, dynamic>>[];

    for (final enrollment in enrollments) {
      final userId = enrollment.userId;

      final user = await (db.select(db.users)
            ..where((u) => u.id.equals(userId)))
          .getSingleOrNull();
      if (user == null) continue;

      final completedLessons = await (db.select(db.lessonProgress)
            ..where((p) => p.userId.equals(userId))
            ..where((p) => p.isCompleted.equals(true)))
          .get();

      final courseCompletedCount = completedLessons.where((p) {
        return true;
      }).length;

      final quizStats = await (db.select(db.quizStatistics)
            ..where((s) => s.userId.equals(userId)))
          .get();

      final recentActivities = await (db.select(db.learningActivities)
            ..where((a) => a.userId.equals(userId))
            ..where((a) => a.createdAt.isBiggerOrEqualValue(twoWeeksAgo))
            ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
          .get();

      double avgQuizScore = 0;
      if (quizStats.isNotEmpty) {
        avgQuizScore = quizStats.fold<double>(0, (sum, s) => sum + s.averageScore) /
            quizStats.length;
      }

      final completionRate = totalLessons > 0
          ? courseCompletedCount / totalLessons
          : 0.0;

      final daysSinceActivity = recentActivities.isEmpty
          ? 30
          : now.difference(recentActivities.first.createdAt).inDays;

      final streak = await (db.select(db.userStreaks)
            ..where((s) => s.userId.equals(userId)))
          .getSingleOrNull();
      final currentStreak = streak?.currentStreak ?? 0;

      var riskScore = 0.0;
      final riskFactors = <String>[];

      if (completionRate < 0.3 && totalLessons > 3) {
        riskScore += 30;
        riskFactors.add('Tiến độ thấp (${(completionRate * 100).toStringAsFixed(0)}%)');
      } else if (completionRate < 0.5) {
        riskScore += 15;
      }

      if (avgQuizScore < 40 && quizStats.isNotEmpty) {
        riskScore += 25;
        riskFactors.add('Điểm quiz thấp (${avgQuizScore.toStringAsFixed(0)}%)');
      } else if (avgQuizScore < 60 && quizStats.isNotEmpty) {
        riskScore += 10;
      }

      if (daysSinceActivity > 7) {
        riskScore += 25;
        riskFactors.add('Không hoạt động $daysSinceActivity ngày');
      } else if (daysSinceActivity > 3) {
        riskScore += 10;
      }

      if (currentStreak == 0) {
        riskScore += 10;
        riskFactors.add('Streak = 0');
      }

      if (recentActivities.length < 3) {
        riskScore += 10;
        riskFactors.add('Ít hoạt động gần đây');
      }

      riskScore = riskScore.clamp(0, 100);

      String riskLevel;
      if (riskScore >= 60) {
        riskLevel = 'high';
      } else if (riskScore >= 35) {
        riskLevel = 'medium';
      } else {
        riskLevel = 'low';
      }

      if (riskScore >= 35) {
        results.add({
          'userId': userId,
          'fullName': user.fullName ?? 'Sinh viên #$userId',
          'email': user.email,
          'riskScore': riskScore,
          'riskLevel': riskLevel,
          'riskFactors': riskFactors,
          'completionRate': completionRate,
          'avgQuizScore': avgQuizScore,
          'daysSinceActivity': daysSinceActivity,
          'currentStreak': currentStreak,
        });
      }
    }

    results.sort((a, b) =>
        (b['riskScore'] as double).compareTo(a['riskScore'] as double));

    final atRiskCount = results.where((r) => r['riskLevel'] == 'high').length;

    return Response.json(body: {
      'courseId': courseId,
      'totalStudents': enrollments.length,
      'atRiskStudents': results,
      'summary': {
        'atRiskCount': atRiskCount,
        'warningCount': results.length - atRiskCount,
        'atRiskPercent': enrollments.isNotEmpty
            ? (results.length / enrollments.length * 100)
            : 0.0,
      },
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Lỗi: $e'},
    );
  }
}
