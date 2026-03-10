import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:backend/database/database.dart';

class FcmPushService {
  static String? _projectId;
  static String? _accessToken;
  static DateTime? _tokenExpiry;
  static Map<String, dynamic>? _serviceAccount;

  static Future<void> _loadServiceAccount() async {
    if (_serviceAccount != null) return;

    final files = Directory('.').listSync().whereType<File>();
    for (final file in files) {
      if (file.path.contains('firebase-adminsdk') &&
          file.path.endsWith('.json')) {
        final content = await file.readAsString();
        _serviceAccount = jsonDecode(content) as Map<String, dynamic>;
        _projectId = _serviceAccount!['project_id'] as String;
        return;
      }
    }

    final envPath = Platform.environment['FIREBASE_SERVICE_ACCOUNT'];
    if (envPath != null) {
      final content = await File(envPath).readAsString();
      _serviceAccount = jsonDecode(content) as Map<String, dynamic>;
      _projectId = _serviceAccount!['project_id'] as String;
    }
  }

  static Future<String?> _getAccessToken() async {
    await _loadServiceAccount();
    if (_serviceAccount == null) return null;

    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final exp = now + 3600;

      final header = base64Url
          .encode(utf8.encode(jsonEncode({'alg': 'RS256', 'typ': 'JWT'})));
      final payload = base64Url.encode(
        utf8.encode(
          jsonEncode({
            'iss': _serviceAccount!['client_email'],
            'scope': 'https://www.googleapis.com/auth/firebase.messaging',
            'aud': 'https://oauth2.googleapis.com/token',
            'iat': now,
            'exp': exp,
          }),
        ),
      );

      final privateKeyPem = _serviceAccount!['private_key'] as String;
      final signingInput = '$header.$payload';

      final privateKeyDer = _pemToDer(privateKeyPem);
      final signature = await _signRs256(
        utf8.encode(signingInput),
        privateKeyDer,
      );
      final sig = base64Url.encode(signature);
      final jwt = '$signingInput.$sig';

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
            'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=$jwt',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'] as String;
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
        return _accessToken;
      }
    } catch (e) {
      print('FCM token error: $e');
    }
    return null;
  }

  static List<int> _pemToDer(String pem) {
    final lines = pem
        .split('\n')
        .where(
          (line) => !line.startsWith('-----') && line.trim().isNotEmpty,
        )
        .join();
    return base64.decode(lines);
  }

  static Future<List<int>> _signRs256(
    List<int> data,
    List<int> privateKeyDer,
  ) async {
    final tempDir = Directory.systemTemp;
    final keyFile = File(
        '${tempDir.path}/fcm_key_${DateTime.now().millisecondsSinceEpoch}.pem');
    final dataFile = File(
        '${tempDir.path}/fcm_data_${DateTime.now().millisecondsSinceEpoch}.bin');
    final sigFile = File(
        '${tempDir.path}/fcm_sig_${DateTime.now().millisecondsSinceEpoch}.bin');

    try {
      final pemKey = '-----BEGIN PRIVATE KEY-----\n'
          '${base64.encode(privateKeyDer)}\n'
          '-----END PRIVATE KEY-----\n';

      await keyFile.writeAsString(pemKey);
      await dataFile.writeAsBytes(data);

      final result = await Process.run('openssl', [
        'dgst',
        '-sha256',
        '-sign',
        keyFile.path,
        '-out',
        sigFile.path,
        dataFile.path,
      ]);

      if (result.exitCode != 0) {
        throw Exception('openssl signing failed: ${result.stderr}');
      }

      return await sigFile.readAsBytes();
    } finally {
      try {
        await keyFile.delete();
      } catch (_) {}
      try {
        await dataFile.delete();
      } catch (_) {}
      try {
        await sigFile.delete();
      } catch (_) {}
    }
  }

  static Future<void> sendChatNotification({
    required AppDatabase db,
    required int recipientId,
    required String senderName,
    required String content,
    required int conversationId,
  }) async {
    try {
      final user = await (db.select(db.users)
            ..where((u) => u.id.equals(recipientId)))
          .getSingleOrNull();

      if (user == null || user.fcmToken == null) {
        print('[FCM] No user or fcmToken for recipientId=$recipientId');
        return;
      }
      print(
          '[FCM] Sending to recipientId=$recipientId, token=${user.fcmToken!.substring(0, 20)}...');

      final accessToken = await _getAccessToken();
      if (accessToken == null || _projectId == null) {
        print('[FCM] Failed to get access token or projectId');
        return;
      }

      final messageBody = {
        'message': {
          'token': user.fcmToken,
          'notification': {
            'title': senderName.isNotEmpty ? senderName : 'Tin nhắn mới',
            'body': content.length > 100
                ? '${content.substring(0, 100)}...'
                : content,
          },
          'data': {
            'type': 'chat_message',
            'conversationId': conversationId.toString(),
            'senderId': recipientId.toString(),
            'senderName': senderName,
          },
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': 'chat_messages',
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(messageBody),
      );
      print('[FCM] Response: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('FCM push error: $e');
    }
  }

  static Future<void> sendToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null || _projectId == null) return;

      final messageBody = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body.length > 200 ? '${body.substring(0, 200)}...' : body,
          },
          if (data != null) 'data': data,
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': 'ai_attendance',
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
        },
      };

      await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(messageBody),
      );
    } catch (e) {
      print('FCM sendToToken error: $e');
    }
  }
}
