import 'package:equatable/equatable.dart';

class QuizStatisticsEntity extends Equatable {
  final int id;
  final String topic;
  final int totalAttempts;
  final int totalCorrect;
  final int totalQuestions;
  final double averageScore;
  final double skillLevel;
  final DateTime? lastAttemptAt;

  const QuizStatisticsEntity({
    required this.id,
    required this.topic,
    required this.totalAttempts,
    required this.totalCorrect,
    required this.totalQuestions,
    required this.averageScore,
    required this.skillLevel,
    this.lastAttemptAt,
  });

  @override
  List<Object?> get props => [
    id,
    topic,
    totalAttempts,
    totalCorrect,
    totalQuestions,
    averageScore,
    skillLevel,
    lastAttemptAt,
  ];
}

class QuizStatisticsSummaryEntity extends Equatable {
  final int totalTopics;
  final int totalAttempts;
  final double overallAverageScore;
  final List<String> weakTopics;
  final List<String> strongTopics;

  const QuizStatisticsSummaryEntity({
    required this.totalTopics,
    required this.totalAttempts,
    required this.overallAverageScore,
    required this.weakTopics,
    required this.strongTopics,
  });

  @override
  List<Object?> get props => [
    totalTopics,
    totalAttempts,
    overallAverageScore,
    weakTopics,
    strongTopics,
  ];
}

class QuizStatisticsResponseEntity extends Equatable {
  final List<QuizStatisticsEntity> statistics;
  final QuizStatisticsSummaryEntity summary;

  const QuizStatisticsResponseEntity({
    required this.statistics,
    required this.summary,
  });

  @override
  List<Object?> get props => [statistics, summary];
}
