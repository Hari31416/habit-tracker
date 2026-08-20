import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../di/providers.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/health/health_connect_models.dart';
import '../../../domain/models/health/health_metric_type.dart';
import '../common/habit_icon_registry.dart';
import '../common/haptics_helper.dart';

class HealthConnectSettingsBottomSheet extends ConsumerStatefulWidget {
  const HealthConnectSettingsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HealthConnectSettingsBottomSheet(),
    );
  }

  @override
  ConsumerState<HealthConnectSettingsBottomSheet> createState() =>
      _HealthConnectSettingsBottomSheetState();
}

class _HealthConnectSettingsBottomSheetState
    extends ConsumerState<HealthConnectSettingsBottomSheet> {
  HealthConnectStatus _status = HealthConnectStatus.available;
  bool _isLoading = true;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  final Map<HealthMetricType, bool> _permissionsMap = {};
  int _syncIntervalMinutes = 30;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    final repo = ref.read(healthConnectRepositoryProvider);

    final status = await repo.checkAvailability();
    final lastSync = await repo.getLastSyncTime();

    final perms = <HealthMetricType, bool>{};
    for (final metric in HealthMetricType.values) {
      perms[metric] = await repo.hasPermissions([metric]);
    }

    if (mounted) {
      setState(() {
        _status = status;
        _lastSyncTime = lastSync;
        _permissionsMap.addAll(perms);
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    HapticsHelper.performLightHaptic();
    final repo = ref.read(healthConnectRepositoryProvider);
    await repo.requestPermissions(HealthMetricType.values);
    await _loadStatus();
  }

  Future<void> _syncNow() async {
    HapticsHelper.performLightHaptic();
    setState(() => _isSyncing = true);

    final repo = ref.read(healthConnectRepositoryProvider);
    final summary = await repo.syncHabitsForDate();
    await _loadStatus();

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            summary.isSuccess
                ? 'Health sync complete: ${summary.habitsUpdated} updated (${summary.habitsCompleted} completed)'
                : 'Health sync failed: ${summary.errorMessage}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeHabitsAsync = ref.watch(activeHabitsStreamProvider);
    final linkedHabits = activeHabitsAsync.value
            ?.where((h) => h.healthSyncEnabled && h.healthMetric != null)
            .toList() ??
        [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Google Health Connect',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      // Status Card
                      _buildStatusCard(theme),
                      const SizedBox(height: 16),

                      // Permissions Section
                      Text(
                        'Metric Permissions',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...HealthMetricType.values.map((metric) {
                        final granted = _permissionsMap[metric] ?? false;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      HabitIconRegistry.getIcon(metric.iconKey),
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      metric.displayName,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: granted
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.errorContainer,
                                  label: Text(
                                    granted ? 'Granted' : 'Not Granted',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: granted
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.security, size: 18),
                        label: const Text('Grant / Update Permissions'),
                        onPressed: _requestPermissions,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Background Sync Schedule
                      Text(
                        'Background Sync (WorkManager)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 15, label: Text('15m')),
                          ButtonSegment(value: 30, label: Text('30m')),
                          ButtonSegment(value: 60, label: Text('1h')),
                          ButtonSegment(value: 0, label: Text('Off')),
                        ],
                        selected: {_syncIntervalMinutes},
                        onSelectionChanged: (val) async {
                          final selected = val.first;
                          setState(() => _syncIntervalMinutes = selected);
                          final repo = ref.read(healthConnectRepositoryProvider);
                          if (selected > 0) {
                            await repo.scheduleBackgroundSync(intervalMinutes: selected);
                          } else {
                            await repo.cancelBackgroundSync();
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Linked Habits
                      Text(
                        'Linked Habits (${linkedHabits.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (linkedHabits.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No habits currently linked to Health Connect. Edit a habit to enable auto-sync.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        ...linkedHabits.map((habit) => _buildLinkedHabitTile(theme, habit)),
                    ],
                  ),
          ),

          // Footer Sync Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync),
                label: Text(_isSyncing ? 'Syncing Health Data...' : 'Sync All Habits Now'),
                onPressed: _isSyncing ? null : _syncNow,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final isAvailable = _status == HealthConnectStatus.available;
    final isNotInstalled = _status == HealthConnectStatus.notInstalled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAvailable
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.warning_amber,
                color: isAvailable ? theme.colorScheme.primary : theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isAvailable
                    ? 'Health Connect Connected'
                    : (isNotInstalled
                        ? 'Health Connect Install Required'
                        : 'Health Connect Not Supported'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isAvailable
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _lastSyncTime != null
                ? 'Last synchronized: ${DateFormat('MMM d, h:mm a').format(_lastSyncTime!)}'
                : 'Zero-touch check-ins active when activity targets are reached.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (isNotInstalled) ...[
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: () {
                ref.read(healthConnectRepositoryProvider).openHealthConnectInstall();
              },
              child: const Text('Get Health Connect from Play Store'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLinkedHabitTile(ThemeData theme, Habit habit) {
    final metric = habit.healthMetric!;
    final targetStr = habit.targetValue != null
        ? (habit.targetValue! % 1.0 == 0.0
            ? habit.targetValue!.toInt().toString()
            : habit.targetValue!.toString())
        : '';
    final unitStr = habit.unit ?? metric.defaultUnit;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                HabitIconRegistry.getIcon(habit.icon ?? metric.iconKey),
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${metric.displayName} • Target: $targetStr $unitStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.sync, size: 20),
              tooltip: 'Sync this habit now',
              onPressed: _isSyncing ? null : _syncNow,
            ),
          ],
        ),
      ),
    );
  }
}
