import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../api/api_constants.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  int? _currentUserId;
  int? _activeConversationId;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
        'chat_messages',
        'Tin nhắn Chat',
        description: 'Thông báo khi có tin nhắn mới',
        importance: Importance.high,
        playSound: true,
      );

  Future<void> init({required int userId}) async {
    _currentUserId = userId;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_chatChannel);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }
    } catch (_) {}

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_sendTokenToServer);
  }

  void setActiveConversation(int? conversationId) {
    _activeConversationId = conversationId;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final conversationId = int.tryParse(data['conversationId'] ?? '');

    if (conversationId == _activeConversationId) {
      return;
    }

    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        id: conversationId ?? notification.hashCode,
        title: notification.title ?? 'Tin nhắn mới',
        body: notification.body ?? '',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _chatChannel.id,
            _chatChannel.name,
            channelDescription: _chatChannel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(data),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final conversationId = int.tryParse(data['conversationId'] ?? '');
    final recipientName = data['senderName'] ?? '';

    if (conversationId != null) {
      _navigateToChat(conversationId, recipientName);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final conversationId = int.tryParse(data['conversationId'] ?? '');
        final senderName = data['senderName'] ?? '';

        if (conversationId != null) {
          _navigateToChat(conversationId, senderName);
        }
      } catch (_) {}
    }
  }

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  void _navigateToChat(int conversationId, String recipientName) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamed(
        '/chat/room',
        arguments: {
          'conversationId': conversationId,
          'recipientName': recipientName,
        },
      );
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    if (_currentUserId == null) return;

    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/update-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _currentUserId, 'fcmToken': token}),
      );
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    _tokenRefreshSub = null;
    _onMessageSub = null;
    _currentUserId = null;
    _activeConversationId = null;
  }
}
