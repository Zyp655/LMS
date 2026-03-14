import 'dart:convert' show jsonDecode;
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:backend/services/ai_service.dart';
import 'package:drift/drift.dart';
import 'package:dotenv/dotenv.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final db = context.read<AppDatabase>();
    final body = await context.request.json() as Map<String, dynamic>;
    final userId = body['userId'] as int?;

    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'userId is required'},
      );
    }

    final enrollments = await (db.select(db.enrollments)
          ..where((e) => e.userId.equals(userId)))
        .get();
    final courseIds = enrollments.map((e) => e.courseId).toList();

    final quizStats = await (db.select(db.quizStatistics)
          ..where((s) => s.userId.equals(userId)))
        .get();
    final weakTopics = quizStats
        .where((s) => s.skillLevel < 0.5)
        .map((s) => '${s.topic} (${(s.averageScore).toStringAsFixed(0)}%)')
        .toList();
    final strongTopics = quizStats
        .where((s) => s.skillLevel >= 0.7)
        .map((s) => s.topic)
        .toList();

    final completedProgress = await (db.select(db.lessonProgress)
          ..where((p) => p.userId.equals(userId))
          ..where((p) => p.isCompleted.equals(true)))
        .get();
    final completedLessonIds = completedProgress.map((p) => p.lessonId).toSet();

    final allLessons = <Map<String, dynamic>>[];
    for (final courseId in courseIds) {
      final course = await (db.select(db.courses)
            ..where((c) => c.id.equals(courseId)))
          .getSingleOrNull();
      final modules = await (db.select(db.modules)
            ..where((m) => m.courseId.equals(courseId))
            ..orderBy([(m) => OrderingTerm.asc(m.orderIndex)]))
          .get();
      for (final module in modules) {
        final lessons = await (db.select(db.lessons)
              ..where((l) => l.moduleId.equals(module.id))
              ..orderBy([(l) => OrderingTerm.asc(l.orderIndex)]))
            .get();
        for (final lesson in lessons) {
          allLessons.add({
            'id': lesson.id,
            'title': lesson.title,
            'type': lesson.type,
            'moduleTitle': module.title,
            'courseTitle': course?.title ?? '',
            'courseId': courseId,
            'completed': completedLessonIds.contains(lesson.id),
          });
        }
      }
    }

    final incompleteLessons =
        allLessons.where((l) => !(l['completed'] as bool)).toList();

    final env = DotEnv(includePlatformEnvironment: true)..load();
    final apiKey = env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      return _buildResponse(incompleteLessons, weakTopics, strongTopics, null);
    }

    final aiService = AIService(openaiApiKey: apiKey);

    final prompt = '''
Bạn là hệ thống gợi ý học tập AI. Dựa trên dữ liệu sinh viên, hãy đề xuất kế hoạch học tập cá nhân hóa.

Dữ liệu sinh viên:
- Chủ đề yếu: ${weakTopics.isEmpty ? 'Chưa có dữ liệu quiz' : weakTopics.join(', ')}
- Chủ đề mạnh: ${strongTopics.isEmpty ? 'Chưa có' : strongTopics.join(', ')}
- Số bài đã hoàn thành: ${completedLessonIds.length}
- Số bài chưa hoàn thành: ${incompleteLessons.length}
- Bài chưa hoàn thành: ${incompleteLessons.take(15).map((l) => '"${l['title']}" (${l['moduleTitle']})').join(', ')}

Trả về JSON (KHÔNG có markdown):
{
  "studyPlan": "Kế hoạch học tập cá nhân 2-3 câu",
  "priorityLessons": ["tên bài ưu tiên 1", "tên bài ưu tiên 2", "tên bài ưu tiên 3"],
  "suggestedTopics": ["Chủ đề cần ôn 1", "Chủ đề cần ôn 2"],
  "tips": ["Mẹo 1", "Mẹo 2", "Mẹo 3"]
}
''';

    try {
      final response = await aiService.chatWithAssistant(
        question: prompt,
        history: [],
      );

      Map<String, dynamic>? aiResult;
      try {
        var cleaned =
            response.replaceAll('```json', '').replaceAll('```', '').trim();
        final jsonStart = cleaned.indexOf('{');
        final jsonEnd = cleaned.lastIndexOf('}');
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
        }
        aiResult = Map<String, dynamic>.from(jsonDecode(cleaned) as Map);
      } catch (_) {
        aiResult = null;
      }

      return _buildResponse(incompleteLessons, weakTopics, strongTopics, aiResult);
    } catch (_) {
      return _buildResponse(incompleteLessons, weakTopics, strongTopics, null);
    }
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Lỗi hệ thống'},
    );
  }
}

Response _buildResponse(
  List<Map<String, dynamic>> incompleteLessons,
  List<String> weakTopics,
  List<String> strongTopics,
  Map<String, dynamic>? aiResult,
) {
  final priorityNames =
      (aiResult?['priorityLessons'] as List?)?.cast<String>() ?? [];

  final recommendedLessons = <Map<String, dynamic>>[];
  for (final name in priorityNames) {
    final match = incompleteLessons.where(
      (l) =>
          (l['title'] as String).toLowerCase().contains(name.toLowerCase()),
    );
    if (match.isNotEmpty &&
        !recommendedLessons.any((r) => r['id'] == match.first['id'])) {
      recommendedLessons.add(match.first);
    }
  }
  for (final lesson in incompleteLessons) {
    if (recommendedLessons.length >= 6) break;
    if (!recommendedLessons.any((r) => r['id'] == lesson['id'])) {
      recommendedLessons.add(lesson);
    }
  }

  return Response.json(body: {
    'success': true,
    'studyPlan': aiResult?['studyPlan'] ??
        (weakTopics.isNotEmpty
            ? 'Bạn nên ôn tập các chủ đề: ${weakTopics.join(', ')}'
            : 'Tiếp tục hoàn thành các bài học chưa hoàn thành.'),
    'suggestedTopics': aiResult?['suggestedTopics'] ?? weakTopics,
    'tips': aiResult?['tips'] ??
        [
          'Ôn tập lại chủ đề yếu trước khi học bài mới',
          'Hoàn thành bài tập đúng hạn để củng cố kiến thức',
          'Dùng AI chat để hỏi khi không hiểu bài',
        ],
    'recommendedLessons': recommendedLessons,
    'weakTopics': weakTopics,
    'strongTopics': strongTopics,
    'totalIncomplete': incompleteLessons.length,
    'totalCompleted':
        incompleteLessons.isEmpty ? 0 : null,
  });
}
