import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/ai_service.dart';
import 'package:backend/helpers/env_helper.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final formData = await context.request.formData();
    final fileField = formData.files['audio'];

    if (fileField == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'audio file is required'},
      );
    }

    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/stt_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    await tempFile.writeAsBytes(await fileField.readAsBytes());

    final env = loadEnv();
    final apiKey = env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      await tempFile.delete();
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'OpenAI API key not configured'},
      );
    }

    final aiService = AIService(openaiApiKey: apiKey);
    final text = await aiService.speechToText(tempFile);

    await tempFile.delete();

    return Response.json(body: {'text': text});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Speech-to-text failed: $e'},
    );
  }
}
