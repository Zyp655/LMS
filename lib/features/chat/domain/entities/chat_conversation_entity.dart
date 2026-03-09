import 'package:equatable/equatable.dart';

class ChatConversationEntity extends Equatable {
  final int id;
  final int participantId;
  final String participantName;
  final String? participantAvatar;
  final bool isTeacher;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const ChatConversationEntity({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    this.isTeacher = false,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  ChatConversationEntity copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatConversationEntity(
      id: id,
      participantId: participantId,
      participantName: participantName,
      participantAvatar: participantAvatar,
      isTeacher: isTeacher,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    participantId,
    participantName,
    lastMessage,
    lastMessageTime,
    unreadCount,
  ];
}
