import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/repositories/health_connect_repository_impl.dart';
import 'package:habit_tracker/domain/engines/health_sync_engine.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_shield.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/habit_tier.dart';
import 'package:habit_tracker/domain/models/health/health_connect_models.dart';
import 'package:habit_tracker/domain/models/health/health_metric_type.dart';
import 'package:habit_tracker/domain/repositories/habit_repository.dart';
import 'package:habit_tracker/services/health_connect_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeHealthConnectService extends HealthConnectService {
  HealthConnectStatus availability = HealthConnectStatus.available;
  bool permissionsGranted = true;
  DailyHealthMetrics? metricsToReturn;

  @override
  Future<HealthConnectStatus> checkAvailability() async => availability;

  @override
  Future<bool> openHealthConnectInstall() async => true;

  @override
  Future<bool> hasPermissions(List<HealthMetricType> metrics) async => permissionsGranted;

  @override
  Future<bool> requestPermissions(List<HealthMetricType> metrics) async => permissionsGranted;

  @override
  Future<DailyHealthMetrics?> getDailyMetrics(
    String dateStr,
    List<HealthMetricType> metrics,
  ) async =>
      metricsToReturn;

  @override
  Future<List<DailyHealthMetrics>> getMetricsRange(
    String startDateStr,
    String endDateStr,
    List<HealthMetricType> metrics,
  ) async =>
      metricsToReturn != null ? [metricsToReturn!] : [];

  @override
  Future<bool> schedulePeriodicSync({int intervalMinutes = 30}) async => true;

  @override
  Future<bool> cancelPeriodicSync() async => true;
}

class FakeHabitRepository implements HabitRepository {
  final List<Habit> habits = [];
  final Map<String, List<HabitLog>> logs = {};
  final List<Map<String, dynamic>> loggedNumericCalls = [];

  @override
  Stream<List<Habit>> getActiveHabits() => Stream.value(habits);

  @override
  Stream<List<HabitLog>> getLogsForHabitAndDate(String habitId, DateTime date) {
    return Stream.value(logs[habitId] ?? []);
  }

  @override
  Future<void> updateNumericValue(String habitId, DateTime date, double value) async {
    loggedNumericCalls.add({'habitId': habitId, 'date': date, 'value': value});
  }

  // Stubs for remaining HabitRepository interface
  @override
  Stream<List<Habit>> getAllHabits() => Stream.value(habits);
  @override
  Stream<List<Habit>> getArchivedHabits() => Stream.value([]);
  @override
  Stream<List<Habit>> getPinnedHabits() => Stream.value([]);
  @override
  Stream<Habit?> getHabitById(String id) => Stream.value(habits.firstWhere((h) => h.id == id));
  @override
  Future<Habit?> getHabitByIdOnce(String id) async =>
      habits.where((h) => h.id == id).firstOrNull;
  @override
  Stream<List<Habit>> getHabitsByCategory(String categoryId) => Stream.value([]);
  @override
  Future<void> upsertHabit(Habit habit) async => habits.add(habit);
  @override
  Future<void> deleteHabit(Habit habit) async => habits.remove(habit);
  @override
  Future<void> setPinned(String id, bool pinned) async {}
  @override
  Future<void> setArchived(String id, bool archived) async {}
  @override
  Future<void> seedDemoHabits() async {}
  @override
  Stream<List<HabitLog>> getLogsForHabit(String habitId) => Stream.value([]);
  @override
  Future<List<HabitLog>> getLogsForHabitOnce(String habitId) async => [];
  @override
  Stream<List<HabitLog>> getLogsForDate(DateTime date) => Stream.value([]);
  @override
  Future<List<HabitLog>> getLogsForDateOnce(DateTime date) async => [];
  @override
  Stream<List<HabitLog>> getLogsForDateRange(DateTime startDate, DateTime endDate) =>
      Stream.value([]);
  @override
  Future<List<HabitLog>> getLogsForDateRangeOnce(DateTime startDate, DateTime endDate) async =>
      [];
  @override
  Stream<List<HabitLog>> getAllLogs() => Stream.value([]);
  @override
  Future<List<HabitLog>> getAllLogsOnce() async => [];
  @override
  Future<void> logCheckIn({
    required String habitId,
    required DateTime date,
    required bool completed,
    double? value,
    int? durationSeconds,
    int? intervalIndex,
    HabitTier? targetTier,
    String? note,
    int? energyLevel,
    String? mood,
  }) async {}
  @override
  Future<void> logTierCheckIn(
      String habitId, DateTime date, HabitTier tier) async {}
  @override
  Future<void> updateReflection({
    required String habitId,
    required DateTime date,
    int? energyLevel,
    String? mood,
    String? note,
  }) async {}
  @override
  Future<void> toggleBooleanCheckIn(String habitId, DateTime date) async {}
  @override
  Future<void> addNumericDelta(String habitId, DateTime date, double delta) async {}
  @override
  Future<void> toggleSlotCheckIn(String habitId, DateTime date, int slotIndex) async {}
  @override
  Future<void> deleteLogsForHabitAndDate(String habitId, DateTime date) async {}
  @override
  Stream<List<HabitShield>> getAllShields() => Stream.value([]);
  @override
  Future<List<HabitShield>> getAllShieldsOnce() async => [];
  @override
  Stream<List<HabitShield>> getShieldsForHabit(String habitId) => Stream.value([]);
  @override
  Future<List<HabitShield>> getShieldsForHabitOnce(String habitId) async => [];
  @override
  Stream<List<HabitShield>> getShieldsForDate(DateTime date) => Stream.value([]);
  @override
  Future<List<HabitShield>> getShieldsForDateOnce(DateTime date) async => [];
  @override
  Stream<List<HabitShield>> getShieldsForDateRange(DateTime startDate, DateTime endDate) =>
      Stream.value([]);
  @override
  Future<List<HabitShield>> getShieldsForDateRangeOnce(DateTime startDate, DateTime endDate) async =>
      [];
  @override
  Future<bool> applyShield({
    required String habitId,
    required DateTime date,
    bool autoApplied = false,
  }) async =>
      true;
  @override
  Future<void> removeShield(String habitId, DateTime date) async {}
  @override
  Future<bool> toggleShield(String habitId, DateTime date) async => true;
  @override
  Future<bool> isDateShielded(String habitId, DateTime date) async => false;
  @override
  Future<int> autoProtectMissedDays(DateTime date) async => 0;
  @override
  Stream<List<HabitCategory>> getAllCategories() => Stream.value([]);
  @override
  Future<List<HabitCategory>> getAllCategoriesOnce() async => [];
  @override
  Stream<HabitCategory?> getCategoryById(String id) => Stream.value(null);
  @override
  Future<void> upsertCategory(HabitCategory category) async {}
  @override
  Future<void> deleteCategory(HabitCategory category) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHealthConnectService fakeService;
  late FakeHabitRepository fakeHabitRepo;
  late HealthConnectRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeService = FakeHealthConnectService();
    fakeHabitRepo = FakeHabitRepository();
    repository = HealthConnectRepositoryImpl(
      service: fakeService,
      habitRepository: fakeHabitRepo,
      engine: const HealthSyncEngine(),
    );
  });

  group('HealthConnectRepositoryImpl Tests', () {
    test('checkAvailability proxies to service', () async {
      fakeService.availability = HealthConnectStatus.available;
      expect(await repository.checkAvailability(), HealthConnectStatus.available);

      fakeService.availability = HealthConnectStatus.notInstalled;
      expect(await repository.checkAvailability(), HealthConnectStatus.notInstalled);
    });

    test('syncHabitsForDate syncs active health habits and logs updates', () async {
      final now = DateTime.now();
      final habit = Habit(
        id: 'habit_steps',
        title: 'Walk 10,000 Steps',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.numeric,
        targetValue: 10000,
        unit: 'steps',
        healthMetric: HealthMetricType.steps,
        healthSyncEnabled: true,
        createdAt: now,
        updatedAt: now,
      );
      fakeHabitRepo.habits.add(habit);

      fakeService.metricsToReturn = DailyHealthMetrics(
        date: '2026-08-20',
        steps: 11200,
        fetchedAt: now,
      );

      final summary = await repository.syncHabitsForDate(DateTime(2026, 8, 20));

      expect(summary.isSuccess, isTrue);
      expect(summary.habitsChecked, 1);
      expect(summary.habitsUpdated, 1);
      expect(summary.habitsCompleted, 1);
      expect(summary.updatedHabitTitles, contains('Walk 10,000 Steps'));
      expect(fakeHabitRepo.loggedNumericCalls.length, 1);
      expect(fakeHabitRepo.loggedNumericCalls.first['value'], 11200.0);
    });

    test('scheduleBackgroundSync and cancelBackgroundSync delegate cleanly', () async {
      expect(await repository.scheduleBackgroundSync(intervalMinutes: 60), isTrue);
      expect(await repository.cancelBackgroundSync(), isTrue);
    });
  });
}
