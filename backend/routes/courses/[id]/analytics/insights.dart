import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:backend/services/ai_service.dart';
import 'package:drift/drift.dart';
import 'package:dotenv/dotenv.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final courseId = int.tryParse(id);
  if (courseId == null) {
    return Response(
        statusCode: HttpStatus.badRequest, body: 'Invalid Course ID');
  }
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  try {
    final db = context.read<AppDatabase>();
    final enrollments = await (db.select(db.enrollments)
          ..where((e) => e.courseId.equals(courseId)))
        .get();
    final totalStudents = enrollments.length;
    if (totalStudents == 0) {
      return Response.json(body: {
        'summary': 'Chưa có dữ liệu học viên.',
        'moduleStats': [],
      });
    }
    final modules = await (db.select(db.modules)
          ..where((m) => m.courseId.equals(courseId))
          ..orderBy([(m) => OrderingTerm.asc(m.orderIndex)]))
        .get();
    final List<Map<String, dynamic>> moduleStats = [];
    int previousCompleters = totalStudents;
    for (final module in modules) {
      final lessons = await (db.select(db.lessons)
            ..where((l) => l.moduleId.equals(module.id)))
          .get();
      final lessonIds = lessons.map((l) => l.id).toList();
      if (lessonIds.isEmpty) continue;
      int completers = 0;
      final quizzes = await (db.select(db.quizzes)
            ..where((q) => q.moduleId.equals(module.id)))
          .get();
      final quizIds = quizzes.map((q) => q.id).toList();
      double totalScore = 0;
      int scoreCount = 0;
      for (final enrollment in enrollments) {
        final progress = await (db.select(db.lessonProgress)
              ..where((p) => p.userId.equals(enrollment.userId))
              ..where((p) => p.lessonId.isIn(lessonIds))
              ..where((p) => p.isCompleted.equals(true)))
            .get();
        if (progress.length == lessons.length) {
          completers++;
        }
        if (quizIds.isNotEmpty) {
          final attempts = await (db.select(db.quizAttempts)
                ..where((a) => a.userId.equals(enrollment.userId))
                ..where((a) => a.quizId.isIn(quizIds)))
              .get();
          if (attempts.isNotEmpty) {
            final userAvg =
                attempts.fold<double>(0, (sum, a) => sum + a.scorePercentage) /
                    attempts.length;
            totalScore += userAvg;
            scoreCount++;
          }
        }
      }
      final completionRate =
          totalStudents > 0 ? completers / totalStudents : 0.0;
      final dropOffRate = previousCompleters > 0
          ? (previousCompleters - completers) / previousCompleters
          : 0.0;
      final avgQuizScore = scoreCount > 0 ? totalScore / scoreCount : null;
      moduleStats.add({
        'moduleId': module.id,
        'title': module.title,
        'studentCount': completers,
        'completionRate': double.parse(completionRate.toStringAsFixed(2)),
        'dropOffRate': double.parse(dropOffRate.toStringAsFixed(2)),
        'avgQuizScore': avgQuizScore != null
            ? double.parse(avgQuizScore.toStringAsFixed(1))
            : null,
      });
      previousCompleters = completers;
    }
    final env = DotEnv(includePlatformEnvironment: true)..load();
    final apiKey = env['OPENAI_API_KEY'];
    Map<String, dynamic> aiInsights;
    if (apiKey != null) {
      final aiService = AIService(openaiApiKey: apiKey);
      try {
        aiInsights = await aiService.generateEngagementReport(
          courseName: "Analysis",
          moduleStats: moduleStats,
          totalStudents: totalStudents,
        );
      } catch (e) {
        aiInsights = {
          'summary': 'Không thể tạo báo cáo AI lúc này.',
          'top_bottleneck': null,
          'causes': [],
          'recommendations': []
        };
      }
    } else {
      aiInsights = {
        'summary': 'Chưa cấu hình OpenAI key.',
        'top_bottleneck': null,
        'causes': [],
        'recommendations': []
      };
    }
    return Response.json(body: {
      'courseId': courseId,
      'totalStudents': totalStudents,
      'moduleStats': moduleStats,
      'aiInsights': aiInsights,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
