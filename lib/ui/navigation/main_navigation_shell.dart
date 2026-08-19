import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/habit_analytics_screen.dart';
import '../daily/daily_tracker_screen.dart';
import '../gamification/badges_showcase_screen.dart';
import '../matrix/habit_week_matrix_screen.dart';
import 'screen.dart';

/// State provider for the root active bottom navigation tab.
/// 0: Today (Daily Tracker)
/// 1: Week (Week Matrix)
/// 2: Analytics (Habit Analytics)
/// 3: Mastery (Badges Showcase)
final activeNavigationTabProvider = StateProvider<int>((ref) => 0);

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(activeNavigationTabProvider);

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != 0) {
          ref.read(activeNavigationTabProvider.notifier).state = 0;
        }
      },
      child: IndexedStack(
        index: currentIndex,
        children: [
          DailyTrackerScreen(
            onNavigateToDetail: (habitId) {
              Navigator.of(context).pushNamed(Screen.detailRoute(habitId));
            },
            onNavigateToMatrix: () {
              ref.read(activeNavigationTabProvider.notifier).state = 1;
            },
            onNavigateToAnalytics: () {
              ref.read(activeNavigationTabProvider.notifier).state = 2;
            },
            onNavigateToBadges: () {
              ref.read(activeNavigationTabProvider.notifier).state = 3;
            },
          ),
          HabitWeekMatrixScreen(
            onNavigateToDaily: () {
              ref.read(activeNavigationTabProvider.notifier).state = 0;
            },
            onNavigateToAnalytics: () {
              ref.read(activeNavigationTabProvider.notifier).state = 2;
            },
            onNavigateToBadges: () {
              ref.read(activeNavigationTabProvider.notifier).state = 3;
            },
            onNavigateToDetail: (habitId) {
              Navigator.of(context).pushNamed(Screen.detailRoute(habitId));
            },
          ),
          HabitAnalyticsScreen(
            onNavigateToDaily: () {
              ref.read(activeNavigationTabProvider.notifier).state = 0;
            },
            onNavigateToMatrix: () {
              ref.read(activeNavigationTabProvider.notifier).state = 1;
            },
            onNavigateToBadges: () {
              ref.read(activeNavigationTabProvider.notifier).state = 3;
            },
            onNavigateToDetail: (habitId) {
              Navigator.of(context).pushNamed(Screen.detailRoute(habitId));
            },
          ),
          BadgesShowcaseScreen(
            onNavigateToDaily: () {
              ref.read(activeNavigationTabProvider.notifier).state = 0;
            },
            onNavigateToMatrix: () {
              ref.read(activeNavigationTabProvider.notifier).state = 1;
            },
            onNavigateToAnalytics: () {
              ref.read(activeNavigationTabProvider.notifier).state = 2;
            },
          ),
        ],
      ),
    );
  }
}
