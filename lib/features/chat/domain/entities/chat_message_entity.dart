import 'package:equatable/equatable.dart';

class ChatMessageEntity extends Equatable {
  final int id;
  final int senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? mediaUrl;

  const ChatMessageEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.mediaUrl,
  });

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) {
    return ChatMessageEntity(
      id: json['id'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String? ?? '',
      text: json['content'] as String? ?? '',
      timestamp: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      type: parseType(json['messageType'] as String?),
      mediaUrl: json['mediaUrl'] as String?,
    );
  }

  static MessageType parseType(String? t) => switch (t) {
    'image' => MessageType.image,
    'file' => MessageType.file,
    'system' => MessageType.system,
    _ => MessageType.text,
  };

  @override
  List<Object?> get props => [
    id,
    senderId,
    text,
    timestamp,
    isRead,
    type,
    mediaUrl,
  ];
}

enum MessageType { text, image, file, system }
