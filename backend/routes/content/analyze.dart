import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/ai_service.dart';
import 'package:backend/helpers/env_helper.dart';
Future<Response> onRequest(RequestContext context) async {
  final request = context.request;
  final method = request.method;
  if (method == HttpMethod.post) {
    return _analyzeContent(context);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}
Future<Response> _analyzeContent(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    if (!body.containsKey('fileName') || !body.containsKey('fileType')) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'fileName and fileType are required'},
      );
    }
    final fileName = body['fileName'] as String;
    final fileType = body['fileType'] as String;
    final content = body['content'] as String? ?? fileName;
    final env = loadEnv();
    final openaiApiKey = env['OPENAI_API_KEY'];
    if (openaiApiKey == null || openaiApiKey.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'OpenAI API key not configured'},
      );
    }
    final aiService = AIService(openaiApiKey: openaiApiKey);
    final result = await aiService.analyzeContentStructure(
      content: content,
      fileName: fileName,
      fileType: fileType,
    );
    return Response.json(body: result);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
