import '../../../../core/api/api_client.dart';
import '../models/achievement_model.dart';

abstract class AchievementRemoteDataSource {
  Future<List<AchievementModel>> getAchievements(int userId);
}

class AchievementRemoteDataSourceImpl implements AchievementRemoteDataSource {
  final ApiClient apiClient;

  AchievementRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AchievementModel>> getAchievements(int userId) async {
    final response = await apiClient.get('/users/$userId/achievements');

    final List<dynamic> data = response is List
        ? response
        : (response['achievements'] as List<dynamic>? ?? []);
    return data
        .map((json) => AchievementModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
