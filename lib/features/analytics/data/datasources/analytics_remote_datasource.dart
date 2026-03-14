import '../../../../core/api/api_client.dart';
import '../../domain/entities/heatmap_entry.dart';
import '../../domain/entities/velocity_data.dart';
import '../../domain/entities/benchmark_data.dart';
import '../../domain/entities/analytics_summary.dart';

class AnalyticsRemoteDataSource {
  final ApiClient apiClient;

  AnalyticsRemoteDataSource({required this.apiClient});

  Future<Map<String, dynamic>> getHeatmap(int userId, int months) async {
    final response = await apiClient.get(
      '/analytics/heatmap?userId=$userId&months=$months',
    );
    return response;
  }

  Future<Map<String, dynamic>> getVelocity(int userId, int courseId) async {
    final response = await apiClient.get(
      '/analytics/velocity?userId=$userId&courseId=$courseId',
    );
    return response;
  }

  Future<Map<String, dynamic>> getBenchmark(int userId, int courseId) async {
    final response = await apiClient.get(
      '/analytics/benchmark?userId=$userId&courseId=$courseId',
    );
    return response;
  }

  Future<Map<String, dynamic>> getSummary(int userId) async {
    final response = await apiClient.get('/analytics/summary?userId=$userId');
    return response;
  }

  Future<void> trackActivity({
    required int userId,
    required String activityType,
    int? courseId,
    int? lessonId,
    int durationMinutes = 0,
    String? metadata,
  }) async {
    await apiClient.post('/analytics/track', {
      'userId': userId,
      'activityType': activityType,
      if (courseId != null) 'courseId': courseId,
      if (lessonId != null) 'lessonId': lessonId,
      'durationMinutes': durationMinutes,
      if (metadata != null) 'metadata': metadata,
    });
  }

  List<HeatmapEntry> parseHeatmap(Map<String, dynamic> json) {
    final list = json['heatmap'] as List<dynamic>? ?? [];
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return HeatmapEntry(
        date: DateTime.parse(map['date'] as String),
        activityCount: map['activityCount'] as int? ?? 0,
        totalMinutes: map['totalMinutes'] as int? ?? 0,
      );
    }).toList();
  }

  VelocityData parseVelocity(Map<String, dynamic> json) {
    final dailyList = json['dailyProgress'] as List<dynamic>? ?? [];
    return VelocityData(
      totalLessons: json['totalLessons'] as int? ?? 0,
      completedLessons: json['completedLessons'] as int? ?? 0,
      remainingLessons: json['remainingLessons'] as int? ?? 0,
      dailyVelocity: (json['dailyVelocity'] as num?)?.toDouble(),
      predictedCompletionDate: json['predictedCompletionDate'] != null
          ? DateTime.tryParse(json['predictedCompletionDate'] as String)
          : null,
      trend: json['trend'] as String? ?? 'insufficient',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      dailyProgress: dailyList
          .map(
            (item) => DailyProgress(
              date: DateTime.parse(item['date'] as String),
              lessonsCompleted: item['lessonsCompleted'] as int? ?? 0,
            ),
          )
          .toList(),
    );
  }

  BenchmarkData parseBenchmark(Map<String, dynamic> json) {
    return BenchmarkData(
      myProgress: (json['myProgress'] as num?)?.toDouble() ?? 0.0,
      avgProgress: (json['avgProgress'] as num?)?.toDouble() ?? 0.0,
      topProgress: (json['topProgress'] as num?)?.toDouble() ?? 0.0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      percentileRank: json['percentileRank'] as int? ?? 0,
      myStudyMinutes: json['myStudyMinutes'] as int? ?? 0,
      avgStudyMinutes: json['avgStudyMinutes'] as int? ?? 0,
    );
  }

  AnalyticsSummary parseSummary(Map<String, dynamic> json) {
    return AnalyticsSummary(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      weekStudyMinutes: json['weekStudyMinutes'] as int? ?? 0,
      todayStudyMinutes: json['todayStudyMinutes'] as int? ?? 0,
      weekCompletedLessons: json['weekCompletedLessons'] as int? ?? 0,
      activeCourses: json['activeCourses'] as int? ?? 0,
      overallProgress: (json['overallProgress'] as num?)?.toDouble() ?? 0.0,
      completedLessons: json['completedLessons'] as int? ?? 0,
      todayActivities: json['todayActivities'] as int? ?? 0,
    );
  }
}
