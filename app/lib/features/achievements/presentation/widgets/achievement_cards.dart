import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/achievement.dart';

/// Returns the background color for an achievement tier
Color getTierColor(AchievementTier tier) {
  switch (tier) {
    case AchievementTier.bronze:
      return Colors.brown.shade200;
    case AchievementTier.silver:
      return Colors.grey.shade300;
    case AchievementTier.gold:
      return Colors.amber.shade200;
    case AchievementTier.platinum:
      return Colors.blue.shade100;
  }
}

/// Summary card showing tier counts and total points for user achievements
class AchievementSummaryCard extends StatelessWidget {
  final List<UserAchievement> achievements;
  final List<AchievementProgress> inProgress;

  const AchievementSummaryCard({
    super.key,
    required this.achievements,
    required this.inProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bronze =
        achievements.where((a) => a.definition?.tier == AchievementTier.bronze).length;
    final silver =
        achievements.where((a) => a.definition?.tier == AchievementTier.silver).length;
    final gold =
        achievements.where((a) => a.definition?.tier == AchievementTier.gold).length;
    final platinum =
        achievements.where((a) => a.definition?.tier == AchievementTier.platinum).length;
    final totalPoints =
        achievements.fold<int>(0, (sum, a) => sum + a.pointsAwarded);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TierCount(tier: AchievementTier.bronze, count: bronze),
                _TierCount(tier: AchievementTier.silver, count: silver),
                _TierCount(tier: AchievementTier.gold, count: gold),
                _TierCount(tier: AchievementTier.platinum, count: platinum),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Totalt oppnadd: ${achievements.length}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '+$totalPoints poeng',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (inProgress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${inProgress.length} i gang',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TierCount extends StatelessWidget {
  final AchievementTier tier;
  final int count;

  const _TierCount({required this.tier, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(tier.emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Card showing achievement progress with a linear progress bar
class AchievementProgressCard extends StatelessWidget {
  final AchievementProgress progress;

  const AchievementProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = progress.definition;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  def?.icon ?? '🎯',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def?.name ?? 'Prestasjon',
                        style: theme.textTheme.titleSmall,
                      ),
                      if (def?.description != null)
                        Text(
                          def!.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${progress.currentValue}/${progress.targetValue ?? "?"}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.progressPercent / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying an earned user achievement
class EarnedAchievementCard extends StatelessWidget {
  final UserAchievement achievement;

  const EarnedAchievementCard({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = achievement.definition;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: getTierColor(def?.tier ?? AchievementTier.bronze),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              def?.icon ?? def?.tier.emoji ?? '🏆',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(def?.name ?? 'Prestasjon'),
        subtitle: Text(
          'Oppnadd ${_formatDate(achievement.awardedAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: achievement.pointsAwarded > 0
            ? Chip(
                label: Text('+${achievement.pointsAwarded}'),
                backgroundColor: theme.colorScheme.primaryContainer,
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Card displaying an achievement definition (available/locked)
class AchievementDefinitionCard extends StatelessWidget {
  final AchievementDefinition definition;
  final bool isEarned;

  const AchievementDefinitionCard({
    super.key,
    required this.definition,
    required this.isEarned,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isEarned
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isEarned ? Colors.grey.shade300 : getTierColor(definition.tier),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              definition.isSecret && !isEarned ? '?' : (definition.icon ?? definition.tier.emoji),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          definition.isSecret && !isEarned ? 'Hemmelig prestasjon' : definition.name,
          style: TextStyle(
            color: isEarned ? theme.colorScheme.outline : null,
          ),
        ),
        subtitle: definition.isSecret && !isEarned
            ? null
            : Text(
                definition.description ?? definition.category.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: isEarned
            ? Icon(Icons.check_circle, color: Colors.green.shade400)
            : definition.bonusPoints > 0
                ? Chip(label: Text('+${definition.bonusPoints}'))
                : null,
      ),
    );
  }
}

/// Card displaying a team member's achievement in the team feed
class TeamAchievementCard extends StatelessWidget {
  final UserAchievement achievement;

  const TeamAchievementCard({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = achievement.definition;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: achievement.userAvatarUrl != null
              ? CachedNetworkImageProvider(achievement.userAvatarUrl!)
              : null,
          child: achievement.userAvatarUrl == null && achievement.userName != null
              ? Text(achievement.userName!.substring(0, 1).toUpperCase())
              : null,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                achievement.userName ?? 'Bruker',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              def?.icon ?? '🏆',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        subtitle: Text(
          '${def?.name ?? "Prestasjon"} - ${_formatDate(achievement.awardedAt)}',
        ),
        trailing: achievement.pointsAwarded > 0
            ? Text(
                '+${achievement.pointsAwarded}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'I dag';
    } else if (diff.inDays == 1) {
      return 'I gar';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} dager siden';
    } else {
      return '${date.day}.${date.month}';
    }
  }
}
