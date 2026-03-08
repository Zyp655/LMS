import '../../../../core/api/api_client.dart';
import '../models/teacher_application_model.dart';

class TeacherApplicationRemoteDataSource {
  final ApiClient apiClient;

  TeacherApplicationRemoteDataSource({required this.apiClient});

  Future<Map<String, dynamic>> submitApplication(
    TeacherApplicationEntity application,
  ) async {
    final result = await apiClient.post(
      '/teacher-applications',
      application.toJson(),
    );
    return result as Map<String, dynamic>;
  }

  Future<TeacherApplicationEntity> getMyApplication() async {
    final result = await apiClient.get('/teacher-applications/my');
    return TeacherApplicationEntity.fromJson(result as Map<String, dynamic>);
  }

  Future<List<TeacherApplicationEntity>> getAllApplications({
    int? status,
  }) async {
    final path = status != null
        ? '/teacher-applications?status=$status'
        : '/teacher-applications';
    final result = await apiClient.get(path);
    final list = result as List;
    return list
        .map(
          (e) => TeacherApplicationEntity.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<Map<String, dynamic>> reviewApplication({
    required int applicationId,
    required int status,
    String? adminNote,
  }) async {
    final result = await apiClient.put('/teacher-applications/$applicationId', {
      'status': status,
      if (adminNote != null) 'adminNote': adminNote,
    });
    return result as Map<String, dynamic>;
  }
}
