import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart';
import 'package:backend/database/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }
  try {
    final db = context.read<AppDatabase>();
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final userId = data['userId'] as int?;
    final topic = data['topic'] as String?;
    final numQuestions = data['numQuestions'] as int? ?? 5;
    if (userId == null || topic == null) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'userId and topic are required'}),
      );
    }
    final stats = await (db.select(db.quizStatistics)
          ..where((t) => t.userId.equals(userId) & t.topic.equals(topic)))
        .getSingleOrNull();
    final skillLevel = stats?.skillLevel ?? 0.5;
    String difficulty;
    String difficultyVi;
    if (skillLevel < 0.35) {
      difficulty = 'easy';
      difficultyVi = 'dễ';
    } else if (skillLevel < 0.65) {
      difficulty = 'medium';
      difficultyVi = 'trung bình';
    } else {
      difficulty = 'hard';
      difficultyVi = 'khó';
    }
    final env = DotEnv(includePlatformEnvironment: true)..load();
    final openaiApiKey = env['OPENAI_API_KEY'];
    if (openaiApiKey == null || openaiApiKey.isEmpty) {
      return Response(
        statusCode: HttpStatus.internalServerError,
        body: jsonEncode({'error': 'OpenAI API key not configured'}),
      );
    }
    final prompt = '''
Tạo một bài quiz trắc nghiệm về chủ đề "$topic" với $numQuestions câu hỏi ở mức độ $difficultyVi.
Skill level của người dùng: ${(skillLevel * 100).toStringAsFixed(0)}%
${skillLevel < 0.4 ? 'Người dùng đang gặp khó khăn, hãy tạo câu hỏi cơ bản và dễ hiểu.' : ''}
${skillLevel >= 0.7 ? 'Người dùng đã thành thạo, hãy tạo câu hỏi thử thách và nâng cao.' : ''}
Trả về KẾT QUẢ DẠNG JSON với format sau (KHÔNG có markdown, CHỈ JSON thuần):
{
  "topic": "$topic",
  "difficulty": "$difficulty",
  "adaptiveLevel": $skillLevel,
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
- Câu hỏi phải phù hợp với skill level của người dùng
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
            'role': 'system',
            'content':
                'You are an adaptive quiz generator. Always respond with valid JSON only, no markdown.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
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
            'userSkillLevel': skillLevel,
            'recommendedDifficulty': difficulty,
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
