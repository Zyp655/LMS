import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_client.dart';
import 'ai_assistant_event.dart';
import 'ai_assistant_state.dart';

class AiAssistantBloc extends Bloc<AiAssistantEvent, AiAssistantState> {
  final ApiClient apiClient;

  AiAssistantBloc({required this.apiClient}) : super(AiInitial()) {
    on<AskAiQuestion>(_onAskQuestion);
    on<SummarizeLesson>(_onSummarize);
    on<ClearChat>(_onClearChat);
    on<LoadChatHistory>(_onLoadHistory);
  }

  Future<void> _onLoadHistory(
    LoadChatHistory event,
    Emitter<AiAssistantState> emit,
  ) async {
    try {
      final lessonId = event.lessonId ?? 0;
      final response = await apiClient.get(
        '/ai/chat-history?userId=${event.userId}&lessonId=$lessonId',
      );
      final data = response as Map<String, dynamic>;
      final rawMessages = data['messages'] as List? ?? [];

      if (rawMessages.isEmpty) {
        emit(AiInitial());
        return;
      }

      final messages = rawMessages.map((m) {
        final msg = m as Map<String, dynamic>;
        return AiChatMessage(
          role: msg['role'] as String,
          content: msg['content'] as String,
          timestamp: DateTime.tryParse(msg['timestamp'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();

      emit(AiChatLoaded(messages));
    } catch (_) {
      emit(AiInitial());
    }
  }

  Future<void> _onAskQuestion(
    AskAiQuestion event,
    Emitter<AiAssistantState> emit,
  ) async {
    final currentMessages = <AiChatMessage>[];
    if (state is AiChatLoaded) {
      currentMessages.addAll((state as AiChatLoaded).messages);
    } else if (state is AiChatLoading) {
      currentMessages.addAll((state as AiChatLoading).messages);
    } else if (state is AiError &&
        (state as AiError).previousMessages != null) {
      currentMessages.addAll((state as AiError).previousMessages!);
    }

    currentMessages.add(
      AiChatMessage(
        role: 'user',
        content: event.question,
        timestamp: DateTime.now(),
      ),
    );

    emit(AiChatLoading(List.from(currentMessages)));

    _persistMessage(event.userId, event.lessonId, 'user', event.question);

    try {
      final history = currentMessages
          .where((m) => m != currentMessages.last)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final response = await apiClient.post('/ai/chat', {
        'lessonTitle': event.lessonTitle,
        'textContent': event.textContent,
        'history': history,
        'question': event.question,
      });

      final data = response as Map<String, dynamic>;
      final answer = data['answer'] as String? ?? 'Không có câu trả lời.';

      currentMessages.add(
        AiChatMessage(
          role: 'assistant',
          content: answer,
          timestamp: DateTime.now(),
        ),
      );

      _persistMessage(event.userId, event.lessonId, 'assistant', answer);

      emit(AiChatLoaded(List.from(currentMessages)));
    } catch (e) {
      emit(
        AiError(
          'Không thể kết nối AI: ${e.toString()}',
          previousMessages: currentMessages,
        ),
      );
    }
  }

  void _persistMessage(int? userId, int? lessonId, String role, String content) {
    if (userId == null) return;
    apiClient.post('/ai/chat-history', {
      'userId': userId,
      'lessonId': lessonId ?? 0,
      'role': role,
      'content': content,
    }).catchError((_) => null);
  }

  Future<void> _onSummarize(
    SummarizeLesson event,
    Emitter<AiAssistantState> emit,
  ) async {
    emit(AiSummaryLoading());

    try {
      final response = await apiClient.post('/ai/summarize', {
        'lessonTitle': event.lessonTitle,
        'textContent': event.textContent,
      });

      final data = response as Map<String, dynamic>;
      final summary = data['summary'] as String? ?? '';
      final keyPoints =
          (data['keyPoints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final keywords =
          (data['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      emit(
        AiSummaryLoaded(
          summary: summary,
          keyPoints: keyPoints,
          keywords: keywords,
        ),
      );
    } catch (e) {
      emit(AiError('Không thể tóm tắt bài giảng: ${e.toString()}'));
    }
  }

  Future<void> _onClearChat(ClearChat event, Emitter<AiAssistantState> emit) async {
    if (event.userId != null) {
      apiClient.delete(
        '/ai/chat-history?userId=${event.userId}&lessonId=${event.lessonId ?? 0}',
      ).catchError((_) => null);
    }
    emit(AiInitial());
  }
}
