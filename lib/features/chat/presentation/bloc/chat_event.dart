import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message_entity.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends ChatEvent {
  final int userId;

  const LoadConversations(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadMessages extends ChatEvent {
  final int conversationId;

  const LoadMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendMessage extends ChatEvent {
  final int conversationId;
  final int senderId;
  final String text;
  final String? mediaUrl;
  final String messageType;

  const SendMessage({
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    this.messageType = 'text',
  });

  @override
  List<Object?> get props => [
    conversationId,
    senderId,
    text,
    mediaUrl,
    messageType,
  ];
}

class MarkMessagesRead extends ChatEvent {
  final int conversationId;
  final int readerId;

  const MarkMessagesRead({
    required this.conversationId,
    required this.readerId,
  });

  @override
  List<Object?> get props => [conversationId, readerId];
}

class CreateConversation extends ChatEvent {
  final int user1Id;
  final int user2Id;

  const CreateConversation({required this.user1Id, required this.user2Id});

  @override
  List<Object?> get props => [user1Id, user2Id];
}

class ConnectWebSocket extends ChatEvent {
  final int userId;

  const ConnectWebSocket(this.userId);

  @override
  List<Object?> get props => [userId];
}

class DisconnectWebSocket extends ChatEvent {
  const DisconnectWebSocket();
}

class WebSocketMessageReceived extends ChatEvent {
  final ChatMessageEntity message;

  const WebSocketMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class WebSocketReadReceipt extends ChatEvent {
  final int conversationId;

  const WebSocketReadReceipt(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendTypingEvent extends ChatEvent {
  final int conversationId;

  const SendTypingEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class WebSocketTypingReceived extends ChatEvent {
  final int conversationId;
  final String userName;

  const WebSocketTypingReceived(this.conversationId, this.userName);

  @override
  List<Object?> get props => [conversationId, userName];
}

class ClearTypingIndicator extends ChatEvent {
  final int conversationId;

  const ClearTypingIndicator(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class RefreshConversations extends ChatEvent {
  final int userId;

  const RefreshConversations(this.userId);

  @override
  List<Object?> get props => [userId];
}
