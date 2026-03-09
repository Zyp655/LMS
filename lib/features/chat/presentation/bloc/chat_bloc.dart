import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../../data/services/chat_ws_service.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/usecases/chat_usecases.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversationsUseCase getConversations;
  final GetMessagesUseCase getMessages;
  final SendMessageUseCase sendMessageUseCase;
  final MarkMessagesReadUseCase markMessagesReadUseCase;
  final CreateConversationUseCase createConversationUseCase;
  final ChatWsService wsService;

  StreamSubscription<ChatMessageEntity>? _messageSub;
  StreamSubscription<int>? _readReceiptSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  Timer? _typingClearTimer;

  List<dynamic>? _cachedConversations;

  ChatBloc({
    required this.getConversations,
    required this.getMessages,
    required this.sendMessageUseCase,
    required this.markMessagesReadUseCase,
    required this.createConversationUseCase,
    required this.wsService,
  }) : super(ChatInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MarkMessagesRead>(_onMarkRead);
    on<CreateConversation>(_onCreateConversation);
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);
    on<WebSocketMessageReceived>(_onWsMessageReceived);
    on<WebSocketReadReceipt>(_onWsReadReceipt);
    on<SendTypingEvent>(_onSendTyping);
    on<WebSocketTypingReceived>(_onTypingReceived);
    on<ClearTypingIndicator>(_onClearTyping);
    on<RefreshConversations>(_onRefreshConversations);
  }

  int get _currentUserId {
    try {
      return GetIt.instance<SharedPreferences>().getInt('userId') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _onConnectWebSocket(
    ConnectWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    if (wsService.isConnected) return;

    await wsService.connect(event.userId);

    _messageSub?.cancel();
    _messageSub = wsService.messageStream.listen((msg) {
      add(WebSocketMessageReceived(msg));
    });

    _readReceiptSub?.cancel();
    _readReceiptSub = wsService.readReceiptStream.listen((convId) {
      add(WebSocketReadReceipt(convId));
    });

    _typingSub?.cancel();
    _typingSub = wsService.typingStream.listen((data) {
      final convId = data['conversationId'] as int? ?? 0;
      final userName = data['userName'] as String? ?? '';
      add(WebSocketTypingReceived(convId, userName));
    });
  }

  Future<void> _onDisconnectWebSocket(
    DisconnectWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    _messageSub?.cancel();
    _readReceiptSub?.cancel();
    _typingSub?.cancel();
    _typingClearTimer?.cancel();
    wsService.disconnect();
  }

  void _onWsMessageReceived(
    WebSocketMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final msg = event.message;

    if (state is MessagesLoaded) {
      final current = state as MessagesLoaded;
      if (msg.conversationId == current.conversationId ||
          msg.conversationId == 0) {
        emit(current.copyWithNewMessage(msg).copyWithClearTyping());
        return;
      }
    }

    if (_cachedConversations != null) {
      _refreshCachedConversations(msg);
      emit(ConversationsLoaded(List.from(_cachedConversations!)));
    }
  }

  void _refreshCachedConversations(ChatMessageEntity msg) {
    if (_cachedConversations == null) return;
    final userId = _currentUserId;

    bool found = false;
    for (int i = 0; i < _cachedConversations!.length; i++) {
      final c = _cachedConversations![i];
      if (c.id == msg.conversationId) {
        _cachedConversations![i] = c.copyWith(
          lastMessage: msg.text,
          lastMessageTime: msg.timestamp,
          unreadCount: msg.senderId != userId
              ? c.unreadCount + 1
              : c.unreadCount,
        );
        found = true;
        break;
      }
    }

    if (found) {
      _cachedConversations!.sort(
        (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
      );
    }
  }

  void _onWsReadReceipt(WebSocketReadReceipt event, Emitter<ChatState> emit) {
    if (state is MessagesLoaded) {
      final current = state as MessagesLoaded;
      if (current.conversationId == event.conversationId) {
        emit(current.copyWithAllRead());
      }
    }
  }

  void _onSendTyping(SendTypingEvent event, Emitter<ChatState> emit) {
    if (wsService.isConnected) {
      wsService.sendTyping(event.conversationId);
    }
  }

  void _onTypingReceived(
    WebSocketTypingReceived event,
    Emitter<ChatState> emit,
  ) {
    if (state is MessagesLoaded) {
      final current = state as MessagesLoaded;
      if (current.conversationId == event.conversationId) {
        emit(current.copyWithTypingUser(event.userName));

        _typingClearTimer?.cancel();
        _typingClearTimer = Timer(const Duration(seconds: 3), () {
          add(ClearTypingIndicator(event.conversationId));
        });
      }
    }
  }

  void _onClearTyping(ClearTypingIndicator event, Emitter<ChatState> emit) {
    if (state is MessagesLoaded) {
      final current = state as MessagesLoaded;
      if (current.conversationId == event.conversationId) {
        emit(current.copyWithClearTyping());
      }
    }
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    final result = await getConversations(event.userId);
    result.fold((failure) => emit(ChatError(failure.message)), (conversations) {
      _cachedConversations = List.from(conversations);
      emit(ConversationsLoaded(conversations));
    });
  }

  Future<void> _onRefreshConversations(
    RefreshConversations event,
    Emitter<ChatState> emit,
  ) async {
    final result = await getConversations(event.userId);
    result.fold((failure) {}, (conversations) {
      _cachedConversations = List.from(conversations);
      emit(ConversationsLoaded(conversations));
    });
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    final result = await getMessages(event.conversationId);
    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (messages) => emit(
        MessagesLoaded(
          messages: messages,
          conversationId: event.conversationId,
        ),
      ),
    );
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      if (wsService.isConnected) {
        wsService.sendMessage(
          conversationId: event.conversationId,
          content: event.text,
          messageType: event.messageType,
          mediaUrl: event.mediaUrl,
        );
      } else {
        final result = await sendMessageUseCase(
          conversationId: event.conversationId,
          senderId: event.senderId,
          content: event.text,
        );
        result.fold((failure) => emit(ChatError(failure.message)), (message) {
          if (state is MessagesLoaded) {
            emit((state as MessagesLoaded).copyWithNewMessage(message));
          } else {
            emit(MessageSent(message));
          }
        });
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onMarkRead(
    MarkMessagesRead event,
    Emitter<ChatState> emit,
  ) async {
    if (wsService.isConnected) {
      wsService.markRead(event.conversationId);
    } else {
      await markMessagesReadUseCase(
        conversationId: event.conversationId,
        readerId: event.readerId,
      );
    }
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    final result = await createConversationUseCase(
      user1Id: event.user1Id,
      user2Id: event.user2Id,
    );
    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (conversationId) => emit(ConversationCreated(conversationId)),
    );
  }

  @override
  Future<void> close() {
    _messageSub?.cancel();
    _readReceiptSub?.cancel();
    _typingSub?.cancel();
    _typingClearTimer?.cancel();
    return super.close();
  }
}
