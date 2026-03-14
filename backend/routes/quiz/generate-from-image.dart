import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
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
    final imageBase64 = data['imageBase64'] as String?;
    final imageUrl = data['imageUrl'] as String?;
    final numQuestions = data['numQuestions'] as int? ?? 5;
    final difficulty = data['difficulty'] as String? ?? 'medium';
    if (imageBase64 == null && imageUrl == null) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'imageBase64 or imageUrl is required'}),
      );
    }
    final env = DotEnv(includePlatformEnvironment: true)..load();
    final openaiApiKey = env['OPENAI_API_KEY'];
    if (openaiApiKey == null || openaiApiKey.isEmpty) {
      return Response(
        statusCode: HttpStatus.internalServerError,
        body: jsonEncode({'error': 'OpenAI API key not configured'}),
      );
    }
    final imageContent = imageBase64 != null
        ? {
            'type': 'image_url',
            'image_url': {
              'url': 'data:image/jpeg;base64,$imageBase64',
            },
          }
        : {
            'type': 'image_url',
            'image_url': {'url': imageUrl},
          };
    final difficultyVi = {
      'easy': 'dễ',
      'medium': 'trung bình',
      'hard': 'khó',
    };
    final prompt = '''
Dựa vào nội dung trong hình ảnh này, hãy tạo $numQuestions câu hỏi trắc nghiệm ở mức độ ${difficultyVi[difficulty] ?? difficulty}.
Trả về KẾT QUẢ DẠNG JSON với format sau (KHÔNG có markdown, CHỈ JSON thuần):
{
  "topic": "Chủ đề từ hình ảnh",
  "difficulty": "$difficulty",
  "questions": [
    {
      "question": "Nội dung câu hỏi?",
      "options": ["Đáp án A", "Đáp án B", "Đáp án C", "Đáp án D"],
      "correctIndex": 0,
      "explanation": "Giải thích tại sao đáp án đúng"
    }
  ]
}
Lưu ý:
- correctIndex là chỉ số của đáp án đúng (0-3)
- Mỗi câu có đúng 4 đáp án
- Câu hỏi phải dựa trên nội dung trong hình
- CHỈ TRẢ VỀ JSON, KHÔNG CÓ TEXT KHÁC
''';
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openaiApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              imageContent,
            ],
          },
        ],
        'max_tokens': 2048,
      }),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final text = responseData['choices'][0]['message']['content'] as String;
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        final quiz = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        return Response.json(
          body: {
            'success': true,
            'quiz': quiz,
          },
        );
      } else {
        throw Exception('Failed to parse quiz from response');
      }
    } else {
      throw Exception(
          'OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
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
