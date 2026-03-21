import 'package:equatable/equatable.dart';

abstract class AiAssistantEvent extends Equatable {
  const AiAssistantEvent();

  @override
  List<Object?> get props => [];
}

class AskAiQuestion extends AiAssistantEvent {
  final String lessonTitle;
  final String textContent;
  final String question;
  final int? userId;
  final int? lessonId;
  final String? persona;

  const AskAiQuestion({
    required this.lessonTitle,
    required this.textContent,
    required this.question,
    this.userId,
    this.lessonId,
    this.persona,
  });

  @override
  List<Object?> get props => [lessonTitle, textContent, question, userId, lessonId, persona];
}

class SummarizeLesson extends AiAssistantEvent {
  final String lessonTitle;
  final String textContent;

  const SummarizeLesson({required this.lessonTitle, required this.textContent});

  @override
  List<Object?> get props => [lessonTitle, textContent];
}

class ClearChat extends AiAssistantEvent {
  final int? userId;
  final int? lessonId;

  const ClearChat({this.userId, this.lessonId});

  @override
  List<Object?> get props => [userId, lessonId];
}

class LoadChatHistory extends AiAssistantEvent {
  final int userId;
  final int? lessonId;

  const LoadChatHistory({required this.userId, this.lessonId});

  @override
  List<Object?> get props => [userId, lessonId];
}

class GenerateConceptMap extends AiAssistantEvent {
  final String lessonTitle;
  final String textContent;

  const GenerateConceptMap({required this.lessonTitle, required this.textContent});

  @override
  List<Object?> get props => [lessonTitle, textContent];
}
