import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

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
    final params = context.request.uri.queryParameters;
    final statusFilter = params['status'];
    final progressFilter = params['progress'];
    final sortBy = params['sortBy'];
    final sortOrder = params['sortOrder'] ?? 'asc';
    final searchQuery = params['search']?.toLowerCase();
    final threshold = int.tryParse(params['threshold'] ?? '3') ?? 3;
    final minRiskScore =
        int.tryParse(params['minRiskScore'] ?? '');
    final warningLevelFilter =
        int.tryParse(params['warningLevel'] ?? '');

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
        final classEnrollments = await (db.select(db.courseClassEnrollments)
              ..where((e) => e.courseClassId.isIn(classIds)))
            .get();
        enrolledUserIds =
            classEnrollments.map((e) => e.studentId).toSet().toList();
      }
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

    final List<Map<String, dynamic>> students = [];
    int statusNotStarted = 0;
    int statusInProgress = 0;
    int statusCompleted = 0;
    double totalProgressPercent = 0;
    double totalQuizScore = 0;
    int quizScoreCount = 0;

    final userIdsToProcess = isAcademic
        ? enrolledUserIds
        : lmsEnrollments.map((e) => e.userId).toList();

    for (final userId in userIdsToProcess) {
      final user = await (db.select(db.users)
            ..where((u) => u.id.equals(userId)))
          .getSingleOrNull();
      if (user == null) continue;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final name = (user.fullName ?? '').toLowerCase();
        final email = user.email.toLowerCase();
        if (!name.contains(searchQuery) && !email.contains(searchQuery)) {
          continue;
        }
      }

      int completedLessons = 0;
      if (allLessonIds.isNotEmpty) {
        final progress = await (db.select(db.lessonProgress)
              ..where((p) => p.userId.equals(userId))
              ..where((p) => p.lessonId.isIn(allLessonIds))
              ..where((p) => p.isCompleted.equals(true)))
            .get();
        completedLessons = progress.length;
      }

      final progressPercent = totalLessons > 0
          ? (completedLessons / totalLessons * 100).round()
          : 0;

      if (progressFilter != null) {
        if (progressFilter == 'low' && progressPercent > 30) continue;
        if (progressFilter == 'medium' &&
            (progressPercent <= 30 || progressPercent > 70)) continue;
        if (progressFilter == 'high' && progressPercent <= 70) continue;
      }

      String status;
      if (completedLessons == 0) {
        status = 'not_started';
        statusNotStarted++;
      } else if (completedLessons >= totalLessons && totalLessons > 0) {
        status = 'completed';
        statusCompleted++;
      } else {
        status = 'in_progress';
        statusInProgress++;
      }

      if (statusFilter != null && statusFilter != 'at_risk' && status != statusFilter) {
        continue;
      }

      totalProgressPercent += progressPercent;

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
          totalQuizScore += quizAverage;
          quizScoreCount++;
        }
      }

      double absenceRate = 0;
      int totalAttendances = 0;
      int absenceCount = 0;
      if (classIds.isNotEmpty) {
        final attendances = await (db.select(db.attendances)
              ..where((a) => a.studentId.equals(userId))
              ..where((a) => a.classId.isIn(classIds)))
            .get();
        totalAttendances = attendances.length;
        absenceCount =
            attendances.where((a) => a.status != 'present').length;
        absenceRate =
            totalAttendances > 0 ? absenceCount / totalAttendances * 100 : 0;
      }

      double lateRate = 0;
      int totalSubmissions = 0;
      int lateCount = 0;
      if (courseAssignmentIds.isNotEmpty) {
        final submissions = await (db.select(db.submissions)
              ..where((s) => s.studentId.equals(userId))
              ..where((s) => s.assignmentId.isIn(courseAssignmentIds)))
            .get();
        totalSubmissions = submissions.length;
        lateCount = submissions.where((s) => s.isLate).length;

        final notSubmittedCount =
            courseAssignmentIds.length - totalSubmissions;
        final totalPenalizable = courseAssignmentIds.length;

        lateRate = totalPenalizable > 0
            ? (lateCount + notSubmittedCount) / totalPenalizable * 100
            : 0;
      }

      double progressPenalty = 0;
      if (totalLessons > 0) {
        final completionRate = completedLessons / totalLessons;
        progressPenalty = (1 - completionRate) * 25;
      }

      double quizPenalty = 0;
      if (quizAverage != null) {
        quizPenalty = ((100 - quizAverage) / 100) * 25;
      } else if (courseQuizIds.isNotEmpty) {
        quizPenalty = 25;
      }

      double absencePenalty = (absenceRate / 100) * 25;
      double latePenalty = (lateRate / 100) * 25;

      double riskScore =
          (progressPenalty + quizPenalty + absencePenalty + latePenalty)
              .clamp(0, 100);
      riskScore = (riskScore * 10).round() / 10;

      int warningLevel;
      if (riskScore >= 60) {
        warningLevel = 3;
      } else if (riskScore >= 40) {
        warningLevel = 2;
      } else {
        warningLevel = 1;
      }

      if (warningLevelFilter != null && warningLevel != warningLevelFilter) {
        continue;
      }
      if (minRiskScore != null && riskScore < minRiskScore) {
        continue;
      }

      DateTime? enrolledAt;
      DateTime? lastAccessedAt;
      if (!isAcademic) {
        final enrollment =
            lmsEnrollments.firstWhere((e) => e.userId == userId);
        enrolledAt = enrollment.enrolledAt;
        lastAccessedAt = enrollment.lastAccessedAt;
      } else if (classIds.isNotEmpty) {
        final ccEnrollment = await (db.select(db.courseClassEnrollments)
              ..where((e) => e.studentId.equals(userId))
              ..where((e) => e.courseClassId.isIn(classIds))
              ..limit(1))
            .getSingleOrNull();
        if (ccEnrollment != null) {
          enrolledAt = ccEnrollment.enrolledAt;
        }
      }

      final lastActivity = await (db.select(db.studentActivityLogs)
            ..where((a) => a.userId.equals(userId))
            ..orderBy([(a) => OrderingTerm.desc(a.timestamp)])
            ..limit(1))
          .getSingleOrNull();

      if (lastAccessedAt == null && lastActivity != null) {
        lastAccessedAt = lastActivity.timestamp;
      }

      int daysInactive = 0;
      bool isAtRisk = riskScore >= 50 || status == 'not_started';
      if (lastAccessedAt != null) {
        daysInactive = DateTime.now().difference(lastAccessedAt).inDays;
        if (daysInactive >= threshold && status != 'completed') {
          isAtRisk = true;
        }
      }

      if (statusFilter == 'at_risk' && !isAtRisk) continue;

      students.add({
        'userId': user.id,
        'email': user.email,
        'fullName': user.fullName ?? 'Unknown',
        'enrolledAt':
            enrolledAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'completedLessons': completedLessons,
        'totalLessons': totalLessons,
        'progressPercent': progressPercent,
        'status': status,
        'quizAverage': quizAverage,
        'riskScore': riskScore,
        'warningLevel': warningLevel,
        'absenceRate': (absenceRate * 10).round() / 10,
        'absenceCount': absenceCount,
        'totalAttendances': totalAttendances,
        'lateRate': (lateRate * 10).round() / 10,
        'lateCount': lateCount,
        'totalAssignments': courseAssignmentIds.length,
        'lastAccessedAt': lastAccessedAt?.toIso8601String(),
        'lastNudgedAt': null,
        'daysInactive': daysInactive,
        'isAtRisk': isAtRisk,
        'lastActivity': lastActivity != null
            ? {
                'action': lastActivity.action,
                'timestamp': lastActivity.timestamp.toIso8601String(),
              }
            : null,
      });
    }

    if (sortBy != null) {
      students.sort((a, b) {
        dynamic valueA, valueB;
        switch (sortBy) {
          case 'name':
            valueA = a['fullName'] as String;
            valueB = b['fullName'] as String;
            break;
          case 'progress':
            valueA = a['progressPercent'] as int;
            valueB = b['progressPercent'] as int;
            break;
          case 'quizScore':
            valueA = a['quizAverage'] ?? 0.0;
            valueB = b['quizAverage'] ?? 0.0;
            break;
          case 'risk':
          case 'riskScore':
            valueA = a['riskScore'] as double;
            valueB = b['riskScore'] as double;
            break;
          default:
            return 0;
        }
        final comparison = (valueA as Comparable).compareTo(valueB);
        return sortOrder == 'desc' ? -comparison : comparison;
      });
    }

    final avgProgress = students.isNotEmpty
        ? (totalProgressPercent / students.length).round()
        : 0;
    final avgQuizScore = quizScoreCount > 0
        ? (totalQuizScore / quizScoreCount * 10).round() / 10
        : null;
    final atRiskCount = students.where((s) => s['isAtRisk'] as bool).length;
    final level3Count =
        students.where((s) => s['warningLevel'] == 3).length;
    final level2Count =
        students.where((s) => s['warningLevel'] == 2).length;
    final level1Count =
        students.where((s) => s['warningLevel'] == 1).length;

    return Response.json(
      body: {
        'courseId': courseId,
        'stats': {
          'totalStudents': students.length,
          'avgProgress': avgProgress,
          'avgQuizScore': avgQuizScore,
          'atRiskCount': atRiskCount,
          'byStatus': {
            'not_started': statusNotStarted,
            'in_progress': statusInProgress,
            'completed': statusCompleted,
          },
          'byWarningLevel': {
            'level1': level1Count,
            'level2': level2Count,
            'level3': level3Count,
          },
        },
        'students': students,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
