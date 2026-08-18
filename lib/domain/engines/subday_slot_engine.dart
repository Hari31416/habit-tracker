import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class SubdaySlot {
  final int index;
  final String timeLabel;
  final DateTime? time;
  final bool completed;

  const SubdaySlot({
    required this.index,
    required this.timeLabel,
    this.time,
    this.completed = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubdaySlot &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          timeLabel == other.timeLabel &&
          completed == other.completed;

  @override
  int get hashCode => index.hashCode ^ timeLabel.hashCode ^ completed.hashCode;
}

class SubdaySlotEngine {
  static final DateFormat timeFormatter = DateFormat('HH:mm');

  static List<SubdaySlot> generateSlots(
    Habit habit, [
    List<HabitLog> logsForDate = const [],
  ]) {
    final completedIndices = logsForDate
        .where((log) => log.completed)
        .map((log) => log.intervalIndex)
        .where((idx) => idx != null)
        .cast<int>()
        .toSet();

    final timeWindow = habit.timeWindow;
    final intervalHours = habit.intervalHours;
    final timesPerDay = habit.timesPerDay;

    // Case 1: Time Window + Interval Hours (e.g. 08:00 to 20:00 every 2 hours)
    if (timeWindow != null && intervalHours != null && intervalHours > 0) {
      final startTime = parseTime(timeWindow.startTime) ?? DateTime(2000, 1, 1, 8, 0);
      final endTime = parseTime(timeWindow.endTime) ?? DateTime(2000, 1, 1, 20, 0);

      final slots = <SubdaySlot>[];
      var current = startTime;
      var index = 0;

      while (!current.isAfter(endTime)) {
        slots.add(
          SubdaySlot(
            index: index,
            timeLabel: timeFormatter.format(current),
            time: current,
            completed: completedIndices.contains(index),
          ),
        );
        index++;
        final next = current.add(Duration(hours: intervalHours));
        if (next.isBefore(current) || next == current) break; // Safety against overflow
        current = next;
      }
      return slots;
    }

    // Case 2: Time Window + Times Per Day (evenly spaced)
    if (timeWindow != null && timesPerDay != null && timesPerDay > 0) {
      final startTime = parseTime(timeWindow.startTime) ?? DateTime(2000, 1, 1, 8, 0);
      final endTime = parseTime(timeWindow.endTime) ?? DateTime(2000, 1, 1, 20, 0);

      if (timesPerDay == 1) {
        return [
          SubdaySlot(
            index: 0,
            timeLabel: timeFormatter.format(startTime),
            time: startTime,
            completed: completedIndices.contains(0),
          ),
        ];
      }

      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      final totalMinutes = (endMinutes - startMinutes).clamp(0, 1440);
      final stepMinutes = totalMinutes ~/ (timesPerDay - 1);

      return List.generate(timesPerDay, (index) {
        final slotMinutes = (startMinutes + (index * stepMinutes)).clamp(0, 1439);
        final hour = slotMinutes ~/ 60;
        final minute = slotMinutes % 60;
        final slotTime = DateTime(2000, 1, 1, hour, minute);
        return SubdaySlot(
          index: index,
          timeLabel: timeFormatter.format(slotTime),
          time: slotTime,
          completed: completedIndices.contains(index),
        );
      });
    }

    // Case 3: Fixed Times Per Day without explicit time window
    final count = timesPerDay ?? habit.targetValue?.toInt() ?? 3;
    return List.generate(count, (index) {
      return SubdaySlot(
        index: index,
        timeLabel: '#${index + 1}',
        time: null,
        completed: completedIndices.contains(index),
      );
    });
  }

  static DateTime? parseTime(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(2000, 1, 1, hour, minute);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
