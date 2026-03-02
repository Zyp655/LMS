import 'package:dartz/dartz.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/chat_conversation_entity.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient apiClient;

  ChatRepositoryImpl({required this.apiClient});

  @override
  Future<Either<Failure, List<ChatConversationEntity>>> getConversations(
    int userId,
  ) async {
    try {
      final response = await apiClient.get('/chat?userId=$userId');
      final data = response as Map<String, dynamic>;
      final rawConvs = data['conversations'] as List<dynamic>? ?? [];

      final conversations = rawConvs.map((json) {
        final c = json as Map<String, dynamic>;
        final lastMsg = c['lastMessage'] as Map<String, dynamic>?;
        return ChatConversationEntity(
          id: c['id'] as int,
          participantId: c['participantId'] as int,
          participantName: c['participantName'] as String? ?? 'Unknown',
          participantAvatar: null,
          isTeacher: c['isTeacher'] as bool? ?? false,
          lastMessage: lastMsg?['content'] as String? ?? '',
          lastMessageTime: lastMsg != null
              ? DateTime.parse(lastMsg['createdAt'] as String)
              : DateTime.now(),
          unreadCount: c['unreadCount'] as int? ?? 0,
        );
      }).toList();

      return Right(conversations);
    } catch (e) {
      return Left(ServerFailure('Lỗi tải hội thoại: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
    int conversationId,
  ) async {
    try {
      final response = await apiClient.get(
        '/chat/messages?conversationId=$conversationId',
      );
      final data = response as Map<String, dynamic>;
      final rawMsgs = data['messages'] as List<dynamic>? ?? [];

      final messages = rawMsgs
          .map(
            (json) => ChatMessageEntity.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return Right(messages);
    } catch (e) {
      return Left(ServerFailure('Lỗi tải tin nhắn: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required int conversationId,
    required int senderId,
    required String content,
  }) async {
    try {
      final response = await apiClient.post('/chat/messages', {
        'conversationId': conversationId,
        'senderId': senderId,
        'content': content,
      });
      final data = response as Map<String, dynamic>;

      final message = ChatMessageEntity(
        id: data['id'] as int,
        senderId: senderId,
        senderName: '',
        text: content,
        timestamp: DateTime.parse(data['createdAt'] as String),
        isRead: false,
        type: MessageType.text,
      );

      return Right(message);
    } catch (e) {
      return Left(ServerFailure('Lỗi gửi tin nhắn: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesRead({
    required int conversationId,
    required int readerId,
  }) async {
    try {
      await apiClient.put('/chat/messages', {
        'conversationId': conversationId,
        'readerId': readerId,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createConversation({
    required int user1Id,
    required int user2Id,
  }) async {
    try {
      final response = await apiClient.post('/chat', {
        'user1Id': user1Id,
        'user2Id': user2Id,
      });
      final data = response as Map<String, dynamic>;
      return Right(data['id'] as int);
    } catch (e) {
      return Left(ServerFailure('Lỗi tạo hội thoại: $e'));
    }
  }
}
