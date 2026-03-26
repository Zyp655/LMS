import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/helpers/env_helper.dart';
import '../../lib/services/ai_service.dart';
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }
  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final topic = data['topic'] as String?;
    final numQuestions = data['numQuestions'] as int? ?? 5;
    final difficulty = data['difficulty'] as String? ?? 'medium';
    final subjectContext = data['subjectContext'] as String?;
    final videoUrl = data['videoUrl'] as String?;
    if (topic == null || topic.isEmpty) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'Topic is required'}),
      );
    }
    if (numQuestions < 1 || numQuestions > 20) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode(
            {'error': 'Number of questions must be between 1 and 20'}),
      );
    }
    final env = loadEnv();
    final openaiApiKey = env['OPENAI_API_KEY'];
    if (openaiApiKey == null || openaiApiKey.isEmpty) {
      return Response(
        statusCode: HttpStatus.internalServerError,
        body: jsonEncode({'error': 'OpenAI API key not configured'}),
      );
    }
    final aiService = AIService(
      openaiApiKey: openaiApiKey,
    );
    final quiz = await aiService.generateQuiz(
      topic: topic,
      numQuestions: numQuestions,
      difficulty: difficulty,
      subjectContext: subjectContext,
      videoUrl: videoUrl,
    );
    return Response.json(
      body: {
        'success': true,
        'quiz': quiz,
      },
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({
        'success': false,
        'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.',
      }),
    );
  }
}
