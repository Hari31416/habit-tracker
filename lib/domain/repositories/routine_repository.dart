import '../models/habit_routine.dart';
import '../models/routine_log.dart';

abstract class RoutineRepository {
  Stream<List<HabitRoutine>> watchActiveRoutines();
  Future<List<HabitRoutine>> getActiveRoutinesOnce();
  Future<List<HabitRoutine>> getAllRoutinesOnce();
  Future<HabitRoutine?> getRoutineById(String id);
  Future<void> upsertRoutine(HabitRoutine routine);
  Future<void> deleteRoutine(String id);
  Future<void> reorderHabitsInRoutine(String routineId, List<String> habitIds);

  Stream<List<RoutineLog>> watchRoutineLogsForDate(String date);
  Future<List<RoutineLog>> getRoutineLogsForDateOnce(String date);
  Future<List<RoutineLog>> getAllRoutineLogsOnce();
  Future<RoutineLog?> getRoutineLog(String routineId, String date);
  Future<RoutineLog> completeRoutine({
    required String routineId,
    required String date,
    required List<String> completedHabitIds,
    int? customBonusXp,
  });
}
