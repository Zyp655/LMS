import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/module_entity.dart';
import '../../../../core/route/app_route.dart';
import '../../../../core/theme/app_colors.dart';

class LessonListSheet extends StatelessWidget {
  final List<LessonEntity> allLessons;
  final int currentIndex;
  final List<ModuleEntity>? allModules;
  final int userId;

  const LessonListSheet({
    super.key,
    required this.allLessons,
    required this.currentIndex,
    this.allModules,
    required this.userId,
  });

  static void show(
    BuildContext context, {
    required List<LessonEntity> allLessons,
    required int currentIndex,
    List<ModuleEntity>? allModules,
    required int userId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LessonListSheet(
        allLessons: allLessons,
        currentIndex: currentIndex,
        allModules: allModules,
        userId: userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      'Danh sách bài học',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${allLessons.length} bài',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),

              Expanded(
                child: allModules != null
                    ? _buildGroupedList(context, cs, scrollCtrl)
                    : _buildFlatList(context, cs, scrollCtrl),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    ColorScheme cs,
    ScrollController scrollCtrl,
  ) {
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: allModules!.length,
      itemBuilder: (_, moduleIdx) {
        final module = allModules![moduleIdx];
        final lessons = module.lessons ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: cs.surfaceContainerLowest,
              child: Text(
                'Chương ${moduleIdx + 1}: ${module.title}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
            ...lessons.map((lesson) {
              final globalIdx = allLessons.indexWhere((l) => l.id == lesson.id);
              final isCurrent = globalIdx == currentIndex;
              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.accent
                        : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${globalIdx + 1}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  lesson.title,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? AppColors.accent : cs.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${lesson.durationMinutes} phút • ${lesson.type.name}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                trailing: isCurrent
                    ? Icon(
                        Icons.play_circle_fill,
                        color: AppColors.accent,
                      )
                    : Icon(
                        Icons.play_circle_outline,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                onTap: () {
                  Navigator.pop(context);
                  if (!isCurrent) {
                    context.go(
                      AppRoutes.lessonPlayer,
                      extra: {
                        'lesson': lesson,
                        'userId': userId,
                        'allModules': allModules,
                      },
                    );
                  }
                },
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildFlatList(
    BuildContext context,
    ColorScheme cs,
    ScrollController scrollCtrl,
  ) {
    return ListView.builder(
      controller: scrollCtrl,
      itemCount: allLessons.length,
      itemBuilder: (_, i) {
        final lesson = allLessons[i];
        final isCurrent = i == currentIndex;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isCurrent
                ? AppColors.accent
                : cs.surfaceContainerHighest,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                color: isCurrent ? Colors.white : cs.onSurfaceVariant,
              ),
            ),
          ),
          title: Text(
            lesson.title,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? AppColors.accent : cs.onSurface,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            if (!isCurrent) {
              context.go(
                AppRoutes.lessonPlayer,
                extra: {
                  'lesson': lesson,
                  'userId': userId,
                  'allModules': allModules,
                },
              );
            }
          },
        );
      },
    );
  }
}
