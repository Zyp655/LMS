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

  const AskAiQuestion({
    required this.lessonTitle,
    required this.textContent,
    required this.question,
  });

  @override
  List<Object?> get props => [lessonTitle, textContent, question];
}

class SummarizeLesson extends AiAssistantEvent {
  final String lessonTitle;
  final String textContent;

  const SummarizeLesson({required this.lessonTitle, required this.textContent});

  @override
  List<Object?> get props => [lessonTitle, textContent];
}

class ClearChat extends AiAssistantEvent {}
