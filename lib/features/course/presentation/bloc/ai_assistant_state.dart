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

class ConceptNode {
  final String id;
  final String label;
  final String description;
  final String type;

  const ConceptNode({
    required this.id,
    required this.label,
    required this.description,
    required this.type,
  });
}

class ConceptEdge {
  final String from;
  final String to;
  final String label;

  const ConceptEdge({
    required this.from,
    required this.to,
    required this.label,
  });
}

class AiConceptMapLoading extends AiAssistantState {}

class AiConceptMapLoaded extends AiAssistantState {
  final List<ConceptNode> nodes;
  final List<ConceptEdge> edges;

  const AiConceptMapLoaded({required this.nodes, required this.edges});

  @override
  List<Object?> get props => [nodes, edges];
}
