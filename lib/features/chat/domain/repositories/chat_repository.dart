import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_conversation_entity.dart';
import '../entities/chat_message_entity.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ChatConversationEntity>>> getConversations(
    int userId,
  );

  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
    int conversationId,
  );

  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required int conversationId,
    required int senderId,
    required String content,
  });

  Future<Either<Failure, void>> markMessagesRead({
    required int conversationId,
    required int readerId,
  });

  Future<Either<Failure, int>> createConversation({
    required int user1Id,
    required int user2Id,
  });
}
