import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:backend/services/ai_service.dart';
import 'package:backend/helpers/env_helper.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final lessonTitle = body['lessonTitle'] as String? ?? '';
    final lessonId = body['lessonId'] as int?;
    final timestamp = body['timestamp'] as int? ?? 0;
    final totalDuration = body['totalDuration'] as int? ?? 0;
    final confusionSignals =
        body['confusionSignals'] as Map<String, dynamic>? ?? {};

    final minutes = timestamp ~/ 60;
    final seconds = timestamp % 60;
    final timeStr = '${minutes}:${seconds.toString().padLeft(2, '0')}';

    String segmentContent = '';

    if (lessonId != null) {
      final db = context.read<AppDatabase>();
      final lesson = await (db.select(db.lessons)
            ..where((t) => t.id.equals(lessonId)))
          .getSingleOrNull();

      if (lesson != null &&
          lesson.cachedTranscript != null &&
          lesson.cachedTranscript!.length > 10) {
        segmentContent = _extractSegment(
          lesson.cachedTranscript!,
          timestamp,
          totalDuration,
        );
      } else if (lesson != null &&
          lesson.textContent != null &&
          lesson.textContent!.length > 10) {
        segmentContent = _extractSegment(
          lesson.textContent!,
          timestamp,
          totalDuration,
        );
      }
    }

    final env = loadEnv();
    final apiKey = env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'OpenAI API key not configured'},
      );
    }

    final hasTranscript = segmentContent.length > 10;

    final prompt = '''
Bạn là trợ lý AI học tập. Sinh viên đang xem video bài học "$lessonTitle" và gặp khó khăn tại phút $timeStr.

Dấu hiệu bối rối:
- Số lần pause: ${confusionSignals['pauseCount'] ?? 0}
- Số lần rewind: ${confusionSignals['rewindCount'] ?? 0}
- Emotion detected: ${confusionSignals['emotion'] ?? 'confused'}

${hasTranscript ? '''Nội dung video tại đoạn gây khó khăn (phút $timeStr):
"""
$segmentContent
"""''' : '''Nội dung chi tiết của video chưa có sẵn.
Dựa vào chủ đề bài học "$lessonTitle" và thời điểm phút $timeStr/${totalDuration ~/ 60} phút tổng.'''}

QUAN TRỌNG: Trả lời theo format JSON sau (CHỈ JSON, KHÔNG có text khác):
{
  "contentPoints": [
    "Nội dung chính 1 đang được giảng tại thời điểm này",
    "Nội dung chính 2 đang được giảng tại thời điểm này",
    "Nội dung chính 3 (nếu có)"
  ],
  "summary": "Tóm tắt ngắn gọn 1-2 câu về nội dung đoạn này"
}

Yêu cầu:
- contentPoints: Liệt kê 2-4 ý chính đang được giảng tại thời điểm này, mỗi ý ngắn gọn (1-2 câu)
- summary: Tóm tắt ngắn gọn nội dung đoạn video
- Viết bằng tiếng Việt, dễ hiểu
''';

    final aiService = AIService(openaiApiKey: apiKey);
    final raw = await aiService.generateExplanation(prompt);

    List<String> contentPoints = [];
    String summary = raw;

    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
      if (jsonMatch != null) {
        final parsed =
            (await Future.value(jsonDecode(jsonMatch.group(0)!)))
                as Map<String, dynamic>;
        final pts = parsed['contentPoints'] as List<dynamic>?;
        if (pts != null) {
          contentPoints = pts.map((e) => e.toString()).toList();
        }
        summary = parsed['summary'] as String? ?? raw;
      }
    } catch (_) {
      final lines = raw.split('\n');
      for (final line in lines) {
        final match = RegExp(r'^\d+[\.\)]\s*(.+)').firstMatch(line.trim());
        if (match != null) contentPoints.add(match.group(1)!);
      }
      if (contentPoints.isEmpty) contentPoints = [raw];
    }

    return Response.json(body: {
      'success': true,
      'explanation': summary,
      'contentPoints': contentPoints,
      'timestamp': timestamp,
      'timeStr': timeStr,
      'lessonTitle': lessonTitle,
      'hasTranscript': hasTranscript,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to generate explanation: $e'},
    );
  }
}

String _extractSegment(String transcript, int timestamp, int totalDuration) {
  final words = transcript.split(RegExp(r'\s+'));
  final totalWords = words.length;

  if (totalDuration <= 0 || totalWords <= 20) return transcript;

  final wordsPerSecond = totalWords / totalDuration;
  final windowStart = (timestamp - 120).clamp(0, totalDuration);
  final windowEnd = (timestamp + 30).clamp(0, totalDuration);

  final startWord = (windowStart * wordsPerSecond).round().clamp(0, totalWords);
  final endWord = (windowEnd * wordsPerSecond).round().clamp(0, totalWords);

  if (endWord <= startWord) return transcript;

  return words.sublist(startWord, endWord).join(' ');
}
