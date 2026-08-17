package com.productivity.habits.domain.engine

import kotlin.math.floor
import kotlin.math.log10
import kotlin.math.pow

data class DynamicStepConfig(
    val primaryStep: Double,
    val quickAddValues: List<Double>
)

object DynamicStepEngine {

    fun getDynamicStepConfig(targetValue: Double = 1.0, unit: String? = null): DynamicStepConfig {
        val normalizedUnit = (unit ?: "").lowercase().trim()
        val target = maxOf(1.0, targetValue)

        // Specialized unit rules: Volume
        if (normalizedUnit in listOf("ml", "milliliters", "l", "liters")) {
            return when {
                target >= 1000.0 -> DynamicStepConfig(primaryStep = 250.0, quickAddValues = listOf(250.0, 500.0, 1000.0))
                target >= 200.0 -> DynamicStepConfig(primaryStep = 50.0, quickAddValues = listOf(100.0, 250.0))
                else -> DynamicStepConfig(primaryStep = 10.0, quickAddValues = listOf(25.0, 50.0))
            }
        }

        // Specialized unit rules: Steps / Distance
        if (normalizedUnit in listOf("steps", "step")) {
            return when {
                target >= 5000.0 -> DynamicStepConfig(primaryStep = 500.0, quickAddValues = listOf(1000.0, 2500.0, 5000.0))
                target >= 1000.0 -> DynamicStepConfig(primaryStep = 200.0, quickAddValues = listOf(500.0, 1000.0))
                else -> DynamicStepConfig(primaryStep = 50.0, quickAddValues = listOf(100.0, 250.0))
            }
        }

        // Specialized unit rules: Calories / Energy
        if (normalizedUnit in listOf("cal", "kcal", "calories")) {
            return if (target >= 1000.0) {
                DynamicStepConfig(primaryStep = 100.0, quickAddValues = listOf(250.0, 500.0))
            } else {
                DynamicStepConfig(primaryStep = 50.0, quickAddValues = listOf(100.0, 200.0))
            }
        }

        // General numeric scaling rules
        return when {
            target <= 5.0 -> DynamicStepConfig(primaryStep = 1.0, quickAddValues = listOf(1.0, 2.0))
            target <= 15.0 -> DynamicStepConfig(primaryStep = 1.0, quickAddValues = listOf(2.0, 5.0))
            target <= 50.0 -> DynamicStepConfig(primaryStep = 1.0, quickAddValues = listOf(5.0, 10.0))
            target <= 150.0 -> DynamicStepConfig(primaryStep = 5.0, quickAddValues = listOf(10.0, 25.0))
            target <= 500.0 -> DynamicStepConfig(primaryStep = 10.0, quickAddValues = listOf(25.0, 50.0, 100.0))
            target <= 2500.0 -> DynamicStepConfig(primaryStep = 50.0, quickAddValues = listOf(100.0, 250.0, 500.0))
            target <= 10000.0 -> DynamicStepConfig(primaryStep = 250.0, quickAddValues = listOf(500.0, 1000.0, 2500.0))
            else -> {
                val power = 10.0.pow(floor(log10(target)) - 1)
                DynamicStepConfig(primaryStep = power, quickAddValues = listOf(power * 2, power * 5))
            }
        }
    }

    fun getDynamicTimerConfig(targetMinutes: Double = 30.0): DynamicStepConfig {
        val target = maxOf(1.0, targetMinutes)
        return when {
            target <= 15.0 -> DynamicStepConfig(primaryStep = 1.0, quickAddValues = listOf(2.0, 5.0, 10.0))
            target <= 30.0 -> DynamicStepConfig(primaryStep = 5.0, quickAddValues = listOf(5.0, 10.0, 15.0))
            target <= 60.0 -> DynamicStepConfig(primaryStep = 5.0, quickAddValues = listOf(10.0, 15.0, 30.0))
            else -> DynamicStepConfig(primaryStep = 15.0, quickAddValues = listOf(15.0, 30.0, 60.0))
        }
    }
}
