import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/preferences/theme_preferences.dart';
import '../../di/providers.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/sync/sync_merge_engine.dart';
import '../common/haptics_helper.dart';

class BackupSettingsBottomSheet extends ConsumerStatefulWidget {
  const BackupSettingsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BackupSettingsBottomSheet(),
    );
  }

  @override
  ConsumerState<BackupSettingsBottomSheet> createState() =>
      _BackupSettingsBottomSheetState();
}

class _BackupSettingsBottomSheetState
    extends ConsumerState<BackupSettingsBottomSheet> {
  bool _isLoading = false;
  String? _statusMessage;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _handleExportJson() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Generating JSON backup...';
    });

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    final service = ref.read(backupServiceProvider);
    final success = await service.exportAndShareBackupJson(sharePositionOrigin: origin);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      if (success) {
        HapticsHelper.performLightHaptic();
        _showSuccess('Backup exported successfully');
      } else {
        _showError('Failed to export backup');
      }
    }
  }

  Future<void> _handleExportCsv() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Exporting CSV data...';
    });

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    final service = ref.read(backupServiceProvider);
    final success = await service.exportAndShareCsv(sharePositionOrigin: origin);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      if (success) {
        HapticsHelper.performLightHaptic();
        _showSuccess('CSV data exported successfully');
      } else {
        _showError('Failed to export CSV');
      }
    }
  }

  Future<void> _handleImportJson() async {
    final service = ref.read(backupServiceProvider);
    final jsonString = await service.pickBackupFile();

    if (jsonString == null || jsonString.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Analyzing backup file...';
    });

    try {
      final preview = await service.previewImport(jsonString);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });

      _showImportConfirmationDialog(jsonString, preview);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
        _showError('Invalid or corrupted backup file');
      }
    }
  }

  void _showImportConfirmationDialog(
    String jsonString,
    MergeResult preview,
  ) {
    final theme = Theme.of(context);
    final stats = preview.stats;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Import Backup'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup Contents:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        Icons.check_circle_outline,
                        'Habits Added/Updated',
                        '+${stats.habitsAdded} added, ${stats.habitsUpdated} updated',
                        theme,
                      ),
                      const SizedBox(height: 6),
                      _buildSummaryRow(
                        Icons.history,
                        'Logs Merged',
                        '${stats.logsMerged} entries',
                        theme,
                      ),
                      const SizedBox(height: 6),
                      _buildSummaryRow(
                        Icons.shield_outlined,
                        'Shields Merged',
                        '${stats.shieldsMerged} shields',
                        theme,
                      ),
                      const SizedBox(height: 6),
                      _buildSummaryRow(
                        Icons.star_outline,
                        'Progress After Merge',
                        'Level ${stats.level} (${NumberFormat.compact().format(stats.totalXp)} XP)',
                        theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select import mode:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _confirmCleanReplace(jsonString);
              },
              child: const Text('Clean Replace'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _executeImport(jsonString, ImportMode.merge);
              },
              child: const Text('Merge (Recommended)'),
            ),
          ],
        );
      },
    );
  }

  void _confirmCleanReplace(String jsonString) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Replace Entire Database?',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          content: const Text(
            'This is a destructive disaster-recovery restore. It will delete all current habits, logs, and progression on this device and replace them with the backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _executeImport(jsonString, ImportMode.overwrite);
              },
              child: const Text('Wipe & Restore'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeImport(String jsonString, ImportMode mode) async {
    setState(() {
      _isLoading = true;
      _statusMessage = mode == ImportMode.merge
          ? 'Merging data...'
          : 'Restoring database snapshot...';
    });

    try {
      final service = ref.read(backupServiceProvider);
      final stats = await service.executeImport(jsonString, mode: mode);

      // Invalidate UI streams
      ref.invalidate(activeHabitsStreamProvider);
      ref.invalidate(allLogsStreamProvider);
      ref.invalidate(allShieldsStreamProvider);
      ref.invalidate(playerProgressionStreamProvider);
      ref.invalidate(achievementsStreamProvider);
      ref.invalidate(shieldBankStateStreamProvider);

      // Refresh preferences notifiers
      final prefs = ref.read(themePreferencesProvider);
      ref.read(userNameProvider.notifier).setUserName(prefs.loadUserName());
      ref.read(themeModeProvider.notifier).setThemeMode(prefs.loadThemeMode());
      ref.read(focusDndProvider.notifier).setFocusDndEnabled(prefs.loadFocusDndEnabled());

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
        HapticsHelper.performHeavyConfirmationHaptic();
        _showSuccess(
          mode == ImportMode.merge
              ? 'Import merged successfully (${stats.logsMerged} logs synced)'
              : 'Database restored successfully',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
        _showError('Failed to apply import: $e');
      }
    }
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sync_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data & Backup',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Local offline backups & data portability',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          if (_isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage ?? 'Processing...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Export Full Backup
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.upload_file_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 20,
                ),
              ),
              title: const Text(
                'Export Backup (JSON)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Complete snapshot of habits, logs, XP, and shields',
              ),
              trailing: const Icon(Icons.share_outlined),
              onTap: _handleExportJson,
            ),
            const SizedBox(height: 4),

            // Import Backup
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.download_outlined,
                  color: theme.colorScheme.onTertiaryContainer,
                  size: 20,
                ),
              ),
              title: const Text(
                'Import Backup (JSON)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Merge or restore data from a previous JSON backup',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _handleImportJson,
            ),
            const SizedBox(height: 4),

            // Export CSV
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.table_chart_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              title: const Text(
                'Export Spreadsheets (CSV)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Export habits.csv and habit_logs.csv for Excel or Sheets',
              ),
              trailing: const Icon(Icons.share_outlined),
              onTap: _handleExportCsv,
            ),
          ],
        ],
      ),
    ),
  );
}
}
