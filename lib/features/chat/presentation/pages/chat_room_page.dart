import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/fcm_service.dart';

class ChatRoomPage extends StatefulWidget {
  final int conversationId;
  final String participantName;
  final bool isTeacher;

  const ChatRoomPage({
    super.key,
    required this.conversationId,
    required this.participantName,
    this.isTeacher = false,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatBloc _chatBloc;
  int _currentUserId = 0;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    _chatBloc = GetIt.instance<ChatBloc>();
    _loadUserIdAndFetch();
    FcmService().setActiveConversation(widget.conversationId);
  }

  void _loadUserIdAndFetch() {
    final prefs = GetIt.instance<SharedPreferences>();
    _currentUserId = prefs.getInt('userId') ?? 0;

    _chatBloc
      ..add(ConnectWebSocket(_currentUserId))
      ..add(LoadMessages(widget.conversationId));

    _chatBloc.add(
      MarkMessagesRead(
        conversationId: widget.conversationId,
        readerId: _currentUserId,
      ),
    );
  }

  @override
  void dispose() {
    FcmService().setActiveConversation(null);
    _typingDebounce?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _chatBloc.add(LoadConversations(_currentUserId));
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatBloc.add(
      SendMessage(
        conversationId: widget.conversationId,
        senderId: _currentUserId,
        text: text,
      ),
    );
    _messageController.clear();
    _scrollToBottom();
  }

  void _onTextChanged(String text) {
    if (text.isEmpty) return;
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 500), () {
      _chatBloc.add(SendTypingEvent(widget.conversationId));
    });
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;

    _chatBloc.add(
      SendMessage(
        conversationId: widget.conversationId,
        senderId: _currentUserId,
        text: '📷 Ảnh',
        mediaUrl: image.path,
        messageType: 'image',
      ),
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final cardColor = isDark ? AppColors.darkBackground : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkBackground;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 1,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: widget.isTeacher
                    ? AppColors.primary.withAlpha(30)
                    : AppColors.accent.withAlpha(30),
                child: Text(
                  widget.participantName[0].toUpperCase(),
                  style: TextStyle(
                    color: widget.isTeacher
                        ? AppColors.primary
                        : AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.participantName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    BlocBuilder<ChatBloc, ChatState>(
                      buildWhen: (prev, curr) {
                        final prevTyping = prev is MessagesLoaded
                            ? prev.typingUsers
                            : <String>{};
                        final currTyping = curr is MessagesLoaded
                            ? curr.typingUsers
                            : <String>{};
                        return prevTyping != currTyping;
                      },
                      builder: (context, state) {
                        if (state is MessagesLoaded &&
                            state.typingUsers.isNotEmpty) {
                          return Text(
                            'Đang nhập...',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        }
                        return Text(
                          widget.isTeacher ? 'Giáo viên' : 'Sinh viên',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert, color: subTextColor),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, state) {
                  if (state is MessagesLoaded) {
                    _scrollToBottom();
                  }
                },
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  if (state is MessagesLoaded) {
                    if (state.messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.waving_hand_rounded,
                              size: 48,
                              color: AppColors.primary.withAlpha(100),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Bắt đầu cuộc trò chuyện!',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      itemCount:
                          state.messages.length +
                          (state.typingUsers.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length) {
                          return _TypingBubble(
                            partnerName: widget.participantName,
                            partnerColor: widget.isTeacher
                                ? AppColors.primary
                                : AppColors.accent,
                            isDark: isDark,
                          );
                        }

                        final msg = state.messages[index];
                        final isMe = msg.senderId == _currentUserId;
                        final showAvatar =
                            !isMe &&
                            (index == 0 ||
                                state.messages[index - 1].senderId !=
                                    msg.senderId);

                        final isLastSeen =
                            isMe &&
                            msg.isRead &&
                            (index == state.messages.length - 1 ||
                                !state.messages[index + 1].isRead ||
                                state.messages[index + 1].senderId !=
                                    _currentUserId);

                        return _MessageBubble(
                          message: msg,
                          isMe: isMe,
                          showAvatar: showAvatar,
                          showSeenLabel: isLastSeen,
                          partnerColor: widget.isTeacher
                              ? AppColors.primary
                              : AppColors.accent,
                          isDark: isDark,
                        );
                      },
                    );
                  }
                  if (state is ChatError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: TextStyle(color: subTextColor),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 12,
                right: 8,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image_rounded, color: AppColors.primary),
                    onPressed: _pickAndSendImage,
                    tooltip: 'Gửi ảnh',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: textColor),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      onChanged: _onTextChanged,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(color: subTextColor),
                        filled: true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  final String partnerName;
  final Color partnerColor;
  final bool isDark;

  const _TypingBubble({
    required this.partnerName,
    required this.partnerColor,
    required this.isDark,
  });

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with TickerProviderStateMixin {
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 48, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: widget.partnerColor.withAlpha(30),
            child: Text(
              widget.partnerName[0].toUpperCase(),
              style: TextStyle(
                color: widget.partnerColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _dotController,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.2;
                    final t = (_dotController.value - delay).clamp(0.0, 1.0);
                    final bounce = (1 - (2 * t - 1).abs());
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.translate(
                        offset: Offset(0, -4 * bounce),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.partnerColor.withAlpha(
                              (100 + 155 * bounce).toInt(),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMe;
  final bool showAvatar;
  final bool showSeenLabel;
  final Color partnerColor;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    this.showSeenLabel = false,
    required this.partnerColor,
    required this.isDark,
  });

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
        bottom: 6,
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe && showAvatar)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: partnerColor.withAlpha(30),
                  child: Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: partnerColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (!isMe)
                const SizedBox(width: 28),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (message.type == MessageType.image &&
                          message.mediaUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: message.mediaUrl!,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 200,
                              height: 150,
                              color: Colors.grey.withAlpha(40),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 200,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(40),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (message.text.isNotEmpty && message.text != '📷 Ảnh')
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                color: isMe ? Colors.white : _textColor,
                                fontSize: 15,
                              ),
                            ),
                          ),
                      ] else
                        Text(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : _textColor,
                            fontSize: 15,
                          ),
                        ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white.withAlpha(170)
                                  : (isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[400]),
                              fontSize: 11,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 14,
                              color: message.isRead
                                  ? Colors.lightBlueAccent
                                  : Colors.white.withAlpha(170),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (showSeenLabel)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: Text(
                'Đã xem',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.lightBlueAccent.withAlpha(180),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color get _textColor => isDark ? Colors.white : AppColors.darkBackground;
}
