import 'dart:math';

class DynamicStepConfig {
  final double primaryStep;
  final List<double> quickAddValues;

  const DynamicStepConfig({
    required this.primaryStep,
    required this.quickAddValues,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DynamicStepConfig &&
          runtimeType == other.runtimeType &&
          primaryStep == other.primaryStep &&
          _listEquals(quickAddValues, other.quickAddValues);

  @override
  int get hashCode => primaryStep.hashCode ^ quickAddValues.hashCode;

  static bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class DynamicStepEngine {
  static DynamicStepConfig getDynamicStepConfig(
    double targetValue, [
    String? unit,
  ]) {
    final normalizedUnit = (unit ?? '').toLowerCase().trim();
    final target = max(1.0, targetValue);

    // Specialized unit rules: Volume
    if (['ml', 'milliliters', 'l', 'liters'].contains(normalizedUnit)) {
      if (target >= 1000.0) {
        return const DynamicStepConfig(
          primaryStep: 250.0,
          quickAddValues: [250.0, 500.0, 1000.0],
        );
      } else if (target >= 200.0) {
        return const DynamicStepConfig(
          primaryStep: 50.0,
          quickAddValues: [100.0, 250.0],
        );
      } else {
        return const DynamicStepConfig(
          primaryStep: 10.0,
          quickAddValues: [25.0, 50.0],
        );
      }
    }

    // Specialized unit rules: Steps / Distance
    if (['steps', 'step'].contains(normalizedUnit)) {
      if (target >= 5000.0) {
        return const DynamicStepConfig(
          primaryStep: 500.0,
          quickAddValues: [1000.0, 2500.0, 5000.0],
        );
      } else if (target >= 1000.0) {
        return const DynamicStepConfig(
          primaryStep: 200.0,
          quickAddValues: [500.0, 1000.0],
        );
      } else {
        return const DynamicStepConfig(
          primaryStep: 50.0,
          quickAddValues: [100.0, 250.0],
        );
      }
    }

    // Specialized unit rules: Calories / Energy
    if (['cal', 'kcal', 'calories'].contains(normalizedUnit)) {
      if (target >= 1000.0) {
        return const DynamicStepConfig(
          primaryStep: 100.0,
          quickAddValues: [250.0, 500.0],
        );
      } else {
        return const DynamicStepConfig(
          primaryStep: 50.0,
          quickAddValues: [100.0, 200.0],
        );
      }
    }

    // General numeric scaling rules
    if (target <= 5.0) {
      return const DynamicStepConfig(
        primaryStep: 1.0,
        quickAddValues: [1.0, 2.0],
      );
    } else if (target <= 15.0) {
      return const DynamicStepConfig(
        primaryStep: 1.0,
        quickAddValues: [2.0, 5.0],
      );
    } else if (target <= 50.0) {
      return const DynamicStepConfig(
        primaryStep: 1.0,
        quickAddValues: [5.0, 10.0],
      );
    } else if (target <= 150.0) {
      return const DynamicStepConfig(
        primaryStep: 5.0,
        quickAddValues: [10.0, 25.0],
      );
    } else if (target <= 500.0) {
      return const DynamicStepConfig(
        primaryStep: 10.0,
        quickAddValues: [25.0, 50.0, 100.0],
      );
    } else if (target <= 2500.0) {
      return const DynamicStepConfig(
        primaryStep: 50.0,
        quickAddValues: [100.0, 250.0, 500.0],
      );
    } else if (target <= 10000.0) {
      return const DynamicStepConfig(
        primaryStep: 250.0,
        quickAddValues: [500.0, 1000.0, 2500.0],
      );
    } else {
      final power = pow(10.0, (log(target) / ln10).floor() - 1).toDouble();
      return DynamicStepConfig(
        primaryStep: power,
        quickAddValues: [power * 2, power * 5],
      );
    }
  }

  static DynamicStepConfig getDynamicTimerConfig([double targetMinutes = 30.0]) {
    final target = max(1.0, targetMinutes);
    if (target <= 15.0) {
      return const DynamicStepConfig(
        primaryStep: 1.0,
        quickAddValues: [2.0, 5.0, 10.0],
      );
    } else if (target <= 30.0) {
      return const DynamicStepConfig(
        primaryStep: 5.0,
        quickAddValues: [5.0, 10.0, 15.0],
      );
    } else if (target <= 60.0) {
      return const DynamicStepConfig(
        primaryStep: 5.0,
        quickAddValues: [10.0, 15.0, 30.0],
      );
    } else {
      return const DynamicStepConfig(
        primaryStep: 15.0,
        quickAddValues: [15.0, 30.0, 60.0],
      );
    }
  }
}
