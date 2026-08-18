import 'package:flutter/material.dart';
import '../../data/preferences/theme_mode.dart';
import 'haptics_helper.dart';

class ThemeToggleButton extends StatelessWidget {
  final AppThemeMode currentTheme;
  final ValueChanged<AppThemeMode> onThemeSelected;

  const ThemeToggleButton({
    super.key,
    required this.currentTheme,
    required this.onThemeSelected,
  });

  IconData _getIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<AppThemeMode>(
      tooltip: 'Theme: ${currentTheme.displayName}',
      icon: Icon(
        _getIcon(currentTheme),
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onSelected: (mode) {
        HapticsHelper.performLightHaptic();
        onThemeSelected(mode);
      },
      itemBuilder: (context) {
        return AppThemeMode.values.map((mode) {
          final isSelected = mode == currentTheme;
          return PopupMenuItem<AppThemeMode>(
            value: mode,
            child: Row(
              children: [
                Icon(
                  _getIcon(mode),
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  mode.displayName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
