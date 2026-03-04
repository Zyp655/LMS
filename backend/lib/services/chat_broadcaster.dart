import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatBroadcaster {
  static final ChatBroadcaster _instance = ChatBroadcaster._internal();
  factory ChatBroadcaster() => _instance;
  ChatBroadcaster._internal();

  final Map<int, Set<WebSocketChannel>> _userChannels = {};

  void connect(int userId, WebSocketChannel channel) {
    _userChannels.putIfAbsent(userId, () => {});
    _userChannels[userId]!.add(channel);
  }

  void disconnect(int userId, WebSocketChannel channel) {
    _userChannels[userId]?.remove(channel);
    if (_userChannels[userId]?.isEmpty ?? false) {
      _userChannels.remove(userId);
    }
  }

  void sendToUser(int userId, Map<String, dynamic> event) {
    final channels = _userChannels[userId];
    if (channels == null || channels.isEmpty) return;

    final message = jsonEncode(event);
    final stale = <WebSocketChannel>[];

    for (final channel in channels) {
      try {
        channel.sink.add(message);
      } catch (_) {
        stale.add(channel);
      }
    }

    for (final ch in stale) {
      channels.remove(ch);
    }
  }

  void onNewMessage({
    required int recipientId,
    required Map<String, dynamic> messageData,
  }) {
    sendToUser(recipientId, {
      'type': 'new_message',
      'data': messageData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void onNotification({
    required int userId,
    required Map<String, dynamic> notificationData,
  }) {
    sendToUser(userId, {
      'type': 'notification',
      'data': notificationData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void onMessagesRead({
    required int senderId,
    required int conversationId,
  }) {
    sendToUser(senderId, {
      'type': 'messages_read',
      'data': {'conversationId': conversationId},
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  bool isUserOnline(int userId) => _userChannels[userId]?.isNotEmpty ?? false;

  int get totalConnections =>
      _userChannels.values.fold(0, (s, set) => s + set.length);
}
