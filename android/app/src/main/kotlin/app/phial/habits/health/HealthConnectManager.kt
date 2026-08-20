package app.phial.habits.health

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HydrationRecord
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.TotalCaloriesBurnedRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlin.reflect.KClass

class HealthConnectManager(private val context: Context) {
    private val client: HealthConnectClient? by lazy {
        if (HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE) {
            HealthConnectClient.getOrCreate(context)
        } else {
            null
        }
    }

    fun checkAvailability(): String {
        return when (HealthConnectClient.getSdkStatus(context)) {
            HealthConnectClient.SDK_AVAILABLE -> "available"
            HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> "not_installed"
            else -> "not_supported"
        }
    }

    fun getPermissionsForMetrics(metrics: List<String>): Set<String> {
        val permissions = mutableSetOf<String>()
        for (m in metrics) {
            when (m.lowercase()) {
                "steps" -> permissions.add(HealthPermission.getReadPermission(StepsRecord::class))
                "exercise_time", "exercise" ->
                    permissions.add(HealthPermission.getReadPermission(ExerciseSessionRecord::class))
                "move_minutes", "active_minutes", "movement" ->
                    permissions.add(HealthPermission.getReadPermission(ExerciseSessionRecord::class))
                "distance", "distance_km" ->
                    permissions.add(HealthPermission.getReadPermission(DistanceRecord::class))
                "active_calories", "calories", "energy" -> {
                    permissions.add(HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class))
                    permissions.add(HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class))
                }
                "hydration", "water" ->
                    permissions.add(HealthPermission.getReadPermission(HydrationRecord::class))
                "sleep_duration", "sleep" ->
                    permissions.add(HealthPermission.getReadPermission(SleepSessionRecord::class))
            }
        }
        return permissions
    }

    suspend fun hasPermissions(metrics: List<String>): Boolean {
        val healthClient = client ?: run {
            android.util.Log.w("HealthConnectManager", "HealthConnectClient is null")
            return false
        }
        val required = getPermissionsForMetrics(metrics)
        if (required.isEmpty()) return true
        val granted = healthClient.permissionController.getGrantedPermissions()
        android.util.Log.d("HealthConnectManager", "Granted: $granted | Required: $required")
        return granted.containsAll(required)
    }

    suspend fun getDailyMetrics(dateStr: String, metrics: List<String>): Map<String, Any> {
        val healthClient = client ?: run {
            android.util.Log.w("HealthConnectManager", "getDailyMetrics: client is null")
            return emptyMap()
        }

        val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
        val localDate = try {
            LocalDate.parse(dateStr, formatter)
        } catch (_: Exception) {
            LocalDate.now()
        }

        val zone = ZoneId.systemDefault()
        val startInstant = localDate.atStartOfDay(zone).toInstant()
        val isToday = localDate == LocalDate.now()
        val endInstant = if (isToday) java.time.Instant.now() else localDate.plusDays(1).atStartOfDay(zone).toInstant()

        val results = mutableMapOf<String, Any>()
        results["date"] = dateStr

        for (metric in metrics) {
            try {
                when (metric.lowercase()) {
                    "steps" -> {
                        val response = healthClient.aggregate(
                            AggregateRequest(
                                metrics = setOf(StepsRecord.COUNT_TOTAL),
                                timeRangeFilter = TimeRangeFilter.between(startInstant, endInstant)
                            )
                        )
                        val stepCount = response[StepsRecord.COUNT_TOTAL] ?: 0L
                        android.util.Log.d("HealthConnectManager", "Steps aggregated for $dateStr: $stepCount")
                        results["steps"] = stepCount.toDouble()
                    }
                    "exercise_time", "exercise" -> {
                        val response = healthClient.aggregate(
                            AggregateRequest(
                                metrics = setOf(ExerciseSessionRecord.EXERCISE_DURATION_TOTAL),
                                timeRangeFilter = TimeRangeFilter.between(startInstant, endInstant)
                            )
                        )
                        val duration = response[ExerciseSessionRecord.EXERCISE_DURATION_TOTAL]
                        val totalMinutes = (duration?.seconds ?: 0L) / 60.0
                        android.util.Log.d("HealthConnectManager", "Exercise minutes for $dateStr: $totalMinutes")
                        results["exercise_minutes"] = (totalMinutes * 10).toInt() / 10.0
                    }
                    "move_minutes", "active_minutes", "movement" -> {
                        // 1. Calculate duration from structured exercise sessions
                        val exerciseResponse = healthClient.aggregate(
                            AggregateRequest(
                                metrics = setOf(ExerciseSessionRecord.EXERCISE_DURATION_TOTAL),
                                timeRangeFilter = TimeRangeFilter.between(startInstant, endInstant)
                            )
                        )
                        val exerciseDuration = exerciseResponse[ExerciseSessionRecord.EXERCISE_DURATION_TOTAL]
                        val exerciseMins = (exerciseDuration?.seconds ?: 0L) / 60.0

                        // 2. Count discrete Move Minutes matching Google Fit's official criteria:
                        // Each 1-minute bucket with active cadence (>= 30 steps/min) yields 1 Move Minute.
                        val stepsRequest = ReadRecordsRequest(
                            recordType = StepsRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(startInstant, endInstant)
                        )
                        val stepsResponse = healthClient.readRecords(stepsRequest)
                        var fitMoveMinutes = 0.0
                        for (stepRecord in stepsResponse.records) {
                            val intervalSec = java.time.Duration.between(stepRecord.startTime, stepRecord.endTime).seconds
                            val intervalMins = if (intervalSec > 0) intervalSec / 60.0 else 1.0
                            val cadence = stepRecord.count / intervalMins

                            if (cadence >= 30.0) {
                                // Qualifying active movement interval
                                val activeBuckets = if (intervalSec >= 60) (intervalSec / 60.0).toInt().toDouble() else 1.0
                                fitMoveMinutes += activeBuckets
                            }
                        }

                        val totalMoveMinutes = Math.max(exerciseMins, fitMoveMinutes)
                        android.util.Log.d("HealthConnectManager", "Google Fit Move Minutes for $dateStr: $totalMoveMinutes (exercise=$exerciseMins, fitMoveMinutes=$fitMoveMinutes)")
                        results["move_minutes"] = totalMoveMinutes
                    }
                    "distance", "distance_km" -> {
                        val response = healthClient.aggregate(
                            AggregateRequest(
                                metrics = setOf(DistanceRecord.DISTANCE_TOTAL),
                                timeRangeFilter = TimeRangeFilter.between(startInstant, endInstant)
                            )
                        )
                        val distanceMeters = response[DistanceRecord.DISTANCE_TOTAL]?.inMeters ?: 0.0
                        val distanceKm = distanceMeters / 1000.0
                        android.util.Log.d("HealthConnectManager", "Distance aggregated for $dateStr: $distanceKm km")
                        results["distance_km"] = (distanceKm * 100).toInt() / 100.0
                    }
                    "active_calories", "calories", "energy" -> {
                        val response = healthClient.aggregate(
                            AggregateRequest(
                                metrics = setOf(TotalCaloriesBurnedRecord.ENERGY_TOTAL, ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL),
                                timeRangeFilter = TimeRangeFilter.between(startInstant, endInstant)
                            )
                        )
                        val totalKcal = response[TotalCaloriesBurnedRecord.ENERGY_TOTAL]?.inKilocalories
                            ?: response[ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL]?.inKilocalories
                            ?: 0.0
                        android.util.Log.d("HealthConnectManager", "Google Fit Energy aggregated for $dateStr (up to $endInstant): $totalKcal kcal")
                        results["active_calories"] = totalKcal.toInt().toDouble()
                    }
                    "hydration", "water" -> {
                        val response = healthClient.aggregate(
                            AggregateRequest(
                                metrics = setOf(HydrationRecord.VOLUME_TOTAL),
                                timeRangeFilter = TimeRangeFilter.between(startInstant, endInstant)
                            )
                        )
                        val volumeLiters = response[HydrationRecord.VOLUME_TOTAL]?.inLiters ?: 0.0
                        val volumeMl = volumeLiters * 1000.0
                        results["hydration_ml"] = volumeMl.toInt().toDouble()
                    }
                    "sleep_duration", "sleep" -> {
                        val request = ReadRecordsRequest(
                            recordType = SleepSessionRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(startInstant, endInstant)
                        )
                        val response = healthClient.readRecords(request)
                        var totalSleepMinutes = 0.0
                        for (session in response.records) {
                            val durationSec = java.time.Duration.between(session.startTime, session.endTime).seconds
                            totalSleepMinutes += durationSec / 60.0
                        }
                        results["sleep_minutes"] = totalSleepMinutes.toInt().toDouble()
                    }
                }
            } catch (e: Exception) {
                android.util.Log.w("HealthConnectManager", "Error reading metric $metric for $dateStr", e)
            }
        }

        return results
    }

    suspend fun getMetricsRange(startDateStr: String, endDateStr: String, metrics: List<String>): List<Map<String, Any>> {
        val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
        val start = try { LocalDate.parse(startDateStr, formatter) } catch (_: Exception) { LocalDate.now() }
        val end = try { LocalDate.parse(endDateStr, formatter) } catch (_: Exception) { LocalDate.now() }

        val list = mutableListOf<Map<String, Any>>()
        var current = start
        while (!current.isAfter(end)) {
            val dStr = current.format(formatter)
            list.add(getDailyMetrics(dStr, metrics))
            current = current.plusDays(1)
        }
        return list
    }
}
