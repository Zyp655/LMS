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
    final fileContent = body['fileContent'] as String? ?? '';
    final numQuestions = body['numQuestions'] as int? ?? 10;
    final difficulty = body['difficulty'] as String? ?? 'medium';
    final imageBase64List = (body['imageBase64List'] as List?)
        ?.cast<String>() ?? [];
    final imageSource = body['imageSource'] as String? ?? 'unknown';
    final imageDetail = body['imageDetail'] as String? ?? 'high';

    if (fileContent.trim().isEmpty && imageBase64List.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'fileContent hoặc ảnh là bắt buộc'},
      );
    }

    final env = loadEnv();
    final apiKey = env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.serviceUnavailable,
        body: {'error': 'AI service not configured'},
      );
    }

    final truncated = fileContent.length > 8000
        ? fileContent.substring(0, 8000)
        : fileContent;

    final imageContext = imageBase64List.isEmpty
        ? ''
        : imageSource == 'pdf'
            ? 'Các hình ảnh đính kèm là ảnh render từng trang PDF. Hãy phân tích kỹ mọi nội dung trực quan: biểu đồ, sơ đồ, công thức, bảng biểu.'
            : 'Các hình ảnh đính kèm là ảnh nhúng trong tài liệu DOCX. Hãy phân tích nội dung trong từng ảnh.';

    final prompt = '''
Bạn là giáo viên chuyên nghiệp. Dựa trên nội dung tài liệu${imageBase64List.isNotEmpty ? ' và các hình ảnh đính kèm' : ''} bên dưới, hãy tạo $numQuestions câu hỏi trắc nghiệm mức độ $difficulty.

${truncated.isNotEmpty ? 'Nội dung tài liệu:\n"""\n$truncated\n"""' : ''}

$imageContext

Yêu cầu:
- Mỗi câu có 4 lựa chọn A, B, C, D
- Chỉ 1 đáp án đúng
- Có giải thích ngắn cho mỗi đáp án đúng
- Độ khó: $difficulty (easy/medium/hard)
${imageBase64List.isNotEmpty ? '- Ưu tiên tạo câu hỏi từ nội dung trong ảnh (biểu đồ, sơ đồ, công thức)' : ''}

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

    final contentParts = <Map<String, dynamic>>[
      {'type': 'text', 'text': prompt},
    ];

    for (final img in imageBase64List) {
      contentParts.add({
        'type': 'image_url',
        'image_url': {
          'url': 'data:image/png;base64,$img',
          'detail': imageDetail,
        },
      });
    }

    final model = imageBase64List.isNotEmpty ? 'gpt-4o-mini' : 'gpt-4o-mini';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': imageBase64List.isNotEmpty ? contentParts : prompt,
          },
        ],
        'max_tokens': 3000,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'AI API lỗi: ${response.statusCode}'},
      );
    }

    final responseData = jsonDecode(response.body);
    final text = responseData['choices'][0]['message']['content'] as String;

    Map<String, dynamic>? parsed;
    try {
      var cleaned = text
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
      'hasImages': imageBase64List.isNotEmpty,
      'imageCount': imageBase64List.length,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Lỗi: $e'},
    );
  }
}
