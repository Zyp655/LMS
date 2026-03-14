import 'dart:io';
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/ai_service.dart';
import 'package:dotenv/dotenv.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final fileContent = body['fileContent'] as String? ?? '';
    final numQuestions = body['numQuestions'] as int? ?? 10;
    final difficulty = body['difficulty'] as String? ?? 'medium';

    if (fileContent.trim().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'fileContent is required'},
      );
    }

    final env = DotEnv(includePlatformEnvironment: true)..load();
    final apiKey = env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.serviceUnavailable,
        body: {'error': 'AI service not configured'},
      );
    }

    final aiService = AIService(openaiApiKey: apiKey);

    final truncated = fileContent.length > 8000
        ? fileContent.substring(0, 8000)
        : fileContent;

    final prompt = '''
Bạn là giáo viên chuyên nghiệp. Dựa trên nội dung tài liệu bên dưới, hãy tạo $numQuestions câu hỏi trắc nghiệm mức độ $difficulty.

Nội dung tài liệu:
"""
$truncated
"""

Yêu cầu:
- Mỗi câu có 4 lựa chọn A, B, C, D
- Chỉ 1 đáp án đúng
- Có giải thích ngắn cho mỗi đáp án đúng
- Độ khó: $difficulty (easy/medium/hard)

Trả về JSON (KHÔNG markdown):
{
  "questions": [
    {
      "question": "Nội dung câu hỏi?",
      "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
      "correctIndex": 0,
      "explanation": "Giải thích tại sao đáp án đúng",
      "difficulty": "$difficulty"
    }
  ]
}
''';

    final response = await aiService.chatWithAssistant(
      question: prompt,
      history: [],
    );

    Map<String, dynamic>? parsed;
    try {
      var cleaned = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
      }
      parsed = Map<String, dynamic>.from(jsonDecode(cleaned) as Map);
    } catch (_) {
      parsed = null;
    }

    if (parsed == null || parsed['questions'] == null) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'AI không thể tạo quiz từ nội dung này'},
      );
    }

    return Response.json(body: {
      'success': true,
      'questions': parsed['questions'],
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Lỗi: $e'},
    );
  }
}
