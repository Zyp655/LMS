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

    final lessonTitle = body['lessonTitle'] as String?;
    final currentMinute = body['currentMinute'] as int?;
    final totalMinutes = body['totalMinutes'] as int?;
    final textContent = body['textContent'] as String?;

    if (lessonTitle == null || currentMinute == null || totalMinutes == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error': 'lessonTitle, currentMinute, and totalMinutes are required'
        },
      );
    }

    final env = loadEnv();
    final apiKey = env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'OpenAI API key not configured'},
      );
    }

    final aiService = AIService(openaiApiKey: apiKey);
    final quiz = await aiService.generateVerifyQuestion(
      lessonTitle: lessonTitle,
      currentMinute: currentMinute,
      totalMinutes: totalMinutes,
      textContent: textContent,
    );

    return Response.json(body: quiz);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Verify question generation failed: $e'},
    );
  }
}
