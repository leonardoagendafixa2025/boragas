import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boragas/core/constants/app_colors.dart';
import 'package:boragas/features/customer/providers/marketing_providers.dart';
import 'story_viewer_dialog.dart';

class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider);
    if (stories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 98,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final group = stories[index];
          return InkWell(
            onTap: () {
              ref.read(storiesProvider.notifier).markSeen(group.id);
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Story',
                pageBuilder: (context, anim1, anim2) {
                  return StoryViewerDialog(group: group);
                },
              );
            },
            borderRadius: BorderRadius.circular(36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Story Avatar Ring
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: group.ringGradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: group.isUnseen
                        ? [
                            BoxShadow(
                              color: group.ringGradientColors.first.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceVariant,
                      ),
                      child: Center(
                        child: Icon(
                          group.icon,
                          color: group.isUnseen
                              ? group.ringGradientColors.first
                              : AppColors.textSecondary,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  group.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: group.isUnseen ? FontWeight.w800 : FontWeight.w600,
                    color: group.isUnseen ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
