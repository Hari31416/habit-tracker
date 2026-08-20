import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/repositories/backup_repository_impl.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/schedulers/no_op_habit_reminder_scheduler.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/data/preferences/theme_mode.dart';
import 'package:habit_tracker/data/preferences/theme_preferences.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/repositories/backup_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late HabitRepositoryImpl habitRepository;
  late BackupRepositoryImpl backupRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    habitRepository = HabitRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
    );
    backupRepository = BackupRepositoryImpl(
      db: db,
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('exportBackupJson exports valid versioned JSON envelope', () async {
    final now = DateTime.utc(2026, 8, 20, 10, 0, 0);
    await habitRepository.upsertCategory(
      HabitCategory(
        id: 'cat_test',
        name: 'Productivity',
        color: '#F59E0B',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await habitRepository.upsertHabit(
      Habit(
        id: 'h_deep_work',
        title: 'Deep Work',
        color: '#3B82F6',
        categoryId: 'cat_test',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await habitRepository.logCheckIn(
      habitId: 'h_deep_work',
      date: DateTime.utc(2026, 8, 20),
      completed: true,
      note: 'Solid session',
    );

    final jsonStr = await backupRepository.exportBackupJson(deviceId: 'test_device');
    expect(jsonStr, isNotEmpty);

    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    expect(decoded['schemaVersion'], 1);
    expect(decoded['deviceId'], 'test_device');
    expect(decoded['data']['habits'], isNotEmpty);
    expect(decoded['data']['logs'], isNotEmpty);
  });

  test('previewImport calculates diff stats accurately', () async {
    final now = DateTime.utc(2026, 8, 20, 10, 0, 0);
    final backupJson = jsonEncode({
      'schemaVersion': 1,
      'appVersion': '0.8.1',
      'exportedAt': now.toIso8601String(),
      'deviceId': 'remote_phone',
      'data': {
        'categories': [
          {
            'id': 'cat_remote',
            'name': 'Fitness',
            'color': '#10B981',
            'isDeleted': false,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }
        ],
        'habits': [
          {
            'id': 'h_run',
            'title': 'Daily Run',
            'color': '#10B981',
            'categoryId': 'cat_remote',
            'frequencyType': 'daily',
            'targetType': 'boolean',
            'isDeleted': false,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }
        ],
        'logs': [
          {
            'id': 'log_run_1',
            'habitId': 'h_run',
            'date': '2026-08-20',
            'timestamp': now.toIso8601String(),
            'completed': true,
            'isDeleted': false,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }
        ],
        'shields': [],
        'gamification': {'totalXp': 20, 'currentLevel': 1},
        'achievements': [],
      }
    });

    final preview = await backupRepository.previewImport(backupJson);
    expect(preview.stats.habitsAdded, 1);
    expect(preview.stats.categoriesAdded, 1);
    expect(preview.stats.logsMerged, 1);
  });

  test('executeImport in merge mode applies updates without wiping existing habits', () async {
    final now = DateTime.utc(2026, 8, 20, 10, 0, 0);

    // Existing local habit
    await habitRepository.upsertHabit(
      Habit(
        id: 'h_local',
        title: 'Local Habit',
        color: '#3B82F6',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final incomingJson = jsonEncode({
      'schemaVersion': 1,
      'appVersion': '0.8.1',
      'exportedAt': now.toIso8601String(),
      'deviceId': 'remote_phone',
      'data': {
        'habits': [
          {
            'id': 'h_incoming',
            'title': 'Incoming Habit',
            'color': '#10B981',
            'frequencyType': 'daily',
            'targetType': 'boolean',
            'isDeleted': false,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }
        ],
        'logs': [],
        'shields': [],
        'categories': [],
        'gamification': {'totalXp': 0, 'currentLevel': 1},
        'achievements': [],
      }
    });

    await backupRepository.executeImport(incomingJson, mode: ImportMode.merge);

    final activeHabits = await habitRepository.getActiveHabits().first;
    expect(activeHabits.map((h) => h.id), containsAll(['h_local', 'h_incoming']));
  });

  test('executeImport in overwrite mode replaces entire database state', () async {
    final now = DateTime.utc(2026, 8, 20, 10, 0, 0);

    // Existing local habit
    await habitRepository.upsertHabit(
      Habit(
        id: 'h_old_to_wipe',
        title: 'Old Habit',
        color: '#3B82F6',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final snapshotJson = jsonEncode({
      'schemaVersion': 1,
      'appVersion': '0.8.1',
      'exportedAt': now.toIso8601String(),
      'deviceId': 'backup_vault',
      'data': {
        'habits': [
          {
            'id': 'h_restored',
            'title': 'Restored Habit',
            'color': '#EC4899',
            'frequencyType': 'daily',
            'targetType': 'boolean',
            'isDeleted': false,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }
        ],
        'logs': [],
        'shields': [],
        'categories': [],
        'gamification': {'totalXp': 100, 'currentLevel': 2},
        'achievements': [],
      }
    });

    await backupRepository.executeImport(snapshotJson, mode: ImportMode.overwrite);

    final activeHabits = await habitRepository.getActiveHabits().first;
    expect(activeHabits.length, 1);
    expect(activeHabits.first.id, 'h_restored');
  });

  test('exportHabitsCsv and exportLogsCsv produce valid CSV headers and data', () async {
    final now = DateTime.utc(2026, 8, 20, 10, 0, 0);

    await habitRepository.upsertHabit(
      Habit(
        id: 'h_csv_test',
        title: 'Read "Atomic Habits"',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.numeric,
        targetValue: 20.0,
        unit: 'pages',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await habitRepository.logCheckIn(
      habitId: 'h_csv_test',
      date: DateTime.utc(2026, 8, 20),
      completed: true,
      value: 20.0,
      note: 'Chapter 1 & 2',
    );

    final habitsCsv = await backupRepository.exportHabitsCsv();
    expect(habitsCsv, contains('id,title,category,frequency,targetType,targetValue,unit,pinned,archived,createdAt'));
    expect(habitsCsv, contains('"Read ""Atomic Habits"""'));

    final logsCsv = await backupRepository.exportLogsCsv();
    expect(logsCsv, contains('id,habitId,habitTitle,date,timestamp,intervalIndex,completed,value,durationSeconds,energyLevel,mood,note'));
    expect(logsCsv, contains('"Chapter 1 & 2"'));
  });

  test('export and import preserves user preferences (name, theme, DND, sound)', () async {
    SharedPreferences.setMockInitialValues({
      ThemePreferences.keyUserName: 'Alex Rider',
      ThemePreferences.keyThemeMode: 'dark',
      ThemePreferences.keyFocusDndEnabled: true,
      ThemePreferences.keyAmbientSoundType: 'rain',
      ThemePreferences.keyAmbientSoundVolume: 0.85,
    });
    final prefs = await SharedPreferences.getInstance();
    final themePrefs = ThemePreferences(prefs);

    final repoWithPrefs = BackupRepositoryImpl(
      db: db,
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
      themePreferences: themePrefs,
    );

    final exportedJson = await repoWithPrefs.exportBackupJson();
    final decoded = jsonDecode(exportedJson);
    expect(decoded['data']['preferences']['userName'], 'Alex Rider');
    expect(decoded['data']['preferences']['themeMode'], 'dark');
    expect(decoded['data']['preferences']['focusDndEnabled'], true);
    expect(decoded['data']['preferences']['ambientSoundType'], 'rain');
    expect(decoded['data']['preferences']['ambientSoundVolume'], 0.85);

    // Wipe local preferences
    await themePrefs.setUserName('Temporary');
    await themePrefs.setThemeMode(AppThemeMode.light);

    // Restore via overwrite
    await repoWithPrefs.executeImport(exportedJson, mode: ImportMode.overwrite);
    expect(themePrefs.loadUserName(), 'Alex Rider');
    expect(themePrefs.loadThemeMode(), AppThemeMode.dark);
    expect(themePrefs.loadFocusDndEnabled(), true);
  });
}
