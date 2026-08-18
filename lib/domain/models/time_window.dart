class TimeWindow {
  final String startTime; // HH:mm format (e.g., "08:00")
  final String endTime;   // HH:mm format (e.g., "20:00")

  const TimeWindow({
    required this.startTime,
    required this.endTime,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeWindow &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;

  @override
  String toString() => 'TimeWindow(startTime: $startTime, endTime: $endTime)';
}
