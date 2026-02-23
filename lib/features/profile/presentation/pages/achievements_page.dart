import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/achievement_bloc.dart';
import '../bloc/achievement_state.dart';
import '../../domain/entities/achievement_entity.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Thành tích'),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<AchievementBloc, AchievementState>(
        builder: (context, state) {
          if (state is AchievementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AchievementError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(color: textColor, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (state is AchievementsLoaded) {
            return _buildContent(
              context,
              state.achievements,
              state.totalPoints,
              state.earnedCount,
              cardColor,
              textColor,
              isDarkMode,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<AchievementEntity> achievements,
    int totalPoints,
    int earnedCount,
    Color cardColor,
    Color textColor,
    bool isDarkMode,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.teal.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.workspace_premium,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  '$totalPoints điểm',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$earnedCount/${achievements.length} thành tích',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: achievements.isEmpty
                      ? 0
                      : earnedCount / achievements.length,
                  backgroundColor: Colors.white.withAlpha(50),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...achievements.map(
            (a) => _buildAchievementCard(a, cardColor, textColor, isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    AchievementEntity achievement,
    Color cardColor,
    Color textColor,
    bool isDarkMode,
  ) {
    final earned = achievement.earned;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: earned ? cardColor : cardColor.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: earned
            ? Border.all(color: Colors.teal.withAlpha(100), width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: earned
                  ? Colors.teal.withAlpha(50)
                  : Colors.grey.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(achievement.iconName),
              size: 28,
              color: earned ? Colors.teal : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: earned ? textColor : textColor.withAlpha(100),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: earned
                        ? textColor.withAlpha(180)
                        : textColor.withAlpha(100),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: earned ? Colors.teal : Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${achievement.points}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (earned) ...[
                const SizedBox(height: 4),
                const Icon(Icons.check_circle, color: Colors.teal, size: 20),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'whatshot':
        return Icons.whatshot;
      case 'military_tech':
        return Icons.military_tech;
      case 'bolt':
        return Icons.bolt;
      case 'school':
        return Icons.school;
      case 'emoji_flags':
        return Icons.emoji_flags;
      case 'leaderboard':
        return Icons.leaderboard;
      default:
        return Icons.emoji_events;
    }
  }
}
