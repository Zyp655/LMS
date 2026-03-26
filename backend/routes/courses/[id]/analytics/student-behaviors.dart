import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:backend/services/ai_service.dart';
import 'package:drift/drift.dart';
import 'package:backend/helpers/env_helper.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final courseId = int.tryParse(id);
  if (courseId == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'Invalid Course ID');
  }
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final db = context.read<AppDatabase>();
    try {
      final cachedRows = await db.customSelect(
        'SELECT report_json, stats_json, generated_at FROM behavior_reports '
        'WHERE course_id = \$1 AND expires_at > NOW() '
        'ORDER BY generated_at DESC LIMIT 1',
        variables: [Variable.withInt(courseId)],
      ).get();

      if (cachedRows.isNotEmpty) {
        final row = cachedRows.first;
        return Response.json(body: {
          'cached': true,
          'generatedAt': row.read<DateTime>('generated_at').toIso8601String(),
          'stats': jsonDecode(row.read<String>('stats_json')),
          'aiInsights': jsonDecode(row.read<String>('report_json')),
        });
      }
    } catch (_) {}

    final classes = await (db.select(db.courseClasses)
          ..where((c) => c.academicCourseId.equals(courseId)))
        .get();
    final classIds = classes.map((c) => c.id).toList();

    List<int> studentUserIds = [];
    if (classIds.isNotEmpty) {
      final classEnrollments = await (db.select(db.courseClassEnrollments)
            ..where((e) => e.courseClassId.isIn(classIds)))
          .get();
      studentUserIds = classEnrollments.map((e) => e.studentId).toSet().toList();
    }

    if (studentUserIds.isEmpty) {
      final lmsEnrollments = await (db.select(db.enrollments)
            ..where((e) => e.courseId.equals(courseId)))
          .get();
      studentUserIds = lmsEnrollments.map((e) => e.userId).toList();
    }

    final totalStudents = studentUserIds.length;
    if (totalStudents == 0) {
      return Response.json(body: {
        'cached': false,
        'stats': <String, dynamic>{'totalStudents': 0, 'engagement': <String, dynamic>{}, 'students': <Map<String, dynamic>>[]},
        'aiInsights': <String, dynamic>{'summary': 'Chưa có sinh viên nào trong môn này.'},
      });
    }

    final modules = await (db.select(db.modules)
          ..where((m) => m.academicCourseId.equals(courseId))
          ..orderBy([(m) => OrderingTerm.asc(m.orderIndex)]))
        .get();

    if (modules.isEmpty) {
      final lmsModules = await (db.select(db.modules)
            ..where((m) => m.courseId.equals(courseId))
            ..orderBy([(m) => OrderingTerm.asc(m.orderIndex)]))
          .get();
      modules.addAll(lmsModules);
    }

    final allLessons = <Lesson>[];
    for (final mod in modules) {
      final lessons = await (db.select(db.lessons)
            ..where((l) => l.moduleId.equals(mod.id)))
          .get();
      allLessons.addAll(lessons);
    }
    final allLessonIds = allLessons.map((l) => l.id).toSet();
    final totalLessons = allLessonIds.length;

    final allQuizIds = <int>[];
    for (final mod in modules) {
      final quizzes = await (db.select(db.quizzes)
            ..where((q) => q.moduleId.equals(mod.id)))
          .get();
      allQuizIds.addAll(quizzes.map((q) => q.id));
    }

    final users = await (db.select(db.users)
          ..where((u) => u.id.isIn(studentUserIds)))
        .get();
    final userNameMap = {for (final u in users) u.id: u.fullName ?? 'SV #${u.id}'};

    final studentProfiles = <Map<String, dynamic>>[];

    for (final userId in studentUserIds) {
      final progress = await (db.select(db.lessonProgress)
            ..where((p) => p.userId.equals(userId))
            ..where((p) => p.lessonId.isIn(allLessonIds))
            ..where((p) => p.isCompleted.equals(true)))
          .get();
      final completionRate = totalLessons > 0
          ? (progress.length / totalLessons * 100).round()
          : 0;

      double avgQuizScore = 0;
      double avgSecondsPerQ = 0;
      int quizAttemptCount = 0;
      if (allQuizIds.isNotEmpty) {
        final attempts = await (db.select(db.quizAttempts)
              ..where((a) => a.userId.equals(userId))
              ..where((a) => a.quizId.isIn(allQuizIds)))
            .get();
        if (attempts.isNotEmpty) {
          quizAttemptCount = attempts.length;
          avgQuizScore = attempts.fold<double>(0, (s, a) => s + a.scorePercentage) / attempts.length;
          final totalTimePerQ = attempts.fold<double>(0, (s, a) {
            return s + (a.totalQuestions > 0 ? a.timeSpentSeconds / a.totalQuestions : 0);
          });
          avgSecondsPerQ = totalTimePerQ / attempts.length;
        }
      }

      final streak = await (db.select(db.userStreaks)
            ..where((s) => s.userId.equals(userId)))
          .getSingleOrNull();
      final lastActivity = streak?.lastActivityDate;
      final daysInactive = lastActivity != null
          ? DateTime.now().difference(lastActivity).inDays
          : 999;

      final userComments = await (db.select(db.comments)
            ..where((c) => c.userId.equals(userId))
            ..where((c) => c.lessonId.isIn(allLessonIds)))
          .get();

      int forumScore = 0;
      for (final c in userComments) {
        if (c.depth == 0) {
          forumScore += 2;
        } else {
          forumScore += 3;
        }
        forumScore += c.upvotes;
        if (c.isAnswered) forumScore += 5;
      }

      String quizSpeed = 'normal';
      if (avgSecondsPerQ > 0 && avgSecondsPerQ < 10) {
        quizSpeed = 'rush';
      } else if (avgSecondsPerQ > 60) {
        quizSpeed = 'slow';
      }

      String level;
      if (daysInactive > 7 || (completionRate < 30 && avgQuizScore < 50)) {
        level = 'low';
      } else if (avgQuizScore < 60 || (quizSpeed == 'rush' && avgQuizScore < 50)) {
        level = 'fair';
      } else if (completionRate > 80 && avgQuizScore >= 80) {
        level = 'excellent';
      } else {
        level = 'good';
      }

      int totalSkips = 0;
      int totalRewinds = 0;
      int totalPauses = 0;
      try {
        final videoBehaviors = await (db.select(db.learningActivities)
              ..where((a) => a.userId.equals(userId))
              ..where((a) => a.activityType.equals('video_behavior')))
            .get();
        for (final vb in videoBehaviors) {
          if (vb.metadata != null) {
            try {
              final meta = jsonDecode(vb.metadata!) as Map<String, dynamic>;
              totalSkips += (meta['skipCount'] as int? ?? 0);
              totalRewinds += (meta['rewindCount'] as int? ?? 0);
              totalPauses += (meta['pauseCount'] as int? ?? 0);
            } catch (_) {}
          }
        }
      } catch (_) {}

      studentProfiles.add({
        'userId': userId,
        'name': userNameMap[userId] ?? 'SV #\$userId',
        'completionRate': completionRate,
        'avgQuizScore': avgQuizScore.round(),
        'avgSecondsPerQ': avgSecondsPerQ.round(),
        'quizSpeed': quizSpeed,
        'daysInactive': daysInactive,
        'commentCount': userComments.length,
        'forumScore': forumScore,
        'quizAttemptCount': quizAttemptCount,
        'totalSkips': totalSkips,
        'totalRewinds': totalRewinds,
        'totalPauses': totalPauses,
        'level': level,
      });
    }

    final engagement = <String, int>{
      'excellent': studentProfiles.where((s) => s['level'] == 'excellent').length,
      'good': studentProfiles.where((s) => s['level'] == 'good').length,
      'fair': studentProfiles.where((s) => s['level'] == 'fair').length,
      'low': studentProfiles.where((s) => s['level'] == 'low').length,
    };

    final riskStudents = studentProfiles
        .where((s) => s['level'] == 'low')
        .toList()
      ..sort((a, b) => (b['daysInactive'] as int).compareTo(a['daysInactive'] as int));

    final starStudents = studentProfiles
        .where((s) => s['level'] == 'excellent')
        .toList()
      ..sort((a, b) => (b['avgQuizScore'] as int).compareTo(a['avgQuizScore'] as int));

    final quizRushers = studentProfiles
        .where((s) => s['quizSpeed'] == 'rush' && (s['avgQuizScore'] as int) < 50)
        .toList();

    var bottleneckModule = 'N/A';
    var bottleneckDropRate = 0.0;
    var previousCompleters = totalStudents;
    for (final mod in modules) {
      final modLessons = await (db.select(db.lessons)
            ..where((l) => l.moduleId.equals(mod.id)))
          .get();
      final modLessonIds = modLessons.map((l) => l.id).toList();
      if (modLessonIds.isEmpty) continue;

      var completers = 0;
      for (final userId in studentUserIds) {
        final done = await (db.select(db.lessonProgress)
              ..where((p) => p.userId.equals(userId))
              ..where((p) => p.lessonId.isIn(modLessonIds))
              ..where((p) => p.isCompleted.equals(true)))
            .get();
        if (done.length == modLessons.length) completers++;
      }

      final dropRate = previousCompleters > 0
          ? (previousCompleters - completers) / previousCompleters
          : 0.0;
      if (dropRate > bottleneckDropRate) {
        bottleneckDropRate = dropRate;
        bottleneckModule = mod.title;
      }
      previousCompleters = completers;
    }

    final statsPayload = {
      'totalStudents': totalStudents,
      'engagement': engagement,
      'students': studentProfiles,
      'bottleneckModule': bottleneckModule,
      'bottleneckDropRate': double.parse(bottleneckDropRate.toStringAsFixed(2)),
    };

    final env = loadEnv();
    final apiKey = env['OPENAI_API_KEY'];
    Map<String, dynamic> aiInsights;

    if (apiKey != null) {
      try {
        final aiService = AIService(openaiApiKey: apiKey);
        aiInsights = await aiService.analyzeStudentBehaviors(
          courseName: modules.isNotEmpty ? modules.first.title : 'Course $courseId',
          totalStudents: totalStudents,
          engagementDistribution: engagement,
          topRiskProfiles: riskStudents.take(10).toList(),
          topStarProfiles: starStudents.take(10).toList(),
          quizRushers: quizRushers.take(5).toList(),
          bottleneckModule: bottleneckModule,
          bottleneckDropRate: bottleneckDropRate,
        );
      } catch (e) {
        aiInsights = {
          'summary': 'Không thể tạo phân tích AI lúc này: $e',
          'causes': <String>[],
          'curriculumSuggestions': <String>[],
          'recommendations': <String>[],
          'nudgeTemplates': <Map<String, String>>[],
        };
      }
    } else {
      aiInsights = {
        'summary': 'Chưa cấu hình OpenAI API key.',
        'causes': <String>[],
        'curriculumSuggestions': <String>[],
        'recommendations': <String>[],
        'nudgeTemplates': <Map<String, String>>[],
      };
    }

    try {
      await db.customStatement(
        'INSERT INTO behavior_reports (course_id, report_json, stats_json, generated_at, expires_at) '
        'VALUES (\$1, \$2, \$3, NOW(), NOW() + INTERVAL \'24 hours\')',
        [courseId, jsonEncode(aiInsights), jsonEncode(statsPayload)],
      );
    } catch (_) {}

    return Response.json(body: {
      'cached': false,
      'generatedAt': DateTime.now().toIso8601String(),
      'stats': statsPayload,
      'aiInsights': aiInsights,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Lỗi hệ thống: $e'},
    );
  }
}
