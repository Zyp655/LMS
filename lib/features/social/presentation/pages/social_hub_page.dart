import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/route/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../injection_container.dart';
import '../../../chat/domain/entities/chat_conversation_entity.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/presentation/bloc/chat_event.dart';
import '../../../chat/presentation/bloc/chat_state.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../notifications/presentation/bloc/notification_event.dart';
import '../../../notifications/presentation/bloc/notification_state.dart';

class SocialHubPage extends StatefulWidget {
  const SocialHubPage({super.key});

  @override
  State<SocialHubPage> createState() => _SocialHubPageState();
}

class _SocialHubPageState extends State<SocialHubPage> {
  late final ChatBloc _chatBloc;
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _chatBloc = sl<ChatBloc>();
    _loadAndFetch();
  }

  void _loadAndFetch() {
    final prefs = sl<SharedPreferences>();
    _currentUserId = prefs.getInt('userId') ?? 0;
    if (_currentUserId == 0) return;

    _chatBloc
      ..add(ConnectWebSocket(_currentUserId))
      ..add(LoadConversations(_currentUserId));

    context.read<NotificationBloc>().add(
      LoadNotifications(userId: _currentUserId),
    );
  }

  @override
  void dispose() {
    _chatBloc
      ..add(const DisconnectWebSocket())
      ..close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bgColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = AppColors.textPrimary(context);
    final subTextColor = AppColors.textSecondary(context);

    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Cộng đồng',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, notifState) {
                final unread = notifState is NotificationsLoaded
                    ? notifState.unreadCount
                    : 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: textColor,
                      ),
                      onPressed: () =>
                          context.push(AppRoutes.notifications),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _chatBloc.add(LoadConversations(_currentUserId));
            context.read<NotificationBloc>().add(
              RefreshNotifications(_currentUserId),
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, notifState) {
                  final unread = notifState is NotificationsLoaded
                      ? notifState.unreadCount
                      : 0;
                  return _SectionCard(
                    icon: Icons.notifications_active_rounded,
                    color: AppColors.warning,
                    title: 'Thông báo',
                    subtitle: unread > 0
                        ? '$unread thông báo chưa đọc'
                        : 'Không có thông báo mới',
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    onTap: () =>
                        context.push(AppRoutes.notifications),
                  );
                },
              ),

              const SizedBox(height: 12),

              _SectionCard(
                icon: Icons.forum_rounded,
                color: AppColors.error,
                title: 'Diễn đàn thảo luận',
                subtitle: 'Đặt câu hỏi, chia sẻ kiến thức',
                cardColor: cardColor,
                textColor: textColor,
                subTextColor: subTextColor,
                onTap: () =>
                    context.push(AppRoutes.discussions),
              ),

              const SizedBox(height: 12),

              _SectionCard(
                icon: Icons.emoji_events_rounded,
                color: AppColors.accent,
                title: 'Bảng xếp hạng',
                subtitle: 'Xem thứ hạng Quiz & Thành tích',
                cardColor: cardColor,
                textColor: textColor,
                subTextColor: subTextColor,
                onTap: () =>
                    context.push(AppRoutes.leaderboard),
              ),

              const SizedBox(height: 16),

              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  final count = state is ConversationsLoaded
                      ? state.conversations.length
                      : 0;
                  return Row(
                    children: [
                      Icon(
                        Icons.chat_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tin nhắn với giảng viên',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$count',
                        style: TextStyle(color: subTextColor, fontSize: 14),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                        ),
                      ),
                    );
                  }
                  if (state is ConversationsLoaded) {
                    if (state.conversations.isEmpty) {
                      return _buildEmptyState(subTextColor);
                    }
                    return Column(
                      children: state.conversations
                          .map(
                            (conv) => _ConversationTile(
                              conversation: conv,
                              cardColor: cardColor,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                          )
                          .toList(),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color subTextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: subTextColor),
            const SizedBox(height: 16),
            Text(
              'Chưa có cuộc hội thoại nào',
              style: TextStyle(color: subTextColor, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng ký khóa học và nhắn tin cho giảng viên',
              style: TextStyle(
                color: subTextColor.withAlpha(150),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: subTextColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: subTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversationEntity conversation;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const _ConversationTile({
    required this.conversation,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
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
                          child: Icon(
                            Icons.school,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.participantName,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormatter.formatRelativeTime(
                              conversation.lastMessageTime,
                            ),
                            style: TextStyle(
                              color: hasUnread
                                  ? AppColors.secondary
                                  : subTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage.isNotEmpty
                                  ? conversation.lastMessage
                                  : 'Chưa có tin nhắn',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasUnread ? textColor : subTextColor,
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
