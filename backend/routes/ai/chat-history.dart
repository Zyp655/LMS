import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<AppDatabase>();

  if (context.request.method == HttpMethod.get) {
    return _getHistory(context, db);
  } else if (context.request.method == HttpMethod.post) {
    return _saveMessage(context, db);
  } else if (context.request.method == HttpMethod.delete) {
    return _clearHistory(context, db);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _getHistory(RequestContext context, AppDatabase db) async {
  final params = context.request.uri.queryParameters;
  final userId = int.tryParse(params['userId'] ?? '');
  final lessonId = int.tryParse(params['lessonId'] ?? '');

  if (userId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'userId is required'},
    );
  }

  try {
    var conv = await (db.select(db.chatConversations)
          ..where((c) => c.user1Id.equals(userId))
          ..where((c) => c.user2Id.equals(lessonId ?? 0)))
        .getSingleOrNull();

    if (conv == null) {
      return Response.json(body: {'messages': <Map<String, dynamic>>[]});
    }

    final messages = await (db.select(db.chatMessages)
          ..where((m) => m.conversationId.equals(conv.id))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .get();

    final messageList = messages.map((m) => {
      'role': m.messageType == 'ai_user' ? 'user' : 'assistant',
      'content': m.content,
      'timestamp': m.createdAt.toIso8601String(),
    }).toList();

    return Response.json(body: {'messages': messageList});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to load chat history'},
    );
  }
}

Future<Response> _saveMessage(RequestContext context, AppDatabase db) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final userId = body['userId'] as int?;
    final lessonId = body['lessonId'] as int? ?? 0;
    final role = body['role'] as String? ?? 'user';
    final content = body['content'] as String? ?? '';

    if (userId == null || content.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'userId and content are required'},
      );
    }

    var conv = await (db.select(db.chatConversations)
          ..where((c) => c.user1Id.equals(userId))
          ..where((c) => c.user2Id.equals(lessonId)))
        .getSingleOrNull();

    if (conv == null) {
      final now = DateTime.now();
      final id = await db.into(db.chatConversations).insert(
        ChatConversationsCompanion.insert(
          user1Id: userId,
          user2Id: lessonId,
          createdAt: now,
          updatedAt: now,
        ),
      );
      conv = await (db.select(db.chatConversations)
            ..where((c) => c.id.equals(id)))
          .getSingle();
    }

    final messageType = role == 'user' ? 'ai_user' : 'ai_assistant';
    await db.into(db.chatMessages).insert(
      ChatMessagesCompanion.insert(
        conversationId: conv.id,
        senderId: userId,
        content: content,
        messageType: Value(messageType),
        createdAt: DateTime.now(),
      ),
    );

    return Response.json(body: {'success': true});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to save message'},
    );
  }
}

Future<Response> _clearHistory(RequestContext context, AppDatabase db) async {
  final params = context.request.uri.queryParameters;
  final userId = int.tryParse(params['userId'] ?? '');
  final lessonId = int.tryParse(params['lessonId'] ?? '');

  if (userId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'userId is required'},
    );
  }

  try {
    final conv = await (db.select(db.chatConversations)
          ..where((c) => c.user1Id.equals(userId))
          ..where((c) => c.user2Id.equals(lessonId ?? 0)))
        .getSingleOrNull();

    if (conv != null) {
      await (db.delete(db.chatMessages)
            ..where((m) => m.conversationId.equals(conv.id)))
          .go();
      await (db.delete(db.chatConversations)
            ..where((c) => c.id.equals(conv.id)))
          .go();
    }

    return Response.json(body: {'success': true});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to clear history'},
    );
  }
}
