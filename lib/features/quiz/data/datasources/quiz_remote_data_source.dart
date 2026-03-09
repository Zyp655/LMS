import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_constants.dart';
import '../models/quiz_model.dart';
import '../models/quiz_statistics_model.dart';

abstract class QuizRemoteDataSource {
  Future<QuizModel> generateQuiz({
    required String topic,
    required int numQuestions,
    required String difficulty,
    String? subjectContext,
    List<String>? questionTypes,
    String? videoUrl,
  });

  Future<QuizModel> generateQuizFromImage({
    required Uint8List imageBytes,
    required int numQuestions,
    required String difficulty,
  });

  Future<QuizModel> generateAdaptiveQuiz({
    required int userId,
    required String topic,
    required int numQuestions,
  });

  Future<int> saveQuiz({
    required int userId,
    required Map<String, dynamic> quiz,
    bool isPublic = false,
  });

  Future<QuizModel> getQuizById(int quizId);

  Future<List<QuizModel>> getMyQuizzes(int userId);

  Future<Map<String, dynamic>> submitQuiz({
    required int userId,
    required int quizId,
    required List<dynamic> answers,
    required int timeSpentSeconds,
  });

  Future<QuizStatisticsResponseModel> getStatistics(
    int userId, {
    String? topic,
  });
  Future<List<Map<String, dynamic>>> getLeaderboard({
    required int classId,
    required String period,
  });
}

class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final http.Client client;

  QuizRemoteDataSourceImpl({required this.client});
  @override
  Future<List<Map<String, dynamic>>> getLeaderboard({
    required int classId,
    required String period,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/quiz/leaderboard?classId=$classId&period=$period',
    );

    final response = await client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['leaderboard'] != null) {
        return (data['leaderboard'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Không thể tải bảng xếp hạng. Vui lòng thử lại sau.');
    }
  }

  @override
  Future<QuizModel> generateQuiz({
    required String topic,
    required int numQuestions,
    required String difficulty,
    String? subjectContext,
    List<String>? questionTypes,
    String? videoUrl,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/quiz/generate');

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'topic': topic,
        'numQuestions': numQuestions,
        'difficulty': difficulty,
        if (subjectContext != null) 'subjectContext': subjectContext,
        if (questionTypes != null) 'questionTypes': questionTypes,
        if (videoUrl != null) 'videoUrl': videoUrl,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['quiz'] != null) {
        return QuizModel.fromJson(data['quiz'] as Map<String, dynamic>);
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Không thể tạo quiz. Vui lòng thử lại sau.');
    }
  }

  @override
  Future<QuizModel> generateQuizFromImage({
    required Uint8List imageBytes,
    required int numQuestions,
    required String difficulty,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/quiz/generate-from-image');
    final imageBase64 = base64Encode(imageBytes);

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'imageBase64': imageBase64,
        'numQuestions': numQuestions,
        'difficulty': difficulty,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['quiz'] != null) {
        return QuizModel.fromJson(data['quiz'] as Map<String, dynamic>);
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Không thể tạo quiz từ ảnh. Vui lòng thử lại sau.');
    }
  }

  @override
  Future<QuizModel> generateAdaptiveQuiz({
    required int userId,
    required String topic,
    required int numQuestions,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/quiz/adaptive');

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'topic': topic,
        'numQuestions': numQuestions,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['quiz'] != null) {
        return QuizModel.fromJson(data['quiz'] as Map<String, dynamic>);
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Không thể tạo quiz thích ứng. Vui lòng thử lại sau.');
    }
  }

  @override
  Future<int> saveQuiz({
    required int userId,
    required Map<String, dynamic> quiz,
    bool isPublic = false,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/quiz/save');

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'quiz': quiz, 'isPublic': isPublic}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return data['quizId'] as int;
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Không thể lưu quiz. Vui lòng thử lại sau.');
    }
  }

  @override
  Future<QuizModel> getQuizById(int quizId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/quiz/details/$quizId');

    final response = await client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['quiz'] != null) {
        return QuizModel.fromJson(data['quiz'] as Map<String, dynamic>);
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Không thể tải quiz. Vui lòng thử lại sau.');
    }
  }

  @override
  Future<List<QuizModel>> getMyQuizzes(int userId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/quiz/my-quizzes?userId=$userId',
    );

    final response = await client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['quizzes'] != null) {
        final quizzes = data['quizzes'] as List;
        return quizzes
            .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Không thể tải danh sách quiz. Vui lòng thử lại sau.');
    }
  }

  @override
  Future<Map<String, dynamic>> submitQuiz({
    required int userId,
    required int quizId,
    required List<dynamic> answers,
    required int timeSpentSeconds,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/quiz/submit');

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'quizId': quizId,
        'answers': answers,
        'timeSpentSeconds': timeSpentSeconds,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Không thể nộp bài. Vui lòng thử lại sau.');
    }
  }

  @override
  Future<QuizStatisticsResponseModel> getStatistics(
    int userId, {
    String? topic,
  }) async {
    var url = '${ApiConstants.baseUrl}/quiz/statistics?userId=$userId';
    if (topic != null) {
      url += '&topic=$topic';
    }

    final response = await client.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return QuizStatisticsResponseModel.fromJson(data);
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Không thể tải thống kê. Vui lòng thử lại sau.');
    }
  }
}
