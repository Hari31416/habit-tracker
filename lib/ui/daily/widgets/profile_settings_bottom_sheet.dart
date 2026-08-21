import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/preferences/theme_mode.dart';
import '../../../data/preferences/theme_preferences.dart';
import '../../common/haptics_helper.dart';
import '../../gamification/dialogs/shield_bank_bottom_sheet.dart';
import '../../settings/backup_settings_bottom_sheet.dart';
import '../../settings/health_connect_settings_bottom_sheet.dart';

class ProfileSettingsBottomSheet extends ConsumerWidget {
  const ProfileSettingsBottomSheet({super.key});

  static void show(BuildContext context) {
    HapticsHelper.performLightHaptic();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ProfileSettingsBottomSheet(),
    );
  }

  static String getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good evening';
    } else {
      return 'Hello';
    }
  }

  static void showNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'What is your name?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(userNameProvider.notifier)
                    .setUserName(nameController.text);
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserName = ref.watch(userNameProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    currentUserName.isNotEmpty
                        ? currentUserName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUserName.isNotEmpty
                            ? currentUserName
                            : 'Set your name',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        getTimeGreeting(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit Name',
                  onPressed: () {
                    Navigator.of(context).pop();
                    showNameDialog(context, ref, currentUserName);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Appearance section
            Text(
              'Appearance',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(
                  value: AppThemeMode.system,
                  icon: Icon(Icons.brightness_auto, size: 18),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: AppThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: AppThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                  label: Text('Dark'),
                ),
              ],
              selected: {currentThemeMode},
              onSelectionChanged: (Set<AppThemeMode> newSelection) {
                HapticsHelper.performLightHaptic();
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(newSelection.first);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 14),

            // Streak Shield Bank Option
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 20,
                ),
              ),
              title: const Text(
                'Streak Shields Bank',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Manage streak freezes and protection'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                ShieldBankBottomSheet.show(context);
              },
            ),
            const SizedBox(height: 4),

            // Google Health Connect Option
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_outline,
                  color: theme.colorScheme.onTertiaryContainer,
                  size: 20,
                ),
              ),
              title: const Text(
                'Google Health Connect',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle:
                  const Text('Auto-sync steps, exercise, hydration & sleep'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                HealthConnectSettingsBottomSheet.show(context);
              },
            ),
            const SizedBox(height: 4),

            // Data & Backup Option
            Semantics(
              identifier: 'settings_data_backup',
              label: 'Data & Backup',
              button: true,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sync_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Data & Backup',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle:
                    const Text('Export, import, and spreadsheet sync'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  BackupSettingsBottomSheet.show(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
