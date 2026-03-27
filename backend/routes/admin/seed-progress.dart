import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:backend/database/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }

  try {
    final db = context.read<AppDatabase>();
    final now = DateTime.now();
    final random = Random(42);
    final log = <String>[];

    final allClasses = await db.select(db.courseClasses).get();
    if (allClasses.isEmpty) {
      return Response.json(body: {'error': 'No course classes found. Run seed-users first.'});
    }

    final classIds = allClasses.map((c) => c.id).toList();
    final enrollments = await (db.select(db.courseClassEnrollments)
          ..where((e) => e.courseClassId.isIn(classIds)))
        .get();

    if (enrollments.isEmpty) {
      return Response.json(body: {'error': 'No enrollments found.'});
    }

    final studentIds = enrollments.map((e) => e.studentId).toSet().toList();

    final progressProfiles = <int, Map<String, dynamic>>{};
    final weightedTemplates = [
      {'minProgress': 0.85, 'maxProgress': 1.0, 'label': 'excellent', 'quizMin': 80.0, 'quizMax': 100.0, 'streakMin': 10, 'streakMax': 30},
      {'minProgress': 0.85, 'maxProgress': 1.0, 'label': 'excellent', 'quizMin': 75.0, 'quizMax': 95.0, 'streakMin': 7, 'streakMax': 25},
      {'minProgress': 0.70, 'maxProgress': 0.90, 'label': 'excellent', 'quizMin': 70.0, 'quizMax': 90.0, 'streakMin': 5, 'streakMax': 20},
      {'minProgress': 0.75, 'maxProgress': 0.95, 'label': 'excellent', 'quizMin': 72.0, 'quizMax': 92.0, 'streakMin': 8, 'streakMax': 22},
      {'minProgress': 0.60, 'maxProgress': 0.84, 'label': 'good', 'quizMin': 55.0, 'quizMax': 80.0, 'streakMin': 4, 'streakMax': 15},
      {'minProgress': 0.55, 'maxProgress': 0.78, 'label': 'good', 'quizMin': 50.0, 'quizMax': 75.0, 'streakMin': 3, 'streakMax': 12},
      {'minProgress': 0.65, 'maxProgress': 0.82, 'label': 'good', 'quizMin': 58.0, 'quizMax': 82.0, 'streakMin': 5, 'streakMax': 14},
      {'minProgress': 0.35, 'maxProgress': 0.59, 'label': 'average', 'quizMin': 35.0, 'quizMax': 60.0, 'streakMin': 1, 'streakMax': 7},
      {'minProgress': 0.40, 'maxProgress': 0.55, 'label': 'average', 'quizMin': 40.0, 'quizMax': 65.0, 'streakMin': 2, 'streakMax': 8},
      {'minProgress': 0.15, 'maxProgress': 0.34, 'label': 'struggling', 'quizMin': 15.0, 'quizMax': 45.0, 'streakMin': 0, 'streakMax': 3},
      {'minProgress': 0.0, 'maxProgress': 0.14, 'label': 'at_risk', 'quizMin': 0.0, 'quizMax': 20.0, 'streakMin': 0, 'streakMax': 1},
    ];

    for (var i = 0; i < studentIds.length; i++) {
      final idx = i % weightedTemplates.length;
      progressProfiles[studentIds[i]] = weightedTemplates[idx];
    }

    int lessonProgressCreated = 0;
    int quizAttemptsCreated = 0;
    int streaksCreated = 0;

    for (final studentId in studentIds) {
      final profile = progressProfiles[studentId]!;
      final minP = profile['minProgress'] as double;
      final maxP = profile['maxProgress'] as double;

      final studentEnrollments = enrollments.where((e) => e.studentId == studentId).toList();

      for (final enrollment in studentEnrollments) {
        final courseClass = allClasses.firstWhere((c) => c.id == enrollment.courseClassId);
        final academicCourseId = courseClass.academicCourseId;

        final modules = await (db.select(db.modules)
              ..where((m) => m.academicCourseId.equals(academicCourseId)))
            .get();
        if (modules.isEmpty) continue;

        final moduleIds = modules.map((m) => m.id).toList();
        final lessons = await (db.select(db.lessons)
              ..where((l) => l.moduleId.isIn(moduleIds)))
            .get();
        if (lessons.isEmpty) continue;

        final progressRate = minP + random.nextDouble() * (maxP - minP);
        final completedCount = (lessons.length * progressRate).round();

        final shuffledLessons = List.of(lessons)..shuffle(random);
        for (var i = 0; i < shuffledLessons.length; i++) {
          final lesson = shuffledLessons[i];
          final isCompleted = i < completedCount;

          final existing = await (db.select(db.lessonProgress)
                ..where((p) => p.userId.equals(studentId))
                ..where((p) => p.lessonId.equals(lesson.id)))
              .getSingleOrNull();
          if (existing != null) continue;

          final daysAgo = random.nextInt(60) + 1;
          final completedAt = now.subtract(Duration(days: daysAgo, hours: random.nextInt(12)));
          final dur = lesson.durationMinutes;
          final watchedPosition = isCompleted
              ? dur * 60
              : (dur * 60 * (random.nextDouble() * 0.7 + 0.1)).round();

          await db.into(db.lessonProgress).insert(
            LessonProgressCompanion.insert(
              userId: studentId,
              lessonId: lesson.id,
              lastWatchedPosition: Value(watchedPosition),
              isCompleted: Value(isCompleted),
              completedAt: isCompleted ? Value(completedAt) : const Value.absent(),
              updatedAt: completedAt,
            ),
          );
          lessonProgressCreated++;
        }

        final quizzes = await (db.select(db.quizzes)
              ..where((q) => q.moduleId.isIn(moduleIds)))
            .get();

        final quizMin = profile['quizMin'] as double;
        final quizMax = profile['quizMax'] as double;

        for (final quiz in quizzes) {
          final existingAttempt = await (db.select(db.quizAttempts)
                ..where((a) => a.userId.equals(studentId))
                ..where((a) => a.quizId.equals(quiz.id)))
              .getSingleOrNull();
          if (existingAttempt != null) continue;

          final score = quizMin + random.nextDouble() * (quizMax - quizMin);
          final totalQ = quiz.questionCount;
          final correct = (totalQ * score / 100).round().clamp(0, totalQ);
          final timeSpent = totalQ * (random.nextInt(30) + 15);

          await db.into(db.quizAttempts).insert(
            QuizAttemptsCompanion.insert(
              quizId: quiz.id,
              userId: studentId,
              correctCount: correct,
              totalQuestions: totalQ,
              scorePercentage: (score * 10).round() / 10.0,
              timeSpentSeconds: timeSpent,
              answers: '[]',
              completedAt: now.subtract(Duration(days: random.nextInt(45) + 1)),
            ),
          );
          quizAttemptsCreated++;
        }
      }

      final streakMin = profile['streakMin'] as int;
      final streakMax = profile['streakMax'] as int;
      final currentStreak = streakMin + random.nextInt(streakMax - streakMin + 1);
      final longestStreak = currentStreak + random.nextInt(10);
      final totalDays = longestStreak + random.nextInt(30);

      final existingStreak = await (db.select(db.userStreaks)
            ..where((s) => s.userId.equals(studentId)))
          .getSingleOrNull();

      if (existingStreak == null) {
        await db.into(db.userStreaks).insert(
          UserStreaksCompanion.insert(
            userId: studentId,
            currentStreak: Value(currentStreak),
            longestStreak: Value(longestStreak),
            lastActivityDate: Value(now.subtract(Duration(days: currentStreak > 0 ? 0 : random.nextInt(30) + 5))),
            totalDaysActive: Value(totalDays),
          ),
        );
        streaksCreated++;
      }
    }

    log.add('Lesson progress: $lessonProgressCreated records');
    log.add('Quiz attempts: $quizAttemptsCreated records');
    log.add('User streaks: $streaksCreated records');
    log.add('Students processed: ${studentIds.length}');

    return Response.json(
      body: {
        'success': true,
        'message': 'Seed progress done: $lessonProgressCreated lesson progress, $quizAttemptsCreated quiz attempts, $streaksCreated streaks',
        'lessonProgressCreated': lessonProgressCreated,
        'quizAttemptsCreated': quizAttemptsCreated,
        'streaksCreated': streaksCreated,
        'log': log,
      },
    );
  } catch (e, st) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({
        'success': false,
        'error': '$e',
        'stackTrace': '$st',
      }),
    );
  }
}
