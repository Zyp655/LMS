import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_conversation_entity.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatConnected extends ChatState {}

class ConversationsLoaded extends ChatState {
  final List<ChatConversationEntity> conversations;

  const ConversationsLoaded(this.conversations);

  ConversationsLoaded copyWithUpdatedConversation({
    required int conversationId,
    required String lastMessage,
    required DateTime lastMessageTime,
    required int senderId,
    required int currentUserId,
  }) {
    final updated = conversations.map((c) {
      if (c.id == conversationId) {
        return ChatConversationEntity(
          id: c.id,
          participantId: c.participantId,
          participantName: c.participantName,
          participantAvatar: c.participantAvatar,
          isTeacher: c.isTeacher,
          lastMessage: lastMessage,
          lastMessageTime: lastMessageTime,
          unreadCount: senderId != currentUserId
              ? c.unreadCount + 1
              : c.unreadCount,
        );
      }
      return c;
    }).toList();
    updated.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return ConversationsLoaded(updated);
  }

  @override
  List<Object?> get props => [conversations];
}

class MessagesLoaded extends ChatState {
  final List<ChatMessageEntity> messages;
  final int conversationId;
  final Set<String> typingUsers;

  const MessagesLoaded({
    required this.messages,
    required this.conversationId,
    this.typingUsers = const {},
  });

  MessagesLoaded copyWithNewMessage(ChatMessageEntity msg) {
    final updated = List<ChatMessageEntity>.from(messages);
    if (!updated.any((m) => m.id == msg.id)) {
      updated.add(msg);
    }
    return MessagesLoaded(
      messages: updated,
      conversationId: conversationId,
      typingUsers: typingUsers,
    );
  }

  MessagesLoaded copyWithAllRead() {
    final updated = messages
        .map(
          (m) => ChatMessageEntity(
            id: m.id,
            conversationId: m.conversationId,
            senderId: m.senderId,
            senderName: m.senderName,
            text: m.text,
            timestamp: m.timestamp,
            isRead: true,
            type: m.type,
            mediaUrl: m.mediaUrl,
          ),
        )
        .toList();
    return MessagesLoaded(
      messages: updated,
      conversationId: conversationId,
      typingUsers: typingUsers,
    );
  }

  MessagesLoaded copyWithTypingUser(String userName) {
    return MessagesLoaded(
      messages: messages,
      conversationId: conversationId,
      typingUsers: {...typingUsers, userName},
    );
  }

  MessagesLoaded copyWithClearTyping() {
    return MessagesLoaded(
      messages: messages,
      conversationId: conversationId,
      typingUsers: const {},
    );
  }

  @override
  List<Object?> get props => [messages, conversationId, typingUsers];
}

class MessageSent extends ChatState {
  final ChatMessageEntity message;

  const MessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

class ConversationCreated extends ChatState {
  final int conversationId;

  const ConversationCreated(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
