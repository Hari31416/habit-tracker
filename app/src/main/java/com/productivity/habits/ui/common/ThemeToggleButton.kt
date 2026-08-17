package com.productivity.habits.ui.common

import androidx.compose.foundation.layout.Box
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BrightnessAuto
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import com.productivity.habits.data.local.preferences.ThemeMode

@Composable
fun ThemeToggleButton(
    currentTheme: ThemeMode,
    onThemeSelected: (ThemeMode) -> Unit,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    val haptic = LocalHapticFeedback.current

    val icon = when (currentTheme) {
        ThemeMode.SYSTEM -> Icons.Default.BrightnessAuto
        ThemeMode.LIGHT -> Icons.Default.LightMode
        ThemeMode.DARK -> Icons.Default.DarkMode
    }

    Box(modifier = modifier) {
        IconButton(
            onClick = {
                HapticsHelper.performLightHaptic(haptic)
                expanded = true
            }
        ) {
            Icon(
                imageVector = icon,
                contentDescription = "Theme: ${currentTheme.displayName}",
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            ThemeMode.entries.forEach { mode ->
                DropdownMenuItem(
                    text = {
                        Text(
                            text = mode.displayName,
                            fontWeight = if (currentTheme == mode) FontWeight.Bold else FontWeight.Normal,
                            color = if (currentTheme == mode) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                        )
                    },
                    leadingIcon = {
                        val itemIcon = when (mode) {
                            ThemeMode.SYSTEM -> Icons.Default.BrightnessAuto
                            ThemeMode.LIGHT -> Icons.Default.LightMode
                            ThemeMode.DARK -> Icons.Default.DarkMode
                        }
                        Icon(
                            imageVector = itemIcon,
                            contentDescription = null,
                            tint = if (currentTheme == mode) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    },
                    onClick = {
                        HapticsHelper.performLightHaptic(haptic)
                        onThemeSelected(mode)
                        expanded = false
                    }
                )
            }
        }
    }
}
