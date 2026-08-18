import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/preferences/theme_mode.dart';
import 'data/preferences/theme_preferences.dart';
import 'ui/analytics/habit_analytics_screen.dart';
import 'ui/daily/daily_tracker_screen.dart';
import 'ui/detail/focus_timer_screen.dart';
import 'ui/detail/habit_detail_screen.dart';
import 'ui/gamification/badges_showcase_screen.dart';
import 'ui/matrix/habit_week_matrix_screen.dart';
import 'ui/navigation/screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HabitTrackerApp()));
}

class HabitTrackerApp extends ConsumerWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final ThemeMode flutterThemeMode;
    switch (themeMode) {
      case AppThemeMode.system:
        flutterThemeMode = ThemeMode.system;
        break;
      case AppThemeMode.light:
        flutterThemeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        flutterThemeMode = ThemeMode.dark;
        break;
    }

    return MaterialApp(
      title: 'Habit Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: flutterThemeMode,
      initialRoute: Screen.daily,
      onGenerateRoute: (settings) {
        final name = settings.name ?? Screen.daily;

        if (name == Screen.daily) {
          return MaterialPageRoute(
            builder: (ctx) => DailyTrackerScreen(
              onNavigateToDetail: (habitId) {
                Navigator.of(ctx).pushNamed(Screen.detailRoute(habitId));
              },
              onNavigateToMatrix: () {
                Navigator.of(ctx).pushReplacementNamed(Screen.matrix);
              },
              onNavigateToAnalytics: () {
                Navigator.of(ctx).pushReplacementNamed(Screen.analytics);
              },
              onNavigateToBadges: () {
                Navigator.of(ctx).pushReplacementNamed(Screen.badges);
              },
            ),
          );
        }

        if (name == Screen.matrix) {
          return MaterialPageRoute(
            builder: (ctx) => HabitWeekMatrixScreen(
              onNavigateToDaily: () {
                Navigator.of(ctx).pushReplacementNamed(Screen.daily);
              },
              onNavigateToAnalytics: () {
                Navigator.of(ctx).pushReplacementNamed(Screen.analytics);
              },
              onNavigateToBadges: () {
                Navigator.of(ctx).pushReplacementNamed(Screen.badges);
              },
              onNavigateToDetail: (habitId) {
                Navigator.of(ctx).pushNamed(Screen.detailRoute(habitId));
              },
            ),
          );
        }

        if (name == Screen.analytics) {
          return MaterialPageRoute(
            builder: (ctx) => HabitAnalyticsScreen(
              onNavigateToDaily: () {
                Navigator.of(ctx).pushReplacementNamed(Screen.daily);
              },
              onNavigateToMatrix: () {
                Navigator.of(ctx).pushReplacementNamed(Screen.matrix);
              },
              onNavigateToBadges: () {
                Navigator.of(ctx).pushReplacementNamed(Screen.badges);
              },
              onNavigateToDetail: (habitId) {
                Navigator.of(ctx).pushNamed(Screen.detailRoute(habitId));
              },
            ),
          );
        }

        if (name == Screen.badges) {
          return MaterialPageRoute(
            builder: (ctx) => BadgesShowcaseScreen(
              onNavigateToDaily: () {
                Navigator.of(ctx).pushReplacementNamed(Screen.daily);
              },
              onNavigateToMatrix: () {
                Navigator.of(ctx).pushReplacementNamed(Screen.matrix);
              },
              onNavigateToAnalytics: () {
                Navigator.of(ctx).pushReplacementNamed(Screen.analytics);
              },
            ),
          );
        }

        if (name.startsWith('detail/')) {
          final habitId = name.replaceFirst('detail/', '');
          return MaterialPageRoute(
            builder: (ctx) => HabitDetailScreen(
              habitId: habitId,
              onBack: () => Navigator.of(ctx).pop(),
              onNavigateToFocusScreen: (id) {
                Navigator.of(ctx).pushNamed(Screen.focusTimerRoute(id));
              },
            ),
          );
        }

        if (name.startsWith('focus_timer/')) {
          final habitId = name.replaceFirst('focus_timer/', '');
          return MaterialPageRoute(
            builder: (ctx) => FocusTimerScreen(
              habitId: habitId,
              onBack: () => Navigator.of(ctx).pop(),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (ctx) => DailyTrackerScreen(
            onNavigateToDetail: (habitId) {
              Navigator.of(ctx).pushNamed(Screen.detailRoute(habitId));
            },
            onNavigateToMatrix: () {
              Navigator.of(ctx).pushReplacementNamed(Screen.matrix);
            },
            onNavigateToAnalytics: () {
              Navigator.of(ctx).pushReplacementNamed(Screen.analytics);
            },
            onNavigateToBadges: () {
              Navigator.of(ctx).pushReplacementNamed(Screen.badges);
            },
          ),
        );
      },
    );
  }
}
