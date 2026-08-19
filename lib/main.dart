import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'data/preferences/theme_mode.dart';
import 'data/preferences/theme_preferences.dart';
import 'di/providers.dart';
import 'services/app_logger.dart';
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

  // Non-blocking background startup pipeline: timezones, notifications, widget sync, reminder schedule, and day rollover
  Future.microtask(() async {
    try {
      tz_data.initializeTimeZones();
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e, stack) {
      AppLogger.w('Timezone initialization failed, using default timezone', error: e, stackTrace: stack);
    }

    try {
      await NotificationService.init();
    } catch (e, stack) {
      AppLogger.w('NotificationService initialization failed', error: e, stackTrace: stack);
    }

    try {
      await container.read(dayRolloverTaskProvider).executeRollover();
      await container.read(widgetSyncServiceProvider).consumePendingWidgetActions();
      await container.read(widgetSyncServiceProvider).syncAllWidgetsImmediate();
      await container.read(habitReminderSchedulerProvider).rescheduleAll();
    } catch (e, stack) {
      AppLogger.w('Background startup tasks encountered an error', error: e, stackTrace: stack);
    }
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
  static const _widgetsChannel = MethodChannel('com.productivity.habits/widgets');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _widgetsChannel.setMethodCallHandler(_handleNativeWidgetsCall);
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

  Future<void> _handleNativeWidgetsCall(MethodCall call) async {
    if (call.method == 'onDeepLink') {
      final uri = call.arguments as String?;
      if (uri != null && uri.isNotEmpty) {
        final route = Screen.fromUri(uri);
        if (route != Screen.daily) {
          appNavigatorKey.currentState?.pushNamed(route);
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(dayRolloverTaskProvider).executeRollover();
      ref.read(widgetSyncServiceProvider).consumePendingWidgetActions();
      ref.read(timerStateHolderProvider.notifier).syncFromNative();
      ref.read(habitReminderSchedulerProvider).rescheduleAll();
      _handlePendingDeepLink();
    }
  }

  Future<void> _handlePendingDeepLink() async {
    var deepLink = NotificationService.pendingDeepLink;
    NotificationService.pendingDeepLink = null;

    if (deepLink == null) {
      try {
        final initialUri = await _widgetsChannel.invokeMethod<String>('getInitialDeepLink');
        if (initialUri != null && initialUri.isNotEmpty) {
          deepLink = initialUri;
        }
      } catch (_) {}
    }

    if (deepLink != null) {
      final route = Screen.fromUri(deepLink);
      if (route != Screen.daily) {
        appNavigatorKey.currentState?.pushNamed(route);
      }
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
        final route = Screen.fromUri(settings.name);

        if (route == Screen.matrix) {
          return MaterialPageRoute(
            settings: settings,
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

        if (route == Screen.analytics) {
          return MaterialPageRoute(
            settings: settings,
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

        if (route == Screen.badges) {
          return MaterialPageRoute(
            settings: settings,
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

        if (route.startsWith('detail/')) {
          final habitId = route.replaceFirst('detail/', '');
          if (habitId.isNotEmpty) {
            return MaterialPageRoute(
              settings: settings,
              builder: (ctx) => HabitDetailScreen(
                habitId: habitId,
                onBack: () => Navigator.of(ctx).pop(),
                onNavigateToFocusScreen: (id) {
                  Navigator.of(ctx).pushNamed(Screen.focusTimerRoute(id));
                },
              ),
            );
          }
        }

        if (route.startsWith('focus_timer/')) {
          final habitId = route.replaceFirst('focus_timer/', '');
          if (habitId.isNotEmpty) {
            return MaterialPageRoute(
              settings: settings,
              builder: (ctx) => FocusTimerScreen(
                habitId: habitId,
                onBack: () => Navigator.of(ctx).pop(),
              ),
            );
          }
        }

        return MaterialPageRoute(
          settings: settings,
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
