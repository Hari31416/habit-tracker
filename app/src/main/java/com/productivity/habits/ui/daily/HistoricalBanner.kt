package com.productivity.habits.ui.daily

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.History
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Composable
fun HistoricalBanner(
    selectedDate: LocalDate,
    onReturnToToday: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isToday = selectedDate == LocalDate.now()
    val isPast = selectedDate.isBefore(LocalDate.now())

    AnimatedVisibility(
        visible = !isToday,
        enter = expandVertically(),
        exit = shrinkVertically()
    ) {
        val formattedDate = selectedDate.format(DateTimeFormatter.ofPattern("EEE, MMM d, yyyy"))
        val label = if (isPast) "Viewing Past: $formattedDate" else "Viewing Future: $formattedDate"

        Row(
            modifier = modifier
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.85f))
                .padding(horizontal = 16.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.weight(1f)
            ) {
                Icon(
                    imageVector = Icons.Default.History,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onTertiaryContainer,
                    modifier = Modifier.size(18.dp)
                )
                Text(
                    text = label,
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onTertiaryContainer,
                    modifier = Modifier.padding(start = 8.dp)
                )
            }

            TextButton(
                onClick = onReturnToToday,
                colors = ButtonDefaults.textButtonColors(
                    contentColor = MaterialTheme.colorScheme.onTertiaryContainer
                )
            ) {
                Text(
                    text = "Return to Today",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
