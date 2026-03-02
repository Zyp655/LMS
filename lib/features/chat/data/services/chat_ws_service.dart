import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/api/api_constants.dart';
import '../../domain/entities/chat_message_entity.dart';

class ChatWsService {
  static final ChatWsService _instance = ChatWsService._internal();
  factory ChatWsService() => _instance;
  ChatWsService._internal();

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int? _userId;
  bool _isConnecting = false;

  final _messageController = StreamController<ChatMessageEntity>.broadcast();
  final _readReceiptController = StreamController<int>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<ChatMessageEntity> get messageStream => _messageController.stream;
  Stream<int> get readReceiptStream => _readReceiptController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect(int userId) async {
    if (_channel != null || _isConnecting) return;
    _isConnecting = true;
    _userId = userId;

    try {
      final wsBase = ApiConstants.baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      final wsUrl = Uri.parse('$wsBase/chat/ws?userId=$userId');

      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        _onMessage,
        onDone: () {
          _channel = null;
          _scheduleReconnect();
        },
        onError: (_) {
          _channel = null;
          _scheduleReconnect();
        },
      );

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _channel?.sink.add(jsonEncode({'type': 'ping'}));
      });
    } catch (_) {
      _scheduleReconnect();
    }

    _isConnecting = false;
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'new_message' || type == 'message_sent') {
        final msgData = data['data'] as Map<String, dynamic>;
        final message = ChatMessageEntity(
          id: msgData['id'] as int,
          senderId: msgData['senderId'] as int,
          senderName: msgData['senderName'] as String? ?? '',
          text: msgData['content'] as String? ?? '',
          timestamp: DateTime.parse(msgData['createdAt'] as String),
          isRead: msgData['isRead'] as bool? ?? false,
          type: ChatMessageEntity.parseType(msgData['messageType'] as String?),
          mediaUrl: msgData['mediaUrl'] as String?,
        );
        _messageController.add(message);
      } else if (type == 'messages_read') {
        final convId = data['data']['conversationId'] as int;
        _readReceiptController.add(convId);
      } else if (type == 'typing') {
        _typingController.add(data['data'] as Map<String, dynamic>);
      } else if (type == 'notification') {
        final notifData = data['data'] as Map<String, dynamic>;
        _notificationController.add(notifData);
      }
    } catch (_) {}
  }

  void sendMessage({
    required int conversationId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
  }) {
    final payload = <String, dynamic>{
      'type': 'send',
      'conversationId': conversationId,
      'content': content,
      'messageType': messageType,
    };
    if (mediaUrl != null) payload['mediaUrl'] = mediaUrl;
    _channel?.sink.add(jsonEncode(payload));
  }

  void sendTyping(int conversationId) {
    _channel?.sink.add(
      jsonEncode({'type': 'typing', 'conversationId': conversationId}),
    );
  }

  void markRead(int conversationId) {
    _channel?.sink.add(
      jsonEncode({'type': 'mark_read', 'conversationId': conversationId}),
    );
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_userId != null) connect(_userId!);
    });
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _readReceiptController.close();
    _typingController.close();
    _notificationController.close();
  }
}
