import 'dart:io';
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/helpers/env_helper.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final docUrl = body['documentUrl'] as String?;

    if (docUrl == null || docUrl.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'documentUrl is required'},
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

    final docResponse = await http.get(Uri.parse(docUrl));
    if (docResponse.statusCode != 200) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Cannot download document: ${docResponse.statusCode}'},
      );
    }

    final bytes = docResponse.bodyBytes;
    final lowerUrl = docUrl.toLowerCase();

    String extractedText = '';

    if (lowerUrl.endsWith('.txt') || lowerUrl.endsWith('.md')) {
      extractedText = utf8.decode(bytes, allowMalformed: true);
    } else if (lowerUrl.endsWith('.pdf')) {
      extractedText = _extractTextFromPdf(bytes);
    } else {
      extractedText = utf8.decode(bytes, allowMalformed: true);
      extractedText = extractedText.replaceAll(
          RegExp(r'[^\x20-\x7E\u00C0-\u024F\u1E00-\u1EFF\s]'), '');
    }

    extractedText = extractedText.trim();

    if (extractedText.isEmpty || extractedText.length < 20) {
      final summaryResponse = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Tài liệu không thể trích xuất nội dung text. Hãy thông báo cho người dùng rằng tài liệu này là dạng scan/hình ảnh và AI không thể đọc được. Đề xuất họ đặt câu hỏi cụ thể.',
            },
            {
              'role': 'user',
              'content': 'Tài liệu: $docUrl',
            },
          ],
        }),
      );

      if (summaryResponse.statusCode == 200) {
        final data = jsonDecode(summaryResponse.body);
        final fallbackMsg = data['choices'][0]['message']['content'] as String;
        return Response.json(body: {
          'text': fallbackMsg,
          'isExtracted': false,
        });
      }

      return Response.json(body: {
        'text': 'Không thể trích xuất nội dung từ tài liệu này.',
        'isExtracted': false,
      });
    }

    return Response.json(body: {
      'text': extractedText,
      'isExtracted': true,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Document extraction failed: $e'},
    );
  }
}

String _extractTextFromPdf(List<int> bytes) {
  final buffer = StringBuffer();
  final content = String.fromCharCodes(bytes);

  final streamPattern = RegExp(r'stream\s*([\s\S]*?)\s*endstream');
  final matches = streamPattern.allMatches(content);

  for (final match in matches) {
    final streamContent = match.group(1) ?? '';

    final textOps = RegExp(r'\(((?:[^\\)]|\\.)*)\)\s*Tj');
    for (final textMatch in textOps.allMatches(streamContent)) {
      var text = textMatch.group(1) ?? '';
      text = text
          .replaceAll(r'\(', '(')
          .replaceAll(r'\)', ')')
          .replaceAll(r'\\', r'\')
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\r', '\r')
          .replaceAll(r'\t', '\t');
      buffer.write(text);
    }

    final tjArray = RegExp(r'\[((?:\([^)]*\)|[^\]])*)\]\s*TJ');
    for (final arrayMatch in tjArray.allMatches(streamContent)) {
      final arrayContent = arrayMatch.group(1) ?? '';
      final stringParts = RegExp(r'\(((?:[^\\)]|\\.)*)\)');
      for (final part in stringParts.allMatches(arrayContent)) {
        var text = part.group(1) ?? '';
        text = text
            .replaceAll(r'\(', '(')
            .replaceAll(r'\)', ')')
            .replaceAll(r'\\', r'\')
            .replaceAll(r'\n', '\n');
        buffer.write(text);
      }
    }

    if (streamContent.contains('ET') && buffer.isNotEmpty) {
      buffer.write(' ');
    }
  }

  var result = buffer.toString();
  result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
  return result;
}
