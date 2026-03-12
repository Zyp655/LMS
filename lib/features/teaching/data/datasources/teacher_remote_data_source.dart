import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../schedule/data/models/schedule_model.dart';
import '../../../schedule/domain/enitities/schedule_entity.dart';
import '../../domain/entities/subject_entity.dart';
import '../models/assignment_model.dart';

abstract class TeacherRemoteDataSource {
  Future<List<AssignmentModel>> getAssignments(int teacherId);

  Future<void> createAssignment(AssignmentModel assignment, int teacherId);

  Future<void> updateAssignment(AssignmentModel assignment, int teacherId);

  Future<void> deleteAssignment(int assignmentId, int teacherId);

  Future<void> createClass(
    String className,
    int teacherId,
    String subjectName,
    String room,
    DateTime startTime,
    DateTime endTime,
    DateTime startDate,
    int repeatWeeks,
    int notificationMinutes,
    int credits,
  );

  Future<void> createSubject(
    int teacherId,
    String name,
    int credits,
    String? code,
  );

  Future<List<ScheduleEntity>> getAllSchedules(int teacherId);

  Future<String> regenerateClassCode(
    int teacherId,
    String subjectName,
    bool isRefresh,
  );

  Future<List<SubjectEntity>> getSubjects(int teacherId);

  Future<void> updateScore(
    int scheduleId,
    int? absences,
    double? midtermScore,
    double? finalScore,
    double? examScore,
  );

  Future<void> importSchedules(
    int teacherId,
    List<Map<String, dynamic>> schedules,
  );

  Future<List<Map<String, dynamic>>> getStudentsInClass(int classId);

  Future<List<Map<String, dynamic>>> getSubmissions(int assignmentId);
  Future<void> gradeSubmission({
    required int submissionId,
    required int teacherId,
    required double grade,
    String? feedback,
  });

  Future<void> markAttendance({
    required int classId,
    required DateTime date,
    required int teacherId,
    required List<Map<String, dynamic>> attendances,
  });
  Future<List<Map<String, dynamic>>> getAttendanceRecords({
    required int classId,
    required DateTime date,
  });
  Future<List<Map<String, dynamic>>> getAttendanceStatistics(int classId);

  Future<Map<String, dynamic>> enrollStudentsByIdentifier(
    int classId,
    int teacherId,
    List<String> identifiers,
  );
}

class TeacherRemoteDataSourceImpl implements TeacherRemoteDataSource {
  final http.Client client;

  TeacherRemoteDataSourceImpl({required this.client});

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<SubjectEntity>> getSubjects(int teacherId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/teacher/subjects?teacherId=$teacherId',
    );
    final headers = await _getHeaders();
    final response = await client.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded
          .map(
            (e) => SubjectEntity(
              id: e['id'],
              name: e['name'],
              code: e['code'],
              credits: e['credits'] ?? 3,
            ),
          )
          .toList();
    } else {
      throw ServerException("Lỗi tải danh sách môn: ${response.statusCode}");
    }
  }

  @override
  Future<void> createSubject(
    int teacherId,
    String name,
    int credits,
    String? code,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/teacher/subjects');
    final headers = await _getHeaders();
    final response = await client.post(
      url,
      headers: headers,
      body: jsonEncode({
        'teacherId': teacherId,
        'name': name,
        'credits': credits,
        'code': code,
      }),
    );

    if (response.statusCode != 200) {
      throw ServerException("Lỗi tạo môn: ${response.body}");
    }
  }

  @override
  Future<void> createClass(
    String className,
    int teacherId,
    String subjectName,
    String room,
    DateTime startTime,
    DateTime endTime,
    DateTime startDate,
    int repeatWeeks,
    int notificationMinutes,
    int credits,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/teacher/create_class');
    final headers = await _getHeaders();
    final response = await client.post(
      url,
      headers: headers,
      body: jsonEncode({
        'className': className,
        'teacherId': teacherId,
        'subjectName': subjectName,
        'room': room,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'startDate': startDate.toIso8601String(),
        'repeatWeeks': repeatWeeks,
        'notificationMinutes': notificationMinutes,
        'credits': credits,
      }),
    );

    if (response.statusCode != 200) {
      throw ServerException("Lỗi tạo lớp: ${response.body}");
    }
  }

  @override
  Future<List<ScheduleEntity>> getAllSchedules(int teacherId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/teacher/schedules?userId=$teacherId',
    );
    final headers = await _getHeaders();
    final response = await client.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.map((e) => ScheduleModel.fromJson(e)).toList();
    } else {
      throw ServerException("Lỗi server: ${response.statusCode}");
    }
  }

  @override
  Future<void> updateScore(
    int scheduleId,
    int? absences,
    double? midtermScore,
    double? finalScore,
    double? examScore,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/teacher/update_score');

    final headers = await _getHeaders();
    final response = await client.post(
      url,
      headers: headers,
      body: jsonEncode({
        'schedule_id': scheduleId,
        'absences': absences,
        'midtermScore': midtermScore,
        'finalScore': finalScore,
        'examScore': examScore,
      }),
    );

    if (response.statusCode != 200) {
      throw ServerException("Lỗi cập nhật điểm: ${response.body}");
    }
  }

  @override
  Future<void> importSchedules(
    int teacherId,
    List<Map<String, dynamic>> schedules,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/teacher/import_schedule');

    final headers = await _getHeaders();
    final response = await client.post(
      url,
      headers: headers,
      body: jsonEncode({'teacherId': teacherId, 'schedules': schedules}),
    );

    if (response.statusCode != 200) {
      throw ServerException("Lỗi import: ${response.body}");
    }
  }

  @override
  Future<String> regenerateClassCode(
    int teacherId,
    String subjectName,
    bool isRefresh,
  ) async {
    final headers = await _getHeaders();
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/teacher/regenerate_code'),
      headers: headers,
      body: jsonEncode({
        'teacherId': teacherId,
        'subjectName': subjectName,
        'forceRefresh': isRefresh,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['newCode'];
    } else {
      throw Exception('error: ${response.body}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsInClass(int classId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/teacher/classes/$classId/students',
    );
    final headers = await _getHeaders();
    final response = await client.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.cast<Map<String, dynamic>>();
    } else {
      throw ServerException(
        "Lỗi tải danh sách sinh viên: ${response.statusCode}",
      );
    }
  }

  @override
  Future<List<AssignmentModel>> getAssignments(int teacherId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/teacher/assignments?userId=$teacherId',
    );
    final headers = await _getHeaders();
    final response = await client.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.map((e) => AssignmentModel.fromJson(e)).toList();
    } else {
      throw ServerException(
        "Lỗi tải danh sách bài tập: ${response.statusCode}",
      );
    }
  }

  @override
  Future<void> createAssignment(
    AssignmentModel assignment,
    int teacherId,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/teacher/create_assignment');

    final body = assignment.toJson();
    body['teacherId'] = teacherId;

    final headers = await _getHeaders();
    final response = await client.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw ServerException("Lỗi tạo bài tập: ${response.body}");
    }
  }

  @override
  Future<void> updateAssignment(
    AssignmentModel assignment,
    int teacherId,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/teacher/assignments/${assignment.id}/update',
    );

    final body = assignment.toJson();
    body['teacherId'] = teacherId;

    final headers = await _getHeaders();
    final response = await client.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw ServerException("Lỗi cập nhật bài tập: ${response.body}");
    }
  }

  @override
  Future<void> deleteAssignment(int assignmentId, int teacherId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/teacher/assignments/$assignmentId/delete?teacherId=$teacherId',
    );

    final headers = await _getHeaders();
    final response = await client.delete(url, headers: headers);

    if (response.statusCode != 200) {
      throw ServerException("Lỗi xóa bài tập: ${response.body}");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSubmissions(int assignmentId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/teacher/assignments/$assignmentId/submissions',
    );
    final headers = await _getHeaders();
    final response = await client.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.cast<Map<String, dynamic>>();
    } else {
      throw ServerException(
        "Lỗi tải danh sách bài nộp: ${response.statusCode}",
      );
    }
  }

  @override
  Future<void> gradeSubmission({
    required int submissionId,
    required int teacherId,
    required double grade,
    String? feedback,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/teacher/submissions/$submissionId/grade',
    );

    final headers = await _getHeaders();
    final response = await client.post(
      url,
      headers: headers,
      body: jsonEncode({
        'teacherId': teacherId,
        'grade': grade,
        'feedback': feedback,
      }),
    );

    if (response.statusCode != 200) {
      throw ServerException("Lỗi chấm bài: ${response.body}");
    }
  }

  @override
  Future<void> markAttendance({
    required int classId,
    required DateTime date,
    required int teacherId,
    required List<Map<String, dynamic>> attendances,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/teacher/attendance/mark');

    final headers = await _getHeaders();
    final response = await client.post(
      url,
      headers: headers,
      body: jsonEncode({
        'classId': classId,
        'teacherId': teacherId,
        'date': date.toIso8601String(),
        'attendances': attendances,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException("Lỗi điểm danh: ${response.body}");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAttendanceRecords({
    required int classId,
    required DateTime date,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/teacher/attendance/records?classId=$classId&date=${date.toIso8601String()}',
    );
    final headers = await _getHeaders();
    final response = await client.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.cast<Map<String, dynamic>>();
    } else {
      throw ServerException(
        "Lỗi tải dữ liệu điểm danh: ${response.statusCode}",
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAttendanceStatistics(
    int classId,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/teacher/attendance/statistics?classId=$classId',
    );
    final headers = await _getHeaders();
    final response = await client.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.cast<Map<String, dynamic>>();
    } else {
      throw ServerException(
        "Lỗi tải thống kê điểm danh: ${response.statusCode}",
      );
    }
  }

  @override
  Future<Map<String, dynamic>> enrollStudentsByIdentifier(
    int classId,
    int teacherId,
    List<String> identifiers,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/teacher/classes/$classId/enroll-by-identifier',
    );
    final headers = await _getHeaders();
    final response = await client.post(
      url,
      headers: headers,
      body: jsonEncode({'teacherId': teacherId, 'identifiers': identifiers}),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw ServerException("Lỗi ghi danh: ${response.body}");
    }
  }
}
