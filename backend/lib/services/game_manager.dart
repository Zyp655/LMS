import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class GameManager {
  static final GameManager _instance = GameManager._internal();
  factory GameManager() => _instance;
  GameManager._internal();

  final Map<String, List<WebSocketChannel>> _rooms = {};
  final Map<String, Map<String, dynamic>> _roomStates = {};

  void createRoom(String roomCode, Map<String, dynamic> quizData) {
    _rooms[roomCode] = [];
    _roomStates[roomCode] = {
      'players': <Map<String, dynamic>>[],
      'status': 'waiting',
      'quiz': quizData,
      'currentQuestionIndex': 0,
    };
  }

  void join(String roomCode, WebSocketChannel channel) {
    if (!_rooms.containsKey(roomCode)) {
      _rooms[roomCode] = [];
      _roomStates[roomCode] = {
        'players': <Map<String, dynamic>>[],
        'status': 'waiting',
      };
    }
    _rooms[roomCode]!.add(channel);

    channel.sink.add(jsonEncode(
        {'type': 'connected', 'message': 'Connected to room $roomCode'}));

    channel.stream.listen(
      (message) {
        _handleMessage(roomCode, channel, message);
      },
      onDone: () {
        _leave(roomCode, channel);
      },
      onError: (_) {
        _leave(roomCode, channel);
      },
    );
  }

  void _leave(String roomCode, WebSocketChannel channel) {
    _rooms[roomCode]?.remove(channel);
    final roomChannels = _rooms[roomCode];
    final roomState = _roomStates[roomCode];
    final players = roomState?['players'] as List?;
    if (roomChannels != null &&
        roomChannels.isEmpty &&
        (players == null || players.isEmpty)) {
      _rooms.remove(roomCode);
      _roomStates.remove(roomCode);
    }
  }

  void _handleMessage(
      String roomCode, WebSocketChannel sender, dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final type = data['type'];

      if (type == 'join_room') {
        final user = data['user'];
        final players = _roomStates[roomCode]!['players'] as List;
        final existingIndex = players.indexWhere((p) => p['id'] == user['id']);
        if (existingIndex == -1) {
          players.add(user);
        } else {
          players[existingIndex] = user;
        }
        _broadcast(roomCode, {
          'type': 'room_update',
          'room': {'code': roomCode},
          'players': players,
          'isHost': players.first['id'] == user['id']
        });
      } else if (type == 'start_game') {
        final state = _roomStates[roomCode];
        if (state != null && state['quiz'] != null) {
          state['status'] = 'playing';
          state['currentQuestionIndex'] = 0;
          final questions = state['quiz']['questions'] as List? ?? [];
          if (questions.isNotEmpty) {
            final firstQuestion = questions[0];
            _broadcast(roomCode, {
              'type': 'game_start',
              'question': firstQuestion,
              'currentQuestionIndex': 0,
              'totalQuestions': questions.length,
              'timeLeft': 30,
            });
          }
        }
      } else if (type == 'submit_answer') {
        final state = _roomStates[roomCode];
        if (state != null) {
          final userId = data['userId'] as int?;
          final answerIndex = data['answerIndex'] as int?;
          final questionIndex = data['questionIndex'] as int?;
          final questions = state['quiz']?['questions'] as List? ?? [];

          if (questionIndex != null && questionIndex < questions.length) {
            final currentQuestion = questions[questionIndex];
            final correctIndex = currentQuestion['correctIndex'] as int?;
            final isCorrect = answerIndex == correctIndex;
            final players = state['players'] as List;

            for (var player in players) {
              if (player['id'] == userId) {
                player['score'] =
                    (player['score'] ?? 0) + (isCorrect ? 100 : 0);
              }
            }

            _broadcast(roomCode, {
              'type': 'answer_result',
              'userId': userId,
              'isCorrect': isCorrect,
              'correctIndex': correctIndex,
            });

            final nextIndex = (state['currentQuestionIndex'] as int) + 1;
            if (nextIndex < questions.length) {
              state['currentQuestionIndex'] = nextIndex;
              Future.delayed(const Duration(seconds: 2), () {
                _broadcast(roomCode, {
                  'type': 'next_question',
                  'question': questions[nextIndex],
                  'currentQuestionIndex': nextIndex,
                  'totalQuestions': questions.length,
                  'timeLeft': 30,
                });
              });
            } else {
              state['status'] = 'finished';
              _broadcast(roomCode, {
                'type': 'game_over',
                'leaderboard': players
                    .map((p) => {'name': p['name'], 'score': p['score'] ?? 0})
                    .toList(),
              });
            }
          }
        }
      } else {
        _broadcast(roomCode, data);
      }
    } catch (_) {}
  }

  void _broadcast(String roomCode, dynamic message) {
    final channels = _rooms[roomCode] ?? [];
    final msgString = message is String ? message : jsonEncode(message);
    for (final channel in channels) {
      channel.sink.add(msgString);
    }
  }
}
