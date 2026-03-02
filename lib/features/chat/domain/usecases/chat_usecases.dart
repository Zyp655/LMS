import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_conversation_entity.dart';
import '../entities/chat_message_entity.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUseCase {
  final ChatRepository repository;
  GetConversationsUseCase(this.repository);

  Future<Either<Failure, List<ChatConversationEntity>>> call(int userId) {
    return repository.getConversations(userId);
  }
}

class GetMessagesUseCase {
  final ChatRepository repository;
  GetMessagesUseCase(this.repository);

  Future<Either<Failure, List<ChatMessageEntity>>> call(int conversationId) {
    return repository.getMessages(conversationId);
  }
}

class SendMessageUseCase {
  final ChatRepository repository;
  SendMessageUseCase(this.repository);

  Future<Either<Failure, ChatMessageEntity>> call({
    required int conversationId,
    required int senderId,
    required String content,
  }) {
    return repository.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      content: content,
    );
  }
}

class MarkMessagesReadUseCase {
  final ChatRepository repository;
  MarkMessagesReadUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required int conversationId,
    required int readerId,
  }) {
    return repository.markMessagesRead(
      conversationId: conversationId,
      readerId: readerId,
    );
  }
}

class CreateConversationUseCase {
  final ChatRepository repository;
  CreateConversationUseCase(this.repository);

  Future<Either<Failure, int>> call({
    required int user1Id,
    required int user2Id,
  }) {
    return repository.createConversation(user1Id: user1Id, user2Id: user2Id);
  }
}
