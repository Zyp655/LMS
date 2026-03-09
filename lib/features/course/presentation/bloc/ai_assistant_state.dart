import 'package:equatable/equatable.dart';

class AiChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  const AiChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

abstract class AiAssistantState extends Equatable {
  const AiAssistantState();

  @override
  List<Object?> get props => [];
}

class AiInitial extends AiAssistantState {}

class AiChatLoading extends AiAssistantState {
  final List<AiChatMessage> messages;
  const AiChatLoading(this.messages);

  @override
  List<Object?> get props => [messages];
}

class AiChatLoaded extends AiAssistantState {
  final List<AiChatMessage> messages;
  const AiChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class AiSummaryLoading extends AiAssistantState {}

class AiSummaryLoaded extends AiAssistantState {
  final String summary;
  final List<String> keyPoints;
  final List<String> keywords;

  const AiSummaryLoaded({
    required this.summary,
    required this.keyPoints,
    required this.keywords,
  });

  @override
  List<Object?> get props => [summary, keyPoints, keywords];
}

class AiError extends AiAssistantState {
  final String message;
  final List<AiChatMessage>? previousMessages;

  const AiError(this.message, {this.previousMessages});

  @override
  List<Object?> get props => [message, previousMessages];
}
