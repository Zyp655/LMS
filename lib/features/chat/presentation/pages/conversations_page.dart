import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/route/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/chat_conversation_entity.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  late final ChatBloc _chatBloc;
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _chatBloc = GetIt.instance<ChatBloc>();
    _loadUserIdAndFetch();
  }

  Future<void> _loadUserIdAndFetch() async {
    final prefs = GetIt.instance<SharedPreferences>();
    _currentUserId = prefs.getInt('userId') ?? 0;
    _chatBloc.add(ConnectWebSocket(_currentUserId));
    _chatBloc.add(LoadConversations(_currentUserId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: _ConversationsView(
        currentUserId: _currentUserId,
        chatBloc: _chatBloc,
      ),
    );
  }
}

class _ConversationsView extends StatelessWidget {
  final int currentUserId;
  final ChatBloc chatBloc;

  const _ConversationsView({
    required this.currentUserId,
    required this.chatBloc,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bgColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = AppColors.textPrimary(context);
    final subTextColor = AppColors.textSecondary(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Tin nhắn',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_square, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tạo cuộc trò chuyện mới')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          chatBloc.add(RefreshConversations(currentUserId));
        },
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              );
            }
            if (state is ConversationsLoaded) {
              if (state.conversations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: subTextColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có cuộc trò chuyện nào',
                        style: TextStyle(color: subTextColor, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.conversations.length,
                separatorBuilder: (_, __) => Divider(
                  indent: 76,
                  height: 1,
                  color: subTextColor.withAlpha(30),
                ),
                itemBuilder: (context, index) {
                  final conv = state.conversations[index];
                  return _ConversationTile(
                    conversation: conv,
                    currentUserId: currentUserId,
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  );
                },
              );
            }
            if (state is ChatError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversationEntity conversation;
  final int currentUserId;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    final initials = conversation.participantName.isNotEmpty
        ? conversation.participantName[0].toUpperCase()
        : '?';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: conversation.isTeacher
                ? AppColors.secondary.withAlpha(30)
                : AppColors.success.withAlpha(30),
            child: Text(
              initials,
              style: TextStyle(
                color: conversation.isTeacher
                    ? AppColors.secondary
                    : AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          if (conversation.isTeacher)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cardColor, width: 2),
                ),
                child: Icon(Icons.school, size: 8, color: Colors.white),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.participantName,
              style: TextStyle(
                color: textColor,
                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            DateFormatter.formatRelativeTime(conversation.lastMessageTime),
            style: TextStyle(
              color: hasUnread ? AppColors.secondary : subTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread ? textColor : subTextColor,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        context.push(
          AppRoutes.chatRoom,
          extra: {
            'conversationId': conversation.id,
            'participantName': conversation.participantName,
            'isTeacher': conversation.isTeacher,
          },
        );
      },
    );
  }
}
