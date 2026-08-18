import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/preferences/theme_preferences.dart';
import '../../domain/gamification/gamification_models.dart';
import '../common/color_utils.dart';
import '../common/haptics_helper.dart';
import '../common/theme_toggle_button.dart';
import '../form/habit_form_bottom_sheet.dart';
import '../navigation/habit_bottom_navigation.dart';
import '../navigation/screen.dart';
import 'controllers/gamification_controller.dart';
import 'dialogs/level_up_celebration_dialog.dart';

class BadgesShowcaseScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToDaily;
  final VoidCallback? onNavigateToMatrix;
  final VoidCallback? onNavigateToAnalytics;

  const BadgesShowcaseScreen({
    super.key,
    this.onNavigateToDaily,
    this.onNavigateToMatrix,
    this.onNavigateToAnalytics,
  });

  @override
  ConsumerState<BadgesShowcaseScreen> createState() =>
      _BadgesShowcaseScreenState();
}

class _BadgesShowcaseScreenState extends ConsumerState<BadgesShowcaseScreen> {
  bool _showAddForm = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uiState = ref.watch(gamificationControllerProvider);
    final controller = ref.read(gamificationControllerProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      bottomNavigationBar: HabitBottomNavigation(
        currentRoute: Screen.badges,
        onNavigate: (route) {
          if (route == Screen.daily) {
            widget.onNavigateToDaily?.call();
          } else if (route == Screen.matrix) {
            widget.onNavigateToMatrix?.call();
          } else if (route == Screen.analytics) {
            widget.onNavigateToAnalytics?.call();
          } else if (route == Screen.badges) {
            // Already here
          }
        },
        onAddHabitClick: () {
          setState(() {
            _showAddForm = true;
          });
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top App Bar
                Material(
                  color: theme.colorScheme.surface,
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mastery & Badges',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        ThemeToggleButton(
                          currentTheme: themeMode,
                          onThemeSelected: (mode) {
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(mode);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: uiState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Hero Progression Card
                              _buildHeroProgressionCard(
                                context,
                                uiState.progression,
                              ),

                              const SizedBox(height: 12),

                              // 2. Streak Multipliers Info Card
                              _buildStreakMultiplierInfoCard(
                                context,
                                uiState.progression,
                              ),

                              const SizedBox(height: 14),

                              // 3. Category Filter Chips
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: AchievementCategory.values.map(
                                    (category) {
                                      final isSelected =
                                          uiState.selectedCategory == category;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: FilterChip(
                                          selected: isSelected,
                                          showCheckmark: false,
                                          label: Text(category.displayName),
                                          onSelected: (selected) {
                                            HapticsHelper.performLightHaptic();
                                            controller.selectCategory(category);
                                          },
                                        ),
                                      );
                                    },
                                  ).toList(),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // 4. Badges Section Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'All Achievements',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${uiState.filteredAchievements.where((a) => a.isUnlocked).length} / ${uiState.filteredAchievements.length} Unlocked',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // 5. Achievement Items
                              ...uiState.filteredAchievements.map((achievement) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: _buildAchievementBadgeCard(
                                    context,
                                    achievement,
                                  ),
                                );
                              }),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                ),
              ],
            ),

            // Level Up Celebration Dialog
            if (uiState.pendingCelebration != null)
              LevelUpCelebrationDialog(
                celebration: uiState.pendingCelebration!,
                onDismiss: () {
                  controller.dismissCelebration(
                    uiState.pendingCelebration!.newLevel,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroProgressionCard(
    BuildContext context,
    PlayerProgression progression,
  ) {
    final theme = Theme.of(context);
    final currentXp =
        (progression.totalXp - progression.currentLevelBaseXp).clamp(0, 999999);
    final neededXp =
        (progression.nextLevelTargetXp - progression.currentLevelBaseXp)
            .clamp(1, 999999);
    final remainingXp = (neededXp - currentXp).clamp(0, 999999);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      color: theme.colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Lv.${progression.level}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progression.title.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Total XP: ${progression.totalXp}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 16,
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
              ],
            ),

            const SizedBox(height: 14),

            // XP Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentXp / $neededXp XP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Level ${progression.level + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: progression.progressFraction.clamp(0.0, 1.0),
                ),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    color: theme.colorScheme.primary,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$remainingXp XP to Level ${progression.level + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakMultiplierInfoCard(
    BuildContext context,
    PlayerProgression progression,
  ) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      color: theme.colorScheme.surface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.bolt,
                    size: 24,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streak Multiplier',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '7d: 1.25x - 14d: 1.5x - 30d+: 2.0x',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${progression.activeStreakMultiplier}x Active',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadgeCard(
    BuildContext context,
    AchievementStatus achievement,
  ) {
    final theme = Theme.of(context);
    final def = achievement.definition;
    final isUnlocked = achievement.isUnlocked;
    final tierColor = ColorUtils.parseHexColor(def.tier.hexColor);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isUnlocked
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      color: isUnlocked
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Lock / Unlock icon in square badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      isUnlocked ? Icons.check : Icons.lock,
                      size: 20,
                      color: isUnlocked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            def.tier.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tierColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+${def.xpReward} XP',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              def.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 10),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${achievement.currentProgress} / ${def.targetValue}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isUnlocked)
                  Text(
                    'Unlocked',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: achievement.progressFraction.clamp(0.0, 1.0),
                minHeight: 6,
                color: isUnlocked
                    ? theme.colorScheme.primary
                    : theme.colorScheme.tertiary,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
