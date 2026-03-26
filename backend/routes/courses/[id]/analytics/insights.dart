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
      statusCode: HttpStatus.badRequest,
      body: 'Invalid Course ID',
    );
  }
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  try {
    final db = context.read<AppDatabase>();
    final lmsEnrollments = await (db.select(db.enrollments)
          ..where((e) => e.courseId.equals(courseId)))
        .get();

    final isAcademic = lmsEnrollments.isEmpty;
    List<int> studentUserIds = lmsEnrollments.map((e) => e.userId).toList();

    if (isAcademic) {
      final classes = await (db.select(db.courseClasses)
            ..where((c) => c.academicCourseId.equals(courseId)))
          .get();
      final classIds = classes.map((c) => c.id).toList();
      if (classIds.isNotEmpty) {
        final classEnrollments = await (db.select(db.courseClassEnrollments)
              ..where((e) => e.courseClassId.isIn(classIds)))
            .get();
        studentUserIds = classEnrollments.map((e) => e.studentId).toSet().toList();
      }
    }

    final totalStudents = studentUserIds.length;
    if (totalStudents == 0) {
      return Response.json(body: {
        'summary': 'Chưa có dữ liệu sinh viên.',
        'moduleStats': <Map<String, dynamic>>[],
      });
    }
    final modules = await (db.select(db.modules)
          ..where((m) => isAcademic
              ? m.academicCourseId.equals(courseId)
              : m.courseId.equals(courseId))
          ..orderBy([(m) => OrderingTerm.asc(m.orderIndex)]))
        .get();
    final moduleStats = <Map<String, dynamic>>[];
    var previousCompleters = totalStudents;
    for (final module in modules) {
      final lessons = await (db.select(db.lessons)
            ..where((l) => l.moduleId.equals(module.id)))
          .get();
      final lessonIds = lessons.map((l) => l.id).toList();
      if (lessonIds.isEmpty) continue;
      var completers = 0;
      final quizzes = await (db.select(db.quizzes)
            ..where((q) => q.moduleId.equals(module.id)))
          .get();
      final quizIds = quizzes.map((q) => q.id).toList();
      var totalScore = 0.0;
      var scoreCount = 0;
      for (final userId in studentUserIds) {
        final progress = await (db.select(db.lessonProgress)
              ..where((p) => p.userId.equals(userId))
              ..where((p) => p.lessonId.isIn(lessonIds))
              ..where((p) => p.isCompleted.equals(true)))
            .get();
        if (progress.length == lessons.length) {
          completers++;
        }
        if (quizIds.isNotEmpty) {
          final attempts = await (db.select(db.quizAttempts)
                ..where((a) => a.userId.equals(userId))
                ..where((a) => a.quizId.isIn(quizIds)))
              .get();
          if (attempts.isNotEmpty) {
            final userAvg =
                attempts.fold<double>(
                  0,
                  (sum, a) => sum + a.scorePercentage,
                ) /
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
    final env = loadEnv();
    final apiKey = env['OPENAI_API_KEY'];
    Map<String, dynamic> aiInsights;
    if (apiKey != null) {
      final aiService = AIService(openaiApiKey: apiKey);
      try {
        aiInsights = await aiService.generateEngagementReport(
          courseName: 'Analysis',
          moduleStats: moduleStats,
          totalStudents: totalStudents,
        );
      } catch (e) {
        aiInsights = {
          'summary': 'Không thể tạo báo cáo AI lúc này.',
          'top_bottleneck': null,
          'causes': <String>[],
          'recommendations': <String>[],
        };
      }
    } else {
      aiInsights = {
        'summary': 'Chưa cấu hình OpenAI key.',
        'top_bottleneck': null,
        'causes': <String>[],
        'recommendations': <String>[],
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
