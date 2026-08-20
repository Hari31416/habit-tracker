import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../../domain/gamification/gamification_models.dart';
import '../../../domain/gamification/player_title.dart';
import '../../common/previews/phial_previews.dart';
import '../../common/previews/preview_fixtures.dart';

class PlayerLevelHeaderBadge extends StatelessWidget {
  final PlayerProgression progression;
  final VoidCallback onClick;

  const PlayerLevelHeaderBadge({
    super.key,
    required this.progression,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
      elevation: 0,
      child: InkWell(
        onTap: onClick,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Level avatar + Title + Multiplier
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                        child: Center(
                          child: Text(
                            '${progression.level}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                progression.title.displayName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              if (progression.activeStreakMultiplier > 1.0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.tertiaryContainer
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.bolt,
                                        size: 11,
                                        color: theme.colorScheme.tertiary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${progression.activeStreakMultiplier}x XP',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme
                                              .onTertiaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${progression.totalXp} / ${progression.nextLevelTargetXp} XP',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Right: Badges count + arrow
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${progression.unlockedBadgesCount}/${progression.totalBadgesCount}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_right,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Thin linear progress bar along bottom
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: progression.progressFraction.clamp(0.0, 1.0),
                  ),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      color: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// Widget Previews
// ==========================================

@PhialMultiBrightnessPreview(name: 'Player Level Badge - Standard', group: 'Gamification')
Widget previewPlayerLevelBadgeStandard() {
  return PhialPreviewWrapper(
    child: PlayerLevelHeaderBadge(
      progression: PreviewFixtures.sampleProgression(
        level: 3,
        multiplier: 1.0,
        unlockedBadges: 4,
        totalBadges: 16,
        title: PlayerTitle.novice,
      ),
      onClick: () {},
    ),
  );
}

@Preview(name: 'Player Level Badge - Multiplier Active', group: 'Gamification')
Widget previewPlayerLevelBadgeMultiplier() {
  return PhialPreviewWrapper(
    child: PlayerLevelHeaderBadge(
      progression: PreviewFixtures.sampleProgression(
        level: 7,
        multiplier: 2.0,
        unlockedBadges: 12,
        totalBadges: 16,
        title: PlayerTitle.pathfinder,
      ),
      onClick: () {},
    ),
  );
}
