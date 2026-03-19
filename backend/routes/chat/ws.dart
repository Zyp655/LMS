import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:backend/database/database.dart';
import 'package:backend/services/chat_broadcaster.dart';
import 'package:backend/services/fcm_push_service.dart';
import 'package:drift/drift.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<Response> onRequest(RequestContext context) async {
  final userId = int.tryParse(
    context.request.uri.queryParameters['userId'] ?? '',
  );

  if (userId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'userId query param is required'},
    );
  }

  final db = context.read<AppDatabase>();
  final broadcaster = ChatBroadcaster();

  final handler = webSocketHandler((WebSocketChannel channel, _) {
    broadcaster.connect(userId, channel);

    channel.sink.add(jsonEncode({
      'type': 'connected',
      'userId': userId,
    }));

    channel.stream.listen(
      (raw) async {
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          final type = data['type'] as String?;

          if (type == 'send') {
            final conversationId = data['conversationId'] as int;
            final content = data['content'] as String;
            final messageType = data['messageType'] as String? ?? 'text';
            final mediaUrl = data['mediaUrl'] as String?;
            final now = DateTime.now();

            final id = await db.into(db.chatMessages).insert(
                  ChatMessagesCompanion.insert(
                    conversationId: conversationId,
                    senderId: userId,
                    content: content,
                    messageType: Value(messageType),
                    mediaUrl: Value(mediaUrl),
                    createdAt: now,
                  ),
                );

            await (db.update(db.chatConversations)
                  ..where((c) => c.id.equals(conversationId)))
                .write(ChatConversationsCompanion(updatedAt: Value(now)));

            final conv = await (db.select(db.chatConversations)
                  ..where((c) => c.id.equals(conversationId)))
                .getSingleOrNull();

            if (conv != null) {
              final recipientId =
                  conv.user1Id == userId ? conv.user2Id : conv.user1Id;

              final sender = await (db.select(db.users)
                    ..where((u) => u.id.equals(userId)))
                  .getSingleOrNull();

              final msgData = {
                'id': id,
                'conversationId': conversationId,
                'senderId': userId,
                'senderName': sender?.fullName ?? sender?.email ?? '',
                'content': content,
                'messageType': messageType,
                'mediaUrl': mediaUrl,
                'isRead': false,
                'createdAt': now.toIso8601String(),
              };

              broadcaster.onNewMessage(
                recipientId: recipientId,
                messageData: msgData,
              );

              await FcmPushService.sendChatNotification(
                db: db,
                recipientId: recipientId,
                senderName: sender?.fullName ?? sender?.email ?? '',
                content: content,
                conversationId: conversationId,
              );

              channel.sink.add(jsonEncode({
                'type': 'message_sent',
                'data': msgData,
              }));
            }
          } else if (type == 'mark_read') {
            final conversationId = data['conversationId'] as int;

            await (db.update(db.chatMessages)
                  ..where(
                    (m) =>
                        m.conversationId.equals(conversationId) &
                        m.senderId.equals(userId).not() &
                        m.isRead.equals(false),
                  ))
                .write(const ChatMessagesCompanion(isRead: Value(true)));

            final conv = await (db.select(db.chatConversations)
                  ..where((c) => c.id.equals(conversationId)))
                .getSingleOrNull();

            if (conv != null) {
              final senderId =
                  conv.user1Id == userId ? conv.user2Id : conv.user1Id;
              broadcaster.onMessagesRead(
                senderId: senderId,
                conversationId: conversationId,
              );
            }
          } else if (type == 'ping') {
            channel.sink.add(jsonEncode({'type': 'pong'}));
          }
        } catch (e) {
          channel.sink.add(jsonEncode({
            'type': 'error',
            'message': e.toString(),
          }));
        }
      },
    );
  });

  return handler(context);
}
