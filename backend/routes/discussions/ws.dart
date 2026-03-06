import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:backend/services/discussion_broadcaster.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<Response> onRequest(RequestContext context) async {
  final lessonId = int.tryParse(
    context.request.uri.queryParameters['lessonId'] ?? '',
  );

  if (lessonId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'lessonId query param is required'},
    );
  }

  final broadcaster = context.read<DiscussionBroadcaster>();

  final handler = webSocketHandler((WebSocketChannel channel, _) {

    channel.sink.add(jsonEncode({
      'type': 'connected',
      'lessonId': lessonId,
    }));

    channel.stream.listen(
      (raw) {
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          final type = data['type'] as String?;

          if (type == 'ping') {
            channel.sink.add(jsonEncode({'type': 'pong'}));
          }
        } catch (_) {}
      },
    );

    broadcaster.joinRoomChannel(lessonId, channel);
  });

  return handler(context);
}
