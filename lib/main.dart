import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'data/preferences/theme_mode.dart';
import 'data/preferences/theme_preferences.dart';
import 'di/providers.dart';
import 'services/notification_service.dart';
import 'ui/analytics/habit_analytics_screen.dart';
import 'ui/daily/daily_tracker_screen.dart';
import 'ui/detail/controllers/timer_state_holder.dart';
import 'ui/detail/focus_timer_screen.dart';
import 'ui/detail/habit_detail_screen.dart';
import 'ui/gamification/badges_showcase_screen.dart';
import 'ui/matrix/habit_week_matrix_screen.dart';
import 'ui/navigation/screen.dart';
import 'ui/theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  NotificationService.bindActionHandler(({
    required String action,
    required String habitId,
    double? delta,
  }) {
    return container.read(notificationActionHandlerProvider).handleAction(
          action: action,
          habitId: habitId,
          delta: delta,
        );
  });

  // Non-blocking background startup pipeline: timezones, notifications, widget sync, and reminder schedule
  Future.microtask(() async {
    try {
      tz_data.initializeTimeZones();
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback to default
    }

    try {
      await NotificationService.init();
      await NotificationService.requestPermission();
    } catch (_) {}

    try {
      await container.read(widgetSyncServiceProvider).consumePendingWidgetActions();
      await container.read(widgetSyncServiceProvider).syncAllWidgetsImmediate();
      await container.read(habitReminderSchedulerProvider).rescheduleAll();
    } catch (_) {}
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HabitTrackerApp(),
    ),
  );
}

class HabitTrackerApp extends ConsumerStatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  ConsumerState<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends ConsumerState<HabitTrackerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timerStateHolderProvider.notifier).syncFromNative();
      _handlePendingDeepLink();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(widgetSyncServiceProvider).consumePendingWidgetActions();
      ref.read(timerStateHolderProvider.notifier).syncFromNative();
      _handlePendingDeepLink();
    }
  }

  void _handlePendingDeepLink() {
    final deepLink = NotificationService.pendingDeepLink;
    if (deepLink != null) {
      NotificationService.pendingDeepLink = null;
      appNavigatorKey.currentState?.pushNamed(deepLink);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      navigatorKey: appNavigatorKey,
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
