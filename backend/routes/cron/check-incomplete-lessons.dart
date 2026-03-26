import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:backend/database/database.dart';
import 'package:backend/helpers/notification_helper.dart';
import 'package:backend/helpers/env_helper.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post &&
      context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final db = context.read<AppDatabase>();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final log = <String>[];

  try {
    final courses = await db.select(db.courses).get();
    int totalNotified = 0;
    int totalAbsent = 0;

    for (final course in courses) {
      final modules = await (db.select(db.modules)
            ..where((m) => m.courseId.equals(course.id))
            ..orderBy([(m) => OrderingTerm.asc(m.orderIndex)]))
          .get();

      if (modules.isEmpty) continue;

      final unlockedModules = <Module>[];
      for (final module in modules) {
        final unlock = module.unlockDate ??
            course.createdAt.add(Duration(days: module.orderIndex * 7));
        if (!unlock.isAfter(today)) {
          unlockedModules.add(module);
        }
      }

      if (unlockedModules.isEmpty) continue;

      final unlockedModuleIds = unlockedModules.map((m) => m.id).toList();

      final lessons = await (db.select(db.lessons)
            ..where((l) => l.moduleId.isIn(unlockedModuleIds))
            ..where((l) => l.type.equals('video')))
          .get();

      if (lessons.isEmpty) continue;

      final enrollments = await (db.select(db.enrollments)
            ..where((e) => e.courseId.equals(course.id)))
          .get();

      for (final enrollment in enrollments) {
        final studentId = enrollment.userId;
        final incompleteLessons = <Map<String, dynamic>>[];

        for (final lesson in lessons) {
          final progress = await (db.select(db.lessonProgress)
                ..where((p) =>
                    p.userId.equals(studentId) &
                    p.lessonId.equals(lesson.id)))
              .getSingleOrNull();

          if (progress == null || !progress.isCompleted) {
            incompleteLessons.add({
              'lessonTitle': lesson.title,
              'moduleTitle': unlockedModules
                  .firstWhere((m) => m.id == lesson.moduleId)
                  .title,
              'watchedPosition': progress?.lastWatchedPosition ?? 0,
            });
          }
        }

        if (incompleteLessons.isEmpty) continue;

        final alreadySent = await _alreadySentToday(db, studentId, today);
        if (alreadySent) continue;

        final message = await _generateAiMessage(
          studentId: studentId,
          courseName: course.title,
          incompleteLessons: incompleteLessons,
          db: db,
        );

        await NotificationHelper.createNotification(
          db: db,
          userId: studentId,
          type: 'absence_warning',
          title: '⚠️ Cảnh báo vắng học',
          message: message,
          relatedId: course.id,
          relatedType: 'course',
        );
        totalNotified++;

        final classQuery = await (db.select(db.courseClasses)
              ..where((c) => c.academicCourseId.isNotNull())
              ..limit(1))
            .getSingleOrNull();

        if (classQuery != null) {
          final existing = await (db.select(db.attendances)
                ..where((a) =>
                    a.studentId.equals(studentId) &
                    a.classId.equals(classQuery.id) &
                    a.date.equals(today)))
              .getSingleOrNull();

          if (existing == null) {
            await db.into(db.attendances).insert(
                  AttendancesCompanion.insert(
                    classId: classQuery.id,
                    studentId: studentId,
                    date: today,
                    status: 'absent',
                    note: Value(
                        'Auto: chưa hoàn thành ${incompleteLessons.length} bài trong ${course.title}'),
                    markedBy: 0,
                    markedAt: now,
                  ),
                );
            totalAbsent++;
          }
        }

        log.add(
          'Student #$studentId: ${incompleteLessons.length} bài chưa hoàn thành trong "${course.title}"',
        );
      }
    }

    return Response.json(body: {
      'success': true,
      'checkedAt': now.toIso8601String(),
      'totalNotified': totalNotified,
      'totalAbsent': totalAbsent,
      'log': log,
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': '$e'},
    );
  }
}

Future<bool> _alreadySentToday(
    AppDatabase db, int studentId, DateTime today) async {
  final existing = await (db.select(db.notifications)
        ..where((n) =>
            n.userId.equals(studentId) &
            n.type.equals('absence_warning') &
            n.createdAt.isBiggerOrEqualValue(today))
        ..limit(1))
      .getSingleOrNull();
  return existing != null;
}

Future<String> _generateAiMessage({
  required int studentId,
  required String courseName,
  required List<Map<String, dynamic>> incompleteLessons,
  required AppDatabase db,
}) async {
  try {
    final env = loadEnv();
    final apiKey = env['OPENAI_API_KEY'];
    if (apiKey == null) return _fallbackMessage(courseName, incompleteLessons);

    final user = await (db.select(db.users)
          ..where((u) => u.id.equals(studentId)))
        .getSingleOrNull();

    final studentName = user?.fullName ?? 'Bạn';
    final lessonList = incompleteLessons
        .map((l) => '- ${l['lessonTitle']} (Chương: ${l['moduleTitle']})')
        .join('\n');

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'Bạn là trợ lý học tập AI trong hệ thống LMS. '
                'Viết thông báo ngắn gọn, thân thiện nhưng nghiêm túc bằng tiếng Việt. '
                'Tối đa 3 câu. Không dùng emoji quá nhiều. '
                'Mục đích: nhắc nhở học sinh hoàn thành bài học, cảnh báo sẽ bị tính vắng.',
          },
          {
            'role': 'user',
            'content':
                'Học sinh: $studentName\n'
                'Khóa học: $courseName\n'
                'Các bài chưa hoàn thành (chưa xem đủ 90% video):\n$lessonList\n\n'
                'Hãy viết thông báo nhắc nhở học sinh hoàn thành các bài trên, '
                'cảnh báo rằng nếu không hoàn thành sẽ bị tính là vắng.',
          },
        ],
        'max_tokens': 200,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List;
      final content =
          (choices[0]['message'] as Map<String, dynamic>)['content'] as String;
      return content.trim();
    }
  } catch (_) {}

  return _fallbackMessage(courseName, incompleteLessons);
}

String _fallbackMessage(
    String courseName, List<Map<String, dynamic>> incompleteLessons) {
  return 'Bạn chưa hoàn thành ${incompleteLessons.length} bài học '
      'trong khóa "$courseName". Vui lòng xem đủ 90% video để không bị tính vắng.';
}
