import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/student_assignment_model.dart';

abstract class StudentRemoteDataSource {
  Future<void> submitAssignment({
    required int assignmentId,
    required int studentId,
    File? file,
    String? link,
    String? text,
  });

  Future<List<StudentAssignmentModel>> getStudentAssignments(int studentId);
}

class StudentRemoteDataSourceImpl implements StudentRemoteDataSource {
  final http.Client client;

  StudentRemoteDataSourceImpl({required this.client});

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<void> submitAssignment({
    required int assignmentId,
    required int studentId,
    File? file,
    String? link,
    String? text,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/student/assignments/$assignmentId/submit',
    );

    var request = http.MultipartRequest('POST', url);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['studentId'] = studentId.toString();

    if (link != null) request.fields['link'] = link;
    if (text != null) request.fields['text'] = text;

    if (file != null) {
      final fileStream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      throw ServerException("Lỗi nộp bài: $respStr");
    }
  }

  @override
  Future<List<StudentAssignmentModel>> getStudentAssignments(
    int studentId,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/student/assignments?userId=$studentId',
    );
    final headers = await _getHeaders();
    final response = await client.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.map((e) => StudentAssignmentModel.fromJson(e)).toList();
    } else {
      throw ServerException(
        "Lỗi tải danh sách bài tập: ${response.statusCode}",
      );
    }
  }
}
