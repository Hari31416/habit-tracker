import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
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
import 'ui/detail/controllers/timer_state_holder.dart';
import 'ui/detail/focus_timer_screen.dart';
import 'ui/detail/habit_detail_screen.dart';
import 'ui/form/habit_form_bottom_sheet.dart';
import 'ui/navigation/main_navigation_shell.dart';
import 'ui/navigation/screen.dart';
import 'ui/routines/routine_player_screen.dart';
import 'ui/theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Register VM Service extension only in profile/debug modes (zero overhead in release mode)
  if (kProfileMode || kDebugMode) {
    _initFrameMetricsExtension();
  }

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
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
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
      await container.read(healthConnectRepositoryProvider).syncHabitsForDate();
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
  static const _widgetsChannel = MethodChannel('app.phial.habits/widgets');

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
        if (route == Screen.addHabit) {
          ref.read(activeNavigationTabProvider.notifier).state = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = appNavigatorKey.currentContext;
            if (ctx != null) {
              HabitFormBottomSheet.show(ctx);
            }
          });
        } else if (route != Screen.daily) {
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
      ref.read(healthConnectRepositoryProvider).syncHabitsForDate();
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
      if (route == Screen.addHabit) {
        ref.read(activeNavigationTabProvider.notifier).state = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = appNavigatorKey.currentContext;
          if (ctx != null) {
            HabitFormBottomSheet.show(ctx);
          }
        });
      } else if (route == Screen.daily) {
        ref.read(activeNavigationTabProvider.notifier).state = 0;
      } else if (route == Screen.matrix) {
        ref.read(activeNavigationTabProvider.notifier).state = 1;
      } else if (route == Screen.analytics) {
        ref.read(activeNavigationTabProvider.notifier).state = 2;
      } else if (route == Screen.badges) {
        ref.read(activeNavigationTabProvider.notifier).state = 3;
      } else {
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
      title: 'Phial',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: flutterThemeMode,
      initialRoute: Screen.daily,
      onGenerateRoute: (settings) {
        final route = Screen.fromUri(settings.name);

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

        if (route.startsWith('routine_player/')) {
          final routineId = route.replaceFirst('routine_player/', '');
          if (routineId.isNotEmpty) {
            return MaterialPageRoute(
              settings: settings,
              builder: (ctx) => RoutinePlayerScreen(
                routineId: routineId,
                onBack: () => Navigator.of(ctx).pop(),
              ),
            );
          }
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (ctx) => const MainNavigationShell(),
        );
      },
    );
  }
}

void _initFrameMetricsExtension() {
  final List<double> frameBuildTimes = [];
  final List<double> frameRasterTimes = [];
  final List<double> frameTotalTimes = [];

  WidgetsBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      frameBuildTimes.add(timing.buildDuration.inMicroseconds / 1000.0);
      frameRasterTimes.add(timing.rasterDuration.inMicroseconds / 1000.0);
      frameTotalTimes.add(timing.totalSpan.inMicroseconds / 1000.0);
      if (frameBuildTimes.length > 5000) {
        frameBuildTimes.removeRange(0, 1000);
        frameRasterTimes.removeRange(0, 1000);
        frameTotalTimes.removeRange(0, 1000);
      }
    }
  });

  developer.registerExtension('ext.habits.getFrameMetrics', (method, parameters) async {
    final reset = parameters['reset'] == 'true';
    final data = {
      'totalFrames': frameTotalTimes.length,
      'buildTimesMs': List<double>.from(frameBuildTimes),
      'rasterTimesMs': List<double>.from(frameRasterTimes),
      'totalTimesMs': List<double>.from(frameTotalTimes),
    };
    if (reset) {
      frameBuildTimes.clear();
      frameRasterTimes.clear();
      frameTotalTimes.clear();
    }
    return developer.ServiceExtensionResponse.result(jsonEncode(data));
  });
}


