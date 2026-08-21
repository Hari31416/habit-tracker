import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_shield.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/habit_tier.dart';
import 'package:habit_tracker/domain/models/health/health_metric_type.dart';
import 'package:habit_tracker/domain/models/sync/sync_envelope.dart';
import 'package:habit_tracker/domain/models/time_window.dart';

/// Fixed clock for contract export *goldens*.
final DateTime kContractClock = DateTime.utc(2026, 4, 11, 9, 15, 30);

final DateTime kContractCreatedAt = DateTime.utc(2026, 3, 15, 14, 30, 0);
final DateTime kContractUpdatedAt = DateTime.utc(2026, 3, 16, 8, 5, 0);
final DateTime kContractLogTimestamp = DateTime.utc(2026, 3, 20, 7, 45, 12);
final DateTime kContractAchievementUnlockedAt =
    DateTime.utc(2026, 3, 21, 11, 0, 0);

const String kContractDeviceId = 'contract_device_alpha';

/// Distinctive SharedPreferences for envelope `preferences`.
const Map<String, Object> kContractPreferenceSeed = {
  'key_user_name': 'ContractUser',
  'key_theme_mode': 'dark',
  'key_focus_dnd_enabled': true,
  'key_ambient_sound_type': 'rain',
  'key_ambient_sound_volume': 0.42,
};

const List<String> kHabitJsonKeys = [
  'id',
  'title',
  'description',
  'color',
  'icon',
  'categoryId',
  'frequencyType',
  'targetDaysOfWeek',
  'targetCountPerWeek',
  'intervalHours',
  'timesPerDay',
  'timeWindow',
  'targetType',
  'targetValue',
  'miniTargetValue',
  'eliteTargetValue',
  'unit',
  'pinned',
  'reminderTimes',
  'motivationNotes',
  'archived',
  'promptReflection',
  'healthMetric',
  'healthSyncEnabled',
  'isDeleted',
  'createdAt',
  'updatedAt',
];

const List<String> kLogJsonKeys = [
  'id',
  'habitId',
  'date',
  'timestamp',
  'intervalIndex',
  'completed',
  'value',
  'durationSeconds',
  'targetTier',
  'note',
  'energyLevel',
  'mood',
  'isDeleted',
  'createdAt',
  'updatedAt',
];

const List<String> kCategoryJsonKeys = [
  'id',
  'name',
  'color',
  'icon',
  'isDeleted',
  'createdAt',
  'updatedAt',
];

const List<String> kShieldJsonKeys = [
  'id',
  'habitId',
  'date',
  'autoApplied',
  'isDeleted',
  'createdAt',
  'updatedAt',
];

const List<String> kAchievementJsonKeys = [
  'id',
  'unlockedAt',
  'progress',
  'notified',
  'createdAt',
  'updatedAt',
];

const List<String> kGamificationJsonKeys = [
  'totalXp',
  'currentLevel',
  'lastCelebratedLevel',
  'maxShieldsCapacity',
  'autoConsumeShields',
  'updatedAt',
];

class ContractFixtures {
  static const String habitId = 'habit_contract_full';
  static const String categoryId = 'cat_contract_health';
  static const String logId = 'log_contract_full';
  static const String shieldId = 'shield_contract_full';

  /// Real definition id so merge can keep `notified`.
  static const String achievementId = 'vol_1';

  static HabitCategory category() => HabitCategory(
        id: categoryId,
        name: 'Contract Health',
        color: '#C45C26',
        icon: 'heartbeat',
        isDeleted: false,
        createdAt: kContractCreatedAt,
        updatedAt: kContractUpdatedAt,
      );

  static Habit habit() => Habit(
        id: habitId,
        title: 'Contract Walk',
        description: 'Distinctive contract description',
        color: '#1B4D89',
        icon: 'footprints',
        categoryId: categoryId,
        frequencyType: HabitFrequencyType.customDays,
        targetDaysOfWeek: const [1, 3, 5],
        targetCountPerWeek: 4,
        intervalHours: 6,
        timesPerDay: 3,
        timeWindow: const TimeWindow(startTime: '06:15', endTime: '21:45'),
        targetType: HabitTargetType.numeric,
        targetValue: 8000.0,
        miniTargetValue: 2500.5,
        eliteTargetValue: 12000.25,
        unit: 'steps',
        pinned: true,
        reminderTimes: const ['06:30', '12:15'],
        motivationNotes: 'Keep the chain for the contract test',
        archived: false,
        promptReflection: true,
        healthMetric: HealthMetricType.steps,
        healthSyncEnabled: true,
        isDeleted: false,
        createdAt: kContractCreatedAt,
        updatedAt: kContractUpdatedAt,
      );

  static HabitLog log() => HabitLog(
        id: logId,
        habitId: habitId,
        date: '2026-03-20',
        timestamp: kContractLogTimestamp,
        intervalIndex: 2,
        completed: true,
        value: 9100.75,
        durationSeconds: 1840,
        targetTier: HabitTier.elite,
        note: 'Contract log note',
        energyLevel: 4,
        mood: 'focused',
        isDeleted: false,
        createdAt: kContractCreatedAt,
        updatedAt: kContractUpdatedAt,
      );

  static HabitShield shield() => HabitShield(
        id: shieldId,
        habitId: habitId,
        date: '2026-03-19',
        autoApplied: true,
        isDeleted: false,
        createdAt: kContractCreatedAt,
        updatedAt: kContractUpdatedAt,
      );

  static SyncAchievement achievement() => SyncAchievement(
        id: achievementId,
        unlockedAt: kContractAchievementUnlockedAt,
        progress: 1,
        notified: true,
        createdAt: kContractCreatedAt,
        updatedAt: kContractUpdatedAt,
      );

  static const int lastCelebratedLevel = 4;
  static const int maxShieldsCapacity = 7;
  static const bool autoConsumeShields = false;
}
