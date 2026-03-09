import '../../domain/entities/quiz_statistics_entity.dart';

class QuizStatisticsModel extends QuizStatisticsEntity {
  const QuizStatisticsModel({
    required super.id,
    required super.topic,
    required super.totalAttempts,
    required super.totalCorrect,
    required super.totalQuestions,
    required super.averageScore,
    required super.skillLevel,
    super.lastAttemptAt,
  });

  factory QuizStatisticsModel.fromJson(Map<String, dynamic> json) {
    return QuizStatisticsModel(
      id: json['id'] as int,
      topic: json['topic'] as String,
      totalAttempts: json['totalAttempts'] as int,
      totalCorrect: json['totalCorrect'] as int,
      totalQuestions: json['totalQuestions'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      skillLevel: (json['skillLevel'] as num).toDouble(),
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'topic': topic,
    'totalAttempts': totalAttempts,
    'totalCorrect': totalCorrect,
    'totalQuestions': totalQuestions,
    'averageScore': averageScore,
    'skillLevel': skillLevel,
    'lastAttemptAt': lastAttemptAt?.toIso8601String(),
  };
}

class QuizStatisticsSummaryModel extends QuizStatisticsSummaryEntity {
  const QuizStatisticsSummaryModel({
    required super.totalTopics,
    required super.totalAttempts,
    required super.overallAverageScore,
    required super.weakTopics,
    required super.strongTopics,
  });

  factory QuizStatisticsSummaryModel.fromJson(Map<String, dynamic> json) {
    return QuizStatisticsSummaryModel(
      totalTopics: json['totalTopics'] as int,
      totalAttempts: json['totalAttempts'] as int,
      overallAverageScore: (json['overallAverageScore'] as num).toDouble(),
      weakTopics: List<String>.from(json['weakTopics'] as List),
      strongTopics: List<String>.from(json['strongTopics'] as List),
    );
  }
}

class QuizStatisticsResponseModel extends QuizStatisticsResponseEntity {
  const QuizStatisticsResponseModel({
    required super.statistics,
    required super.summary,
  });

  factory QuizStatisticsResponseModel.fromJson(Map<String, dynamic> json) {
    final statsList = (json['statistics'] as List)
        .map((s) => QuizStatisticsModel.fromJson(s as Map<String, dynamic>))
        .toList();

    return QuizStatisticsResponseModel(
      statistics: statsList,
      summary: QuizStatisticsSummaryModel.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
    );
  }
}
