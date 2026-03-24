import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/ai_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final lessonTitle = body['lessonTitle'] as String? ?? '';
    final textContent = body['textContent'] as String? ?? '';
    final timestamp = body['timestamp'] as int? ?? 0;
    final transcript = body['transcript'] as String? ?? '';
    final confusionSignals = body['confusionSignals'] as Map<String, dynamic>? ?? {};

    final minutes = timestamp ~/ 60;
    final seconds = timestamp % 60;
    final timeStr = '${minutes}:${seconds.toString().padLeft(2, '0')}';

    final contentContext = transcript.isNotEmpty ? transcript : textContent;

    final prompt = '''
Bạn là trợ lý AI học tập. Sinh viên đang xem video bài học "$lessonTitle" và gặp khó khăn tại phút $timeStr.

Dấu hiệu bối rối:
- Số lần pause: ${confusionSignals['pauseCount'] ?? 'N/A'}
- Số lần rewind: ${confusionSignals['rewindCount'] ?? 'N/A'}
- Emotion detected: ${confusionSignals['emotion'] ?? 'N/A'}

Nội dung tại đoạn gây khó khăn:
"""
$contentContext
"""

Hãy:
1. Giải thích lại nội dung đoạn này một cách đơn giản, dễ hiểu
2. Cho ví dụ minh họa nếu cần
3. Tóm tắt các ý chính bằng bullet points
4. Đề xuất câu hỏi kiểm tra hiểu biết

Trả lời bằng tiếng Việt, ngắn gọn, dễ hiểu.
''';

    final aiService = context.read<AIService>();
    final explanation = await aiService.generateExplanation(prompt);

    return Response.json(body: {
      'success': true,
      'explanation': explanation,
      'timestamp': timestamp,
      'timeStr': timeStr,
      'lessonTitle': lessonTitle,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to generate explanation: $e'},
    );
  }
}
