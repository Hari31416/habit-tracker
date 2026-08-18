package com.productivity.habits.ui.form

import android.app.TimePickerDialog
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Alarm
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.ui.common.ColorUtils
import com.productivity.habits.ui.common.HabitIconRegistry
import com.productivity.habits.ui.common.HapticsHelper
import com.productivity.habits.ui.theme.HABIT_PRESET_COLORS
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun HabitFormBottomSheet(
    viewModel: HabitFormViewModel,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    val formState by viewModel.formState.collectAsState()
    val categories by viewModel.categories.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.saveSuccessEvent.collect {
            onDismiss()
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface,
        modifier = modifier.imePadding()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .verticalScroll(rememberScrollState())
        ) {
            // Sheet Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = if (formState.isEditMode) "Edit Habit" else "New Habit",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )

                IconButton(
                    onClick = {
                        HapticsHelper.performLightHaptic(haptic)
                        viewModel.onTogglePinned()
                    }
                ) {
                    Icon(
                        imageVector = if (formState.pinned) Icons.Filled.PushPin else Icons.Outlined.PushPin,
                        contentDescription = "Pin habit",
                        tint = if (formState.pinned) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // 1. Basic Info Section
            OutlinedTextField(
                value = formState.title,
                onValueChange = viewModel::onTitleChange,
                label = { Text("Habit Title *") },
                isError = formState.titleError != null,
                supportingText = formState.titleError?.let { { Text(it, color = MaterialTheme.colorScheme.error) } },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(10.dp))

            OutlinedTextField(
                value = formState.description,
                onValueChange = viewModel::onDescriptionChange,
                label = { Text("Description (optional)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(10.dp))

            OutlinedTextField(
                value = formState.motivationNotes,
                onValueChange = viewModel::onMotivationChange,
                label = { Text("Motivation / Why this habit? (optional)") },
                maxLines = 2,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Category Selection
            Text(
                text = "Category",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(6.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                categories.forEach { cat ->
                    val isSelected = formState.categoryId == cat.id
                    FilterChip(
                        selected = isSelected,
                        onClick = {
                            HapticsHelper.performLightHaptic(haptic)
                            viewModel.onCategoryChange(if (isSelected) null else cat.id)
                        },
                        label = { Text(cat.name) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Color Palette (8 presets)
            Text(
                text = "Accent Color",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                HABIT_PRESET_COLORS.forEach { hex ->
                    val color = ColorUtils.parseHexColor(hex)
                    val isSelected = formState.color.equals(hex, ignoreCase = true)
                    Box(
                        modifier = Modifier
                            .size(34.dp)
                            .clip(CircleShape)
                            .background(color)
                            .then(
                                if (isSelected) {
                                    Modifier.border(3.dp, MaterialTheme.colorScheme.onSurface, CircleShape)
                                } else Modifier
                            )
                            .clickable {
                                HapticsHelper.performLightHaptic(haptic)
                                viewModel.onColorChange(hex)
                            },
                        contentAlignment = Alignment.Center
                    ) {
                        if (isSelected) {
                            Icon(
                                imageVector = Icons.Default.Check,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Icon Picker (20 icons)
            Text(
                text = "Icon",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                HabitIconRegistry.AVAILABLE_ICONS.forEach { item ->
                    val isSelected = formState.icon.equals(item.key, ignoreCase = true)
                    val currentColor = ColorUtils.parseHexColor(formState.color)
                    Surface(
                        modifier = Modifier
                            .size(42.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .clickable {
                                HapticsHelper.performLightHaptic(haptic)
                                viewModel.onIconChange(item.key)
                            },
                        shape = RoundedCornerShape(10.dp),
                        color = if (isSelected) currentColor.copy(alpha = 0.2f) else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f),
                        border = if (isSelected) BorderStroke(2.dp, currentColor) else null
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = item.icon,
                                contentDescription = item.label,
                                tint = if (isSelected) currentColor else MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // 2. Target Model Selector
            Text(
                text = "Target Type",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(8.dp))
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                HabitTargetType.entries.forEachIndexed { index, targetType ->
                    SegmentedButton(
                        selected = formState.targetType == targetType,
                        onClick = {
                            HapticsHelper.performLightHaptic(haptic)
                            viewModel.onTargetTypeChange(targetType)
                        },
                        shape = SegmentedButtonDefaults.itemShape(index = index, count = HabitTargetType.entries.size)
                    ) {
                        Text(
                            when (targetType) {
                                HabitTargetType.BOOLEAN -> "Yes / No"
                                HabitTargetType.NUMERIC -> "Numeric"
                                HabitTargetType.TIMER -> "Timer"
                            }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            when (formState.targetType) {
                HabitTargetType.NUMERIC -> {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = formState.targetValue,
                            onValueChange = viewModel::onTargetValueChange,
                            label = { Text("Target Goal *") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                            isError = formState.targetValueError != null,
                            singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                        OutlinedTextField(
                            value = formState.unit,
                            onValueChange = viewModel::onUnitChange,
                            label = { Text("Unit (e.g. ml, steps)") },
                            singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                    }

                    Spacer(modifier = Modifier.height(6.dp))

                    // Unit presets
                    val unitPresets = listOf("glasses", "steps", "pages", "ml", "km", "cal")
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        unitPresets.forEach { u ->
                            FilterChip(
                                selected = formState.unit.equals(u, ignoreCase = true),
                                onClick = {
                                    HapticsHelper.performLightHaptic(haptic)
                                    viewModel.onUnitChange(u)
                                },
                                label = { Text(u) },
                                colors = FilterChipDefaults.filterChipColors()
                            )
                        }
                    }
                }

                HabitTargetType.TIMER -> {
                    OutlinedTextField(
                        value = formState.targetValue,
                        onValueChange = viewModel::onTargetValueChange,
                        label = { Text("Target Duration (Minutes) *") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        isError = formState.targetValueError != null,
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(6.dp))

                    // Duration presets
                    val timerPresets = listOf("15", "25", "30", "45", "60")
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        timerPresets.forEach { mins ->
                            FilterChip(
                                selected = formState.targetValue == mins,
                                onClick = {
                                    HapticsHelper.performLightHaptic(haptic)
                                    viewModel.onTargetValueChange(mins)
                                },
                                label = { Text("$mins mins") }
                            )
                        }
                    }
                }

                HabitTargetType.BOOLEAN -> Unit
            }

            Spacer(modifier = Modifier.height(20.dp))

            // 3. Frequency Rules
            Text(
                text = "Frequency",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(8.dp))

            FlowRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                HabitFrequencyType.entries.forEach { freq ->
                    val label = when (freq) {
                        HabitFrequencyType.DAILY -> "Everyday"
                        HabitFrequencyType.CUSTOM_DAYS -> "Specific Days"
                        HabitFrequencyType.WEEKLY -> "Times Per Week"
                        HabitFrequencyType.SUBDAY_INTERVAL -> "Interval (Hours)"
                        HabitFrequencyType.TIMES_PER_DAY -> "Times Per Day"
                    }
                    FilterChip(
                        selected = formState.frequencyType == freq,
                        onClick = {
                            HapticsHelper.performLightHaptic(haptic)
                            viewModel.onFrequencyTypeChange(freq)
                        },
                        label = { Text(label) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            when (formState.frequencyType) {
                HabitFrequencyType.CUSTOM_DAYS -> {
                    val daysLabels = listOf("S", "M", "T", "W", "T", "F", "S") // 0=Sun..6=Sat
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        daysLabels.forEachIndexed { index, dayLetter ->
                            val isSelected = formState.targetDaysOfWeek.contains(index)
                            val accentColor = ColorUtils.parseHexColor(formState.color)
                            Surface(
                                modifier = Modifier
                                    .size(40.dp)
                                    .clip(CircleShape)
                                    .clickable {
                                        HapticsHelper.performLightHaptic(haptic)
                                        viewModel.toggleDayOfWeek(index)
                                    },
                                shape = CircleShape,
                                color = if (isSelected) accentColor else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Text(
                                        text = dayLetter,
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                    }
                }

                HabitFrequencyType.WEEKLY -> {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Target: ${formState.targetCountPerWeek} days / week",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.Medium
                            )
                        }
                        Slider(
                            value = formState.targetCountPerWeek.toFloat(),
                            onValueChange = { viewModel.onTargetCountPerWeekChange(it.toInt()) },
                            valueRange = 1f..6f,
                            steps = 4,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }

                HabitFrequencyType.SUBDAY_INTERVAL -> {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        Text(
                            text = "Interval: Every ${formState.intervalHours} hours",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium
                        )
                        Slider(
                            value = formState.intervalHours.toFloat(),
                            onValueChange = { viewModel.onIntervalHoursChange(it.toInt()) },
                            valueRange = 1f..8f,
                            steps = 6,
                            modifier = Modifier.fillMaxWidth()
                        )

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            OutlinedTextField(
                                value = formState.timeWindowStart,
                                onValueChange = { viewModel.onTimeWindowChange(it, formState.timeWindowEnd) },
                                label = { Text("Start Time") },
                                singleLine = true,
                                modifier = Modifier.weight(1f)
                            )
                            OutlinedTextField(
                                value = formState.timeWindowEnd,
                                onValueChange = { viewModel.onTimeWindowChange(formState.timeWindowStart, it) },
                                label = { Text("End Time") },
                                singleLine = true,
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }

                HabitFrequencyType.TIMES_PER_DAY -> {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        Text(
                            text = "Times per day: ${formState.timesPerDay}",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium
                        )
                        Slider(
                            value = formState.timesPerDay.toFloat(),
                            onValueChange = { viewModel.onTimesPerDayChange(it.toInt()) },
                            valueRange = 1f..8f,
                            steps = 6,
                            modifier = Modifier.fillMaxWidth()
                        )

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            OutlinedTextField(
                                value = formState.timeWindowStart,
                                onValueChange = { viewModel.onTimeWindowChange(it, formState.timeWindowEnd) },
                                label = { Text("Start Time") },
                                singleLine = true,
                                modifier = Modifier.weight(1f)
                            )
                            OutlinedTextField(
                                value = formState.timeWindowEnd,
                                onValueChange = { viewModel.onTimeWindowChange(formState.timeWindowStart, it) },
                                label = { Text("End Time") },
                                singleLine = true,
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }

                HabitFrequencyType.DAILY -> Unit
            }

            Spacer(modifier = Modifier.height(20.dp))

            // 4. Reminders
            Text(
                text = "Reminders",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(8.dp))

            // Quick reminder presets
            val reminderPresets = listOf(
                "Morning" to "08:00",
                "Midday" to "12:30",
                "Evening" to "18:00",
                "Night" to "21:30"
            )
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                reminderPresets.forEach { (label, time) ->
                    val isAdded = formState.reminderTimes.contains(time)
                    FilterChip(
                        selected = isAdded,
                        onClick = {
                            HapticsHelper.performLightHaptic(haptic)
                            if (isAdded) viewModel.removeReminderTime(time) else viewModel.addReminderTime(time)
                        },
                        label = { Text("$label ($time)") }
                    )
                }

                // Custom Time Button
                AssistChip(
                    onClick = {
                        val timePicker = TimePickerDialog(
                            context,
                            { _, hourOfDay, minute ->
                                val timeStr = String.format(Locale.getDefault(), "%02d:%02d", hourOfDay, minute)
                                viewModel.addReminderTime(timeStr)
                            },
                            8, 0, true
                        )
                        timePicker.show()
                    },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = "Add custom reminder",
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                    },
                    label = {
                        Text(
                            text = "Custom",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.primary
                        )
                    },
                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.5f))
                )
            }

            // Reminders List
            if (formState.reminderTimes.isNotEmpty()) {
                Spacer(modifier = Modifier.height(10.dp))
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    formState.reminderTimes.forEach { time ->
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 12.dp, vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        imageVector = Icons.Default.Alarm,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = time,
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                                IconButton(
                                    onClick = {
                                        HapticsHelper.performLightHaptic(haptic)
                                        viewModel.removeReminderTime(time)
                                    },
                                    modifier = Modifier.size(24.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Close,
                                        contentDescription = "Remove reminder",
                                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(28.dp))

            // Footer Actions
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = onDismiss,
                    modifier = Modifier
                        .weight(1f)
                        .height(48.dp),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("Cancel")
                }

                Button(
                    onClick = {
                        HapticsHelper.performLightHaptic(haptic)
                        viewModel.saveHabit()
                    },
                    enabled = !formState.isSaving,
                    modifier = Modifier
                        .weight(1f)
                        .height(48.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                ) {
                    if (formState.isSaving) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = MaterialTheme.colorScheme.onPrimary,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text(
                            text = if (formState.isEditMode) "Update Habit" else "Create Habit",
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}
