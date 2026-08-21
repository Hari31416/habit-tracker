import 'package:flutter/material.dart';
import '../common/haptics_helper.dart';
import 'screen.dart';

enum BottomNavDestination {
  today(Screen.daily, 'Today', Icons.check_circle, Icons.check_circle_outline, 'nav_today'),
  week(Screen.matrix, 'Week', Icons.calendar_month, Icons.calendar_month_outlined, 'nav_week'),
  analytics(Screen.analytics, 'Analytics', Icons.insert_chart, Icons.insert_chart_outlined, 'nav_analytics'),
  mastery(Screen.badges, 'Mastery', Icons.emoji_events, Icons.emoji_events_outlined, 'nav_mastery');

  final String route;
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String semanticsId;

  const BottomNavDestination(
    this.route,
    this.label,
    this.selectedIcon,
    this.unselectedIcon,
    this.semanticsId,
  );
}

class HabitBottomNavigation extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onAddHabitClick;

  const HabitBottomNavigation({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.onAddHabitClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: Container(
        height: 64.0 + bottomInset,
        padding: EdgeInsets.only(
          left: 8.0,
          right: 8.0,
          bottom: bottomInset,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Today
            _NavIconItem(
              destination: BottomNavDestination.today,
              isSelected: currentRoute == BottomNavDestination.today.route,
              onClick: () {
                HapticsHelper.performLightHaptic();
                onNavigate(BottomNavDestination.today.route);
              },
            ),

            // 2. Week Matrix
            _NavIconItem(
              destination: BottomNavDestination.week,
              isSelected: currentRoute == BottomNavDestination.week.route,
              onClick: () {
                HapticsHelper.performLightHaptic();
                onNavigate(BottomNavDestination.week.route);
              },
            ),

            // 3. Center Elevated Plus (+) Button
            Expanded(
              flex: 12,
              child: Center(
                child: Semantics(
                  identifier: 'nav_add',
                  label: 'Add habit',
                  button: true,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Material(
                      color: theme.colorScheme.primary,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          HapticsHelper.performLightHaptic();
                          onAddHabitClick();
                        },
                        child: Icon(
                          Icons.add,
                          color: theme.colorScheme.onPrimary,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 4. Analytics
            _NavIconItem(
              destination: BottomNavDestination.analytics,
              isSelected: currentRoute == BottomNavDestination.analytics.route,
              onClick: () {
                HapticsHelper.performLightHaptic();
                onNavigate(BottomNavDestination.analytics.route);
              },
            ),

            // 5. Mastery & Badges
            _NavIconItem(
              destination: BottomNavDestination.mastery,
              isSelected: currentRoute == BottomNavDestination.mastery.route,
              onClick: () {
                HapticsHelper.performLightHaptic();
                onNavigate(BottomNavDestination.mastery.route);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIconItem extends StatelessWidget {
  final BottomNavDestination destination;
  final bool isSelected;
  final VoidCallback onClick;

  const _NavIconItem({
    required this.destination,
    required this.isSelected,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final unselectedColor =
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    return Expanded(
      flex: 10,
      child: Semantics(
        identifier: destination.semanticsId,
        label: destination.label,
        button: true,
        selected: isSelected,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onClick,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected
                      ? destination.selectedIcon
                      : destination.unselectedIcon,
                  size: 22,
                  color: isSelected ? primaryColor : unselectedColor,
                ),
                const SizedBox(height: 2),
                Text(
                  destination.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? primaryColor : unselectedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
