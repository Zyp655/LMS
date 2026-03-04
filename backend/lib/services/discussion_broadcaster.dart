import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';

class DiscussionBroadcaster {
  final Map<int, Set<WebSocket>> _rooms = {};
  final Map<int, Set<WebSocketChannel>> _channelRooms = {};

  void joinRoom(int lessonId, WebSocket socket) {
    _rooms.putIfAbsent(lessonId, () => {});
    _rooms[lessonId]!.add(socket);

    socket.done.then((_) {
      _rooms[lessonId]?.remove(socket);
      if (_rooms[lessonId]?.isEmpty ?? false) {
        _rooms.remove(lessonId);
      }
    });
  }

  void joinRoomChannel(int lessonId, WebSocketChannel channel) {
    _channelRooms.putIfAbsent(lessonId, () => {});
    _channelRooms[lessonId]!.add(channel);

    channel.stream.drain<void>().whenComplete(() {
      _channelRooms[lessonId]?.remove(channel);
      if (_channelRooms[lessonId]?.isEmpty ?? false) {
        _channelRooms.remove(lessonId);
      }
    });
  }

  void broadcast(int lessonId, Map<String, dynamic> event) {
    final message = jsonEncode(event);

    final sockets = _rooms[lessonId];
    if (sockets != null) {
      final stale = <WebSocket>[];
      for (final socket in sockets) {
        try {
          socket.add(message);
        } catch (_) {
          stale.add(socket);
        }
      }
      for (final s in stale) {
        sockets.remove(s);
      }
    }

    final channels = _channelRooms[lessonId];
    if (channels != null) {
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
  }

  void onNewComment(int lessonId, Map<String, dynamic> commentData) {
    broadcast(lessonId, {
      'type': 'new_comment',
      'data': commentData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void onVoteUpdate(int lessonId, int commentId, int upvotes, int downvotes) {
    broadcast(lessonId, {
      'type': 'vote_update',
      'data': {
        'commentId': commentId,
        'upvotes': upvotes,
        'downvotes': downvotes,
      },
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void onModeration(int lessonId, int commentId, String action) {
    broadcast(lessonId, {
      'type': 'moderation',
      'data': {
        'commentId': commentId,
        'action': action,
      },
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Map<String, int> get roomStats {
    final stats = <String, int>{};
    for (final entry in _rooms.entries) {
      stats[entry.key.toString()] =
          entry.value.length + (_channelRooms[entry.key]?.length ?? 0);
    }
    for (final entry in _channelRooms.entries) {
      if (!stats.containsKey(entry.key.toString())) {
        stats[entry.key.toString()] = entry.value.length;
      }
    }
    return stats;
  }

  int get totalConnections =>
      _rooms.values.fold(0, (s, set) => s + set.length) +
      _channelRooms.values.fold(0, (s, set) => s + set.length);
}
