import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/ai_service.dart';
import 'package:backend/helpers/env_helper.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final question = body['question'] as String?;

    if (question == null || question.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'question is required'},
      );
    }

    final rawHistory = body['history'] as List<dynamic>? ?? [];
    final history = rawHistory.map((h) {
      final m = h as Map<String, dynamic>;
      return {
        'role': m['role'] as String? ?? 'user',
        'content': m['content'] as String? ?? '',
      };
    }).toList();

    final env = loadEnv();
    final apiKey = env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'OpenAI API key not configured'},
      );
    }

    final aiService = AIService(openaiApiKey: apiKey);
    final answer = await aiService.chatWithAssistant(
      history: history,
      question: question,
    );

    return Response.json(body: {'answer': answer});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'AI assistant failed: $e'},
    );
  }
}
