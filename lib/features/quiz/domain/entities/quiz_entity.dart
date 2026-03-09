import 'package:equatable/equatable.dart';

enum QuestionType { multipleChoice, trueFalse, fillBlank, matching }

extension QuestionTypeExtension on QuestionType {
  String get value {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.fillBlank:
        return 'fill_blank';
      case QuestionType.matching:
        return 'matching';
    }
  }

  static QuestionType fromString(String value) {
    switch (value) {
      case 'true_false':
        return QuestionType.trueFalse;
      case 'fill_blank':
        return QuestionType.fillBlank;
      case 'matching':
        return QuestionType.matching;
      default:
        return QuestionType.multipleChoice;
    }
  }
}

class QuestionEntity extends Equatable {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final QuestionType questionType;
  final String? correctAnswer;

  const QuestionEntity({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.questionType = QuestionType.multipleChoice,
    this.correctAnswer,
  });

  @override
  List<Object?> get props => [
    question,
    options,
    correctIndex,
    explanation,
    questionType,
    correctAnswer,
  ];
}

class QuizEntity extends Equatable {
  final int? id;
  final int? createdBy;
  final String topic;
  final String difficulty;
  final List<QuestionEntity> questions;
  final DateTime? createdAt;
  final bool isPublic;
  final double? adaptiveLevel;

  const QuizEntity({
    this.id,
    this.createdBy,
    required this.topic,
    required this.difficulty,
    required this.questions,
    this.createdAt,
    this.isPublic = false,
    this.adaptiveLevel,
  });

  int get totalQuestions => questions.length;

  Map<String, dynamic> toJson() => {
    'topic': topic,
    'difficulty': difficulty,
    'questions': questions
        .map(
          (q) => {
            'question': q.question,
            'options': q.options,
            'correctIndex': q.correctIndex,
            'explanation': q.explanation,
            'questionType': q.questionType.value,
            'correctAnswer': q.correctAnswer,
          },
        )
        .toList(),
  };

  @override
  List<Object?> get props => [
    id,
    createdBy,
    topic,
    difficulty,
    questions,
    createdAt,
    isPublic,
    adaptiveLevel,
  ];
}

class QuizResultEntity extends Equatable {
  final QuizEntity quiz;
  final List<dynamic> userAnswers;
  final int timeSpentSeconds;

  const QuizResultEntity({
    required this.quiz,
    required this.userAnswers,
    this.timeSpentSeconds = 0,
  });

  int get correctCount {
    int count = 0;
    for (int i = 0; i < quiz.questions.length; i++) {
      final q = quiz.questions[i];
      final answer = i < userAnswers.length ? userAnswers[i] : null;

      if (q.questionType == QuestionType.fillBlank) {
        if (q.correctAnswer != null &&
            answer != null &&
            answer.toString().toLowerCase().trim() ==
                q.correctAnswer!.toLowerCase().trim()) {
          count++;
        }
      } else {
        if (answer == q.correctIndex) {
          count++;
        }
      }
    }
    return count;
  }

  double get scorePercentage =>
      quiz.totalQuestions > 0 ? (correctCount / quiz.totalQuestions) * 100 : 0;

  double get score =>
      quiz.totalQuestions > 0 ? (correctCount / quiz.totalQuestions) * 10 : 0;

  @override
  List<Object?> get props => [quiz, userAnswers, timeSpentSeconds];
}

class QuizStatisticsEntity extends Equatable {
  final String topic;
  final int totalAttempts;
  final int totalCorrect;
  final int totalQuestions;
  final double averageScore;
  final double skillLevel;
  final DateTime? lastAttemptAt;

  const QuizStatisticsEntity({
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
    topic,
    totalAttempts,
    totalCorrect,
    totalQuestions,
    averageScore,
    skillLevel,
    lastAttemptAt,
  ];
}
