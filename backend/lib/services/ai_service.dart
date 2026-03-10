import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AIService {
  final String openaiApiKey;
  AIService({required this.openaiApiKey});

  Future<Map<String, dynamic>> generateQuiz({
    required String topic,
    required int numQuestions,
    required String difficulty,
    String? subjectContext,
    String? videoUrl,
  }) async {
    const baseUrl = 'https://api.openai.com/v1/chat/completions';
    final prompt =
        _buildPrompt(topic, numQuestions, difficulty, subjectContext, videoUrl);
    final response = await http.post(
      Uri.parse(baseUrl),
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
                'You are a quiz generator. Always respond with valid JSON only, no markdown.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
        'max_tokens': 2048,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      final jsonStr = _extractJson(text);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } else {
      throw Exception(
          'OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }

  String _buildPrompt(String topic, int numQuestions, String difficulty,
      String? subjectContext, String? videoUrl) {
    final difficultyVi = {
      'easy': 'dễ',
      'medium': 'trung bình',
      'hard': 'khó',
    };
    String videoContext = '';
    if (videoUrl != null && videoUrl.isNotEmpty) {
      videoContext = '''
Đây là quiz dựa trên nội dung video bài học từ URL: $videoUrl
Hãy tạo câu hỏi liên quan đến chủ đề "$topic" phù hợp với nội dung có thể có trong video này.
''';
    }
    return '''
Tạo một bài quiz trắc nghiệm về chủ đề "$topic" với $numQuestions câu hỏi ở mức độ ${difficultyVi[difficulty] ?? difficulty}.
${subjectContext != null ? 'Ngữ cảnh môn học: $subjectContext' : ''}
$videoContext
Trả về KẾT QUẢ DẠNG JSON với format sau (KHÔNG có markdown, CHỈ JSON thuần):
{
  "topic": "$topic",
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
- Câu hỏi phải chính xác và phù hợp với độ khó
- CHỈ TRẢ VỀ JSON, KHÔNG CÓ TEXT KHÁC
''';
  }

  String _extractJson(String text) {
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(0)!;
    }
    return text;
  }

  Future<Map<String, dynamic>> analyzeContentStructure({
    required String content,
    required String fileName,
    required String fileType,
  }) async {
    const baseUrl = 'https://api.openai.com/v1/chat/completions';
    final prompt = '''
Bạn là một chuyên gia thiết kế khóa học. Phân tích nội dung sau và đề xuất cách chia thành các chương (modules) và bài học (lessons).
Tên file: $fileName
Loại file: $fileType
Nội dung:
$content
Hãy phân tích và trả về cấu trúc khóa học gợi ý theo định dạng JSON sau:
{
  "suggestedModules": [
    {
      "title": "Tên chương",
      "description": "Mô tả ngắn về chương này",
      "lessons": [
        {
          "title": "Tên bài học",
          "description": "Mô tả ngắn",
          "estimatedDuration": 10
        }
      ]
    }
  ],
  "totalEstimatedDuration": 60,
  "summary": "Tóm tắt ngắn về nội dung"
}
Lưu ý:
- Chia hợp lý dựa trên nội dung thực tế
- Mỗi chương nên có 2-5 bài học
- estimatedDuration tính bằng phút
- CHỈ TRẢ VỀ JSON, KHÔNG CÓ TEXT KHÁC
''';
    final response = await http.post(
      Uri.parse(baseUrl),
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
                'You are a course structure analyzer. Always respond with valid JSON only, no markdown.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
        'max_tokens': 4096,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      final jsonStr = _extractJson(text);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } else {
      throw Exception(
          'OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> analyzeMultipleFiles({
    required List<Map<String, String>> files,
  }) async {
    const baseUrl = 'https://api.openai.com/v1/chat/completions';
    final fileList =
        files.map((f) => '- ${f['fileName']} (${f['fileType']})').join('\n');
    final prompt = '''
Bạn có danh sách các file sau:
$fileList
Hãy gợi ý cách gom nhóm các file này thành các chương (modules) và bài học (lessons) hợp lý.
Trả về JSON:
{
  "suggestedModules": [
    {
      "title": "Tên chương",
      "lessons": [
        {"fileName": "tên_file.pdf", "suggestedTitle": "Tên bài học gợi ý"}
      ]
    }
  ]
}
CHỈ TRẢ VỀ JSON.
''';
    final response = await http.post(
      Uri.parse(baseUrl),
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
                'You are a course organizer. Respond with valid JSON only.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
        'max_tokens': 2048,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      final jsonStr = _extractJson(text);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } else {
      throw Exception(
          'OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> generateQuizFromContext({
    required String context,
    required String moduleTitle,
    int numQuestions = 5,
  }) async {
    const baseUrl = 'https://api.openai.com/v1/chat/completions';
    final prompt = '''
Bạn là chuyên gia giáo dục và đánh giá năng lực.
Nhiệm vụ: Tạo bài kiểm tra trắc nghiệm cho chương "$moduleTitle" dựa trên nội dung được cung cấp bên dưới.
Yêu cầu dữ liệu ("Source of Truth"):
- CHỈ sử dụng thông tin có trong nội dung cung cấp.
- KHÔNG tạo câu hỏi chung chung hoặc bề mặt.
- Tập trung vào các khái niệm then chốt, case study, và các lỗi thường gặp được đề cập.
Nội dung bài học:
"""
$context
"""
Hãy tạo $numQuestions câu hỏi trắc nghiệm.
Mỗi câu hỏi cần có:
1. Nội dung sâu sắc, kiểm tra khả năng hiểu và vận dụng.
2. 4 đáp án lựa chọn.
3. Giải thích chi tiết (Feedback) tại sao đáp án đó đúng, trích dẫn ý từ nội dung.
Trả về JSON format:
{
  "questions": [
    {
      "question": "Nội dung câu hỏi...",
      "options": ["A", "B", "C", "D"],
      "correctIndex": 0,
      "explanation": "Giải thích chi tiết..."
    }
  ]
}
CHỈ TRẢ VỀ JSON.
''';
    final response = await http.post(
      Uri.parse(baseUrl),
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
                'You are an advanced quiz generator. Always respond with valid JSON only.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.5,
        'max_tokens': 4096,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      final jsonStr = _extractJson(text);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } else {
      throw Exception(
          'OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> generateNudgeMessage({
    required String studentName,
    required String courseName,
    required int daysInactive,
    required int progressPercent,
    String? nextLessonTitle,
    String? nextLessonDeepLink,
  }) async {
    const baseUrl = 'https://api.openai.com/v1/chat/completions';
    final prompt = '''
Bạn là trợ lý học tập AI thân thiện. Hãy viết một tin nhắn ngắn (dưới 50 từ) để nhắc nhở học viên quay lại học.
Thông tin học viên:
- Tên: $studentName
- Khóa học: $courseName
- Số ngày vắng mặt: $daysInactive ngày
- Tiến độ: $progressPercent%
- Bài học tiếp theo: ${nextLessonTitle ?? "Chưa xác định"}
Yêu cầu:
1. Giọng văn: Thân thiện, khích lệ, không trách móc.
2. Nếu vắng < 5 ngày: Nhấn mạnh vào việc hoàn thành mục tiêu (tiến độ đang dở dang).
3. Nếu vắng >= 5 ngày: Nhấn mạnh vào nội dung thú vị đang chờ đợi hoặc cộng đồng lớp học.
4. Cuối tin nhắn, hãy chèn link bài học này để họ bấm vào học ngay: ${nextLessonDeepLink ?? ""}
   (Format link: [Tiếp tục học ngay]($nextLessonDeepLink))
Ví dụ output mong muốn:
"Chào Nam 👋, bạn đã đi được 80% chặng đường khóa Flutter rồi! Đừng để kiến thức nguội lạnh nhé. Bài học 'State Management' đang chờ cậu đó. 👉 [Tiếp tục học ngay](link)"
''';
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openaiApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful learning assistant.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
        'max_tokens': 150,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception(
          'OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> generateEngagementReport({
    required String courseName,
    required List<Map<String, dynamic>> moduleStats,
    required int totalStudents,
  }) async {
    const baseUrl = 'https://api.openai.com/v1/chat/completions';
    final statsJson = jsonEncode(moduleStats);
    final prompt = '''
Bạn là một Data Scientist & Chuyên gia Sư phạm. Hãy phân tích dữ liệu khóa học "$courseName" ($totalStudents học viên) dưới đây và tìm ra nguyên nhân học viên bỏ học.
Dữ liệu từng chương (Module Data):
$statsJson
Yêu cầu phân tích:
1. Xác định "Top Bottleneck" (Điểm nghẽn lớn nhất): Chương nào có tỷ lệ hoàn thành tụt giảm mạnh nhất so với chương trước? Hoặc điểm Quiz thấp nhất?
2. Tìm mối tương quan: Có phải điểm Quiz thấp dẫn đến việc bỏ học ở chương sau không?
3. Đưa ra 03 nguyên nhân chính khiến sinh viên bỏ cuộc.
4. Đề xuất 03 giải pháp sư phạm cụ thể để cải thiện.
Trả về kết quả dạng JSON (KHÔNG Markdown):
{
  "summary": "Tóm tắt ngắn gọn về tình hình (ví dụ: Tỷ lệ rơi rớt tập trung ở Module 3 do kiến thức quá khó...)",
  "top_bottleneck": {
    "moduleName": "Tên chương",
    "dropRate": 0.45,
    "avgScore": 4.5
  },
  "causes": ["Nguyên nhân 1", "Nguyên nhân 2", "Nguyên nhân 3"],
  "recommendations": ["Giải pháp 1", "Giải pháp 2", "Giải pháp 3"]
}
''';
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openaiApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an expert Educational Data Scientist. Always respond with valid JSON.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.5,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      final jsonStr = _extractJson(text);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } else {
      throw Exception(
          'OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> chatWithContext({
    required String lessonTitle,
    required String textContent,
    required List<Map<String, String>> history,
    required String question,
  }) async {
    const baseUrl = 'https://api.openai.com/v1/chat/completions';

    final hasContent = textContent.trim().isNotEmpty;

    final systemPrompt = hasContent
        ? '''
Bạn là trợ lý học tập AI thông minh. Nhiệm vụ: trả lời câu hỏi của sinh viên DỰA TRÊN nội dung bài học được cung cấp bên dưới.

Bài học: "$lessonTitle"
Nội dung bài học:
"""
$textContent
"""

Quy tắc:
1. LUÔN trả lời bằng tiếng Việt.
2. Ưu tiên trả lời dựa trên nội dung bài học. Nếu câu hỏi liên quan đến chủ đề bài học nhưng không có trong nội dung, hãy dùng kiến thức chuyên môn để trả lời và ghi chú rằng đây là kiến thức bổ sung.
3. Giải thích rõ ràng, dễ hiểu, có ví dụ khi cần.
4. Dùng markdown formatting (bold, bullet list, code block) để câu trả lời dễ đọc.
5. Ngắn gọn nhưng đầy đủ thông tin.
'''
        : '''
Bạn là trợ lý học tập AI thông minh. Nhiệm vụ: trả lời câu hỏi của sinh viên về bài học "$lessonTitle".

Lưu ý: Nội dung chi tiết của bài học (transcript/văn bản) chưa có sẵn. Hãy sử dụng kiến thức chuyên môn của bạn về chủ đề "$lessonTitle" và các chủ đề liên quan để trả lời.

Quy tắc:
1. LUÔN trả lời bằng tiếng Việt.
2. Trả lời mọi câu hỏi liên quan đến chủ đề bài học và các chủ đề liên quan trong khóa học (ví dụ: nếu bài học về Java fullstack thì các câu hỏi về Spring Boot, React, HTML, CSS, database, API... đều hợp lệ).
3. Giải thích rõ ràng, dễ hiểu, có ví dụ khi cần.
4. Dùng markdown formatting (bold, bullet list, code block) để câu trả lời dễ đọc.
5. Ngắn gọn nhưng đầy đủ thông tin.
6. Chỉ từ chối các câu hỏi hoàn toàn không liên quan đến học tập.
''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': question},
    ];

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openaiApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception(
          'OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> generateVerifyQuestion({
    required String lessonTitle,
    required int currentMinute,
    required int totalMinutes,
    String? textContent,
  }) async {
    const baseUrl = 'https://api.openai.com/v1/chat/completions';

    final fromMinute = (currentMinute - 10).clamp(0, totalMinutes);

    String contentContext = '';
    if (textContent != null && textContent.trim().isNotEmpty) {
      final words = textContent.split(RegExp(r'\s+'));
      final totalWords = words.length;
      if (totalMinutes > 0 && totalWords > 20) {
        final wordsPerMinute = totalWords / totalMinutes;
        final startWord =
            (fromMinute * wordsPerMinute).round().clamp(0, totalWords);
        final endWord =
            (currentMinute * wordsPerMinute).round().clamp(0, totalWords);
        if (endWord > startWord) {
          contentContext = words.sublist(startWord, endWord).join(' ');
        }
      }
      if (contentContext.isEmpty) contentContext = textContent;
    }

    final hasContent = contentContext.isNotEmpty;

    final prompt = hasContent
        ? '''
Bạn là hệ thống xác minh sinh viên đang xem video bài học.
Bài học: "$lessonTitle"
Nội dung phút $fromMinute - $currentMinute (tổng $totalMinutes phút):
"""
$contentContext
"""
Tạo 1 câu hỏi trắc nghiệm đơn giản để xác minh sinh viên vừa xem đoạn này.
Câu hỏi phải dễ trả lời nếu đã xem, nhưng khó đoán nếu không xem.
'''
        : '''
Bạn là hệ thống xác minh sinh viên đang xem video bài học.
Bài học: "$lessonTitle"
Sinh viên đang xem tại phút $currentMinute / $totalMinutes.
Đoạn vừa xem: phút $fromMinute đến phút $currentMinute.
Tạo 1 câu hỏi trắc nghiệm về nội dung có thể được dạy trong khoảng thời gian này của bài "$lessonTitle".
Câu hỏi nên ở mức cơ bản, kiểm tra kiến thức nền tảng về chủ đề.
''';

    final fullPrompt = '''
$prompt
Trả về JSON (CHỈ JSON, KHÔNG text khác):
{
  "question": "Nội dung câu hỏi bằng tiếng Việt?",
  "options": ["Đáp án A", "Đáp án B", "Đáp án C", "Đáp án D"],
  "correctIndex": 0
}
Yêu cầu:
- Câu hỏi bằng tiếng Việt
- 4 đáp án
- correctIndex là 0-3
''';

    final response = await http.post(
      Uri.parse(baseUrl),
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
                'You are a student verification system. Always respond with valid JSON only, no markdown.'
          },
          {'role': 'user', 'content': fullPrompt}
        ],
        'temperature': 0.7,
        'max_tokens': 512,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      final jsonStr = _extractJson(text);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } else {
      throw Exception(
          'OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> summarizeLesson({
    required String lessonTitle,
    required String textContent,
  }) async {
    const baseUrl = 'https://api.openai.com/v1/chat/completions';

    final prompt = '''
Hãy tóm tắt nội dung bài học "$lessonTitle" bên dưới.

Nội dung bài học:
"""
$textContent
"""

Trả về JSON theo format sau (CHỈ JSON, KHÔNG text khác):
{
  "summary": "Đoạn tóm tắt ngắn gọn 3-5 câu về nội dung chính của bài học",
  "keyPoints": [
    "Điểm chính 1",
    "Điểm chính 2",
    "Điểm chính 3"
  ],
  "keywords": ["từ khóa 1", "từ khóa 2", "từ khóa 3"]
}

Yêu cầu:
- Tóm tắt bằng tiếng Việt
- keyPoints: 3-7 điểm chính quan trọng nhất
- keywords: 3-8 từ khóa chủ đề
- Ngắn gọn, súc tích, dễ hiểu
''';

    final response = await http.post(
      Uri.parse(baseUrl),
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
                'You are a lecture summarizer. Always respond with valid JSON only, no markdown.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.5,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      final jsonStr = _extractJson(text);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } else {
      throw Exception(
          'OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> chatWithAssistant({
    required List<Map<String, String>> history,
    required String question,
  }) async {
    const baseUrl = 'https://api.openai.com/v1/chat/completions';

    const systemPrompt = '''
Bạn là một Trợ lý Học thuật Cao cấp chuyên hỗ trợ sinh viên.

Nhiệm vụ:
- Với câu hỏi cơ bản: Trả lời ngắn gọn, súc tích, dễ hiểu.
- Với câu hỏi nâng cao/chuyên sâu: Sử dụng tư duy logic đa bước (Chain of Thought), giải thích cặn kẽ lý thuyết và đưa ra ví dụ thực tiễn.

Kiểm soát phạm vi:
- Chỉ trả lời các câu hỏi liên quan đến kiến thức học thuật, kỹ năng sinh viên và định hướng nghề nghiệp.
- Từ chối khéo léo các câu hỏi ngoài lề (đời tư, giải trí không lành mạnh, chính trị, tán gẫu vô bổ).

Phản hồi: Luôn giữ thái độ chuyên nghiệp, khích lệ tinh thần học tập và dùng ngôn ngữ học thuật chuẩn mực.
Luôn trả lời bằng tiếng Việt.

Câu lệnh từ chối mẫu: "Rất tiếc, tôi được thiết kế để hỗ trợ bạn trong các vấn đề học tập và phát triển kỹ năng. Hãy đặt câu hỏi liên quan đến bài học để tôi có thể giúp bạn tốt nhất nhé!"
''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': question},
    ];

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openaiApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 2048,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception(
          'OpenAI API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> speechToText(File audioFile) async {
    const baseUrl = 'https://api.openai.com/v1/audio/transcriptions';

    final request = http.MultipartRequest('POST', Uri.parse(baseUrl));
    request.headers['Authorization'] = 'Bearer $openaiApiKey';
    request.fields['model'] = 'whisper-1';
    request.fields['language'] = 'vi';
    request.files.add(
      await http.MultipartFile.fromPath('file', audioFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['text'] as String;
    } else {
      throw Exception(
          'Whisper API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
