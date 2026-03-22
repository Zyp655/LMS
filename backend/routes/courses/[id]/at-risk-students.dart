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

    final lmsEnrollments = await (db.select(db.enrollments)
          ..where((e) => e.courseId.equals(courseId)))
        .get();

    final isAcademic = lmsEnrollments.isEmpty;
    List<int> enrolledUserIds = [];
    List<int> classIds = [];

    if (isAcademic) {
      final classes = await (db.select(db.courseClasses)
            ..where((c) => c.academicCourseId.equals(courseId)))
          .get();
      classIds = classes.map((c) => c.id).toList();
      if (classIds.isNotEmpty) {
        final ccEnrollments = await (db.select(db.courseClassEnrollments)
              ..where((e) => e.courseClassId.isIn(classIds)))
            .get();
        enrolledUserIds = ccEnrollments.map((e) => e.studentId).toSet().toList();
      }
    } else {
      enrolledUserIds = lmsEnrollments.map((e) => e.userId).toList();
    }

    if (enrolledUserIds.isEmpty) {
      return Response.json(body: {
        'courseId': courseId,
        'totalStudents': 0,
        'atRiskStudents': <Map<String, dynamic>>[],
        'summary': {
          'atRiskCount': 0,
          'warningCount': 0,
          'atRiskPercent': 0.0,
        },
      });
    }

    final modules = await (db.select(db.modules)
          ..where((m) => isAcademic
              ? m.academicCourseId.equals(courseId)
              : m.courseId.equals(courseId)))
        .get();
    final moduleIds = modules.map((m) => m.id).toList();

    List<int> allLessonIds = [];
    if (moduleIds.isNotEmpty) {
      final lessons = await (db.select(db.lessons)
            ..where((l) => l.moduleId.isIn(moduleIds)))
          .get();
      allLessonIds = lessons.map((l) => l.id).toList();
    }
    final totalLessons = allLessonIds.length;

    List<int> courseAssignmentIds = [];
    if (classIds.isNotEmpty) {
      final assignments = await (db.select(db.assignments)
            ..where((a) => a.classId.isIn(classIds)))
          .get();
      courseAssignmentIds = assignments.map((a) => a.id).toList();
    } else if (moduleIds.isNotEmpty) {
      final assignments = await (db.select(db.assignments)
            ..where((a) => a.moduleId.isIn(moduleIds)))
          .get();
      courseAssignmentIds = assignments.map((a) => a.id).toList();
    }

    List<int> courseQuizIds = [];
    if (moduleIds.isNotEmpty) {
      final quizzes = await (db.select(db.quizzes)
            ..where((q) => q.moduleId.isIn(moduleIds)))
          .get();
      courseQuizIds = quizzes.map((q) => q.id).toList();
    }

    final results = <Map<String, dynamic>>[];

    for (final userId in enrolledUserIds) {
      final user = await (db.select(db.users)
            ..where((u) => u.id.equals(userId)))
          .getSingleOrNull();
      if (user == null) continue;

      int completedLessons = 0;
      if (allLessonIds.isNotEmpty) {
        final progress = await (db.select(db.lessonProgress)
              ..where((p) => p.userId.equals(userId))
              ..where((p) => p.lessonId.isIn(allLessonIds))
              ..where((p) => p.isCompleted.equals(true)))
            .get();
        completedLessons = progress.length;
      }

      final completionRate = totalLessons > 0
          ? completedLessons / totalLessons
          : 0.0;

      double? quizAverage;
      if (courseQuizIds.isNotEmpty) {
        final attempts = await (db.select(db.quizAttempts)
              ..where((a) => a.userId.equals(userId))
              ..where((a) => a.quizId.isIn(courseQuizIds)))
            .get();
        if (attempts.isNotEmpty) {
          quizAverage = attempts.fold<double>(
                  0, (sum, a) => sum + a.scorePercentage) /
              attempts.length;
        }
      }

      double absenceRate = 0;
      int absenceCount = 0;
      if (classIds.isNotEmpty) {
        final attendances = await (db.select(db.attendances)
              ..where((a) => a.studentId.equals(userId))
              ..where((a) => a.classId.isIn(classIds)))
            .get();
        final total = attendances.length;
        absenceCount = attendances.where((a) => a.status != 'present').length;
        absenceRate = total > 0 ? absenceCount / total * 100 : 0;
      }

      double lateRate = 0;
      int lateCount = 0;
      if (courseAssignmentIds.isNotEmpty) {
        final submissions = await (db.select(db.submissions)
              ..where((s) => s.studentId.equals(userId))
              ..where((s) => s.assignmentId.isIn(courseAssignmentIds)))
            .get();
        lateCount = submissions.where((s) => s.isLate).length;
        final notSubmitted = courseAssignmentIds.length - submissions.length;
        final totalPenalizable = courseAssignmentIds.length;
        lateRate = totalPenalizable > 0
            ? (lateCount + notSubmitted) / totalPenalizable * 100
            : 0;
      }

      double progressPenalty = totalLessons > 0
          ? (1 - completionRate) * 25
          : 0;
      double quizPenalty = quizAverage != null
          ? ((100 - quizAverage) / 100) * 25
          : courseQuizIds.isNotEmpty ? 25 : 0;
      double absencePenalty = (absenceRate / 100) * 25;
      double latePenalty = (lateRate / 100) * 25;

      double riskScore = (progressPenalty + quizPenalty + absencePenalty + latePenalty)
          .clamp(0, 100);
      riskScore = (riskScore * 10).round() / 10;

      if (riskScore < 35) continue;

      final riskFactors = <String>[];
      if (completionRate < 0.3 && totalLessons > 0) {
        riskFactors.add('Tiến độ thấp (${(completionRate * 100).toStringAsFixed(0)}%)');
      }
      if (quizAverage != null && quizAverage < 50) {
        riskFactors.add('Điểm quiz thấp (${quizAverage.toStringAsFixed(0)}%)');
      }
      if (absenceCount > 0) {
        riskFactors.add('Vắng $absenceCount buổi');
      }
      if (lateCount > 0) {
        riskFactors.add('Trễ $lateCount bài tập');
      }

      final lastActivity = await (db.select(db.studentActivityLogs)
            ..where((a) => a.userId.equals(userId))
            ..orderBy([(a) => OrderingTerm.desc(a.timestamp)])
            ..limit(1))
          .getSingleOrNull();
      final daysSinceActivity = lastActivity != null
          ? DateTime.now().difference(lastActivity.timestamp).inDays
          : 30;
      if (daysSinceActivity > 7) {
        riskFactors.add('Không hoạt động $daysSinceActivity ngày');
      }

      results.add({
        'userId': userId,
        'fullName': user.fullName ?? 'Sinh viên #$userId',
        'email': user.email,
        'riskScore': riskScore,
        'riskLevel': riskScore >= 60 ? 'high' : 'medium',
        'riskFactors': riskFactors,
        'completionRate': completionRate,
        'avgQuizScore': quizAverage ?? 0,
        'daysSinceActivity': daysSinceActivity,
        'currentStreak': 0,
      });
    }

    results.sort((a, b) =>
        (b['riskScore'] as double).compareTo(a['riskScore'] as double));

    final atRiskCount = results.where((r) => r['riskLevel'] == 'high').length;

    return Response.json(body: {
      'courseId': courseId,
      'totalStudents': enrolledUserIds.length,
      'atRiskStudents': results,
      'summary': {
        'atRiskCount': atRiskCount,
        'warningCount': results.length - atRiskCount,
        'atRiskPercent': enrolledUserIds.isNotEmpty
            ? (results.length / enrolledUserIds.length * 100)
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
