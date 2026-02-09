import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/achievement.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../achievements/providers/achievement_provider.dart';

class PlayerProfileAchievementsSection extends ConsumerWidget {
  final String teamId;
  final String userId;

  const PlayerProfileAchievementsSection({
    super.key,
    required this.teamId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(
      userAchievementsProvider((userId: userId, teamId: teamId, seasonId: null)),
    );
    final progressAsync = ref.watch(
      userProgressProvider((userId: userId, teamId: teamId, seasonId: null)),
    );
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Earned achievements
                achievementsAsync.when2(
                  onRetry: () => ref.invalidate(
                    userAchievementsProvider((userId: userId, teamId: teamId, seasonId: null)),
                  ),
                  data: (achievements) {
                    if (achievements.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: EmptyStateWidget(
                          icon: Icons.emoji_events_outlined,
                          title: 'Ingen achievements',
                          subtitle: 'Ingen achievements å vise ennå',
                        ),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: achievements.take(6).map((achievement) {
                        return AchievementBadge(achievement: achievement);
                      }).toList(),
                    );
                  },
                ),

                // In-progress achievements
                progressAsync.when2(
                  onRetry: () => ref.invalidate(
                    userProgressProvider((userId: userId, teamId: teamId, seasonId: null)),
                  ),
                  loading: () => const SizedBox.shrink(),
                  data: (progress) {
                    final inProgress = progress.where((p) => p.percentComplete < 100).take(3).toList();
                    if (inProgress.isEmpty) return const SizedBox.shrink();

                    return Column(
                      children: [
                        const Divider(height: 24),
                        Text(
                          'Under arbeid',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        ...inProgress.map((p) => ProgressMini(progress: p)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AchievementBadge extends StatelessWidget {
  final UserAchievement achievement;

  const AchievementBadge({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: achievement.achievementName ?? '',
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _getTierColor(achievement.tier).withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: _getTierColor(achievement.tier),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            achievement.icon ?? _getTierEmoji(achievement.tier),
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Color _getTierColor(AchievementTier? tier) {
    switch (tier) {
      case AchievementTier.platinum:
        return Colors.cyan;
      case AchievementTier.gold:
        return Colors.amber;
      case AchievementTier.silver:
        return Colors.grey.shade400;
      case AchievementTier.bronze:
      default:
        return Colors.brown.shade300;
    }
  }

  String _getTierEmoji(AchievementTier? tier) {
    switch (tier) {
      case AchievementTier.platinum:
        return '\u{1F4A0}';
      case AchievementTier.gold:
        return '\u{1F3C6}';
      case AchievementTier.silver:
        return '\u{1F948}';
      case AchievementTier.bronze:
      default:
        return '\u{1F949}';
    }
  }
}

class ProgressMini extends StatelessWidget {
  final AchievementProgress progress;

  const ProgressMini({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              progress.icon ?? '\u{1F3AF}',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.achievementName ?? '',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: progress.percentComplete / 100,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${progress.currentValue}/${progress.targetValue}',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
