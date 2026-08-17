package com.productivity.habits.ui.analytics

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import java.time.LocalDate

data class AdherenceDataPoint(
    val date: LocalDate,
    val label: String,
    val adherencePercent: Int
)

enum class TrendRange(val label: String, val days: Int) {
    SEVEN_DAYS("7 Days", 7),
    THIRTY_DAYS("30 Days", 30)
}

@Composable
fun AdherenceAreaChart(
    dataPoints: List<AdherenceDataPoint>,
    selectedRange: TrendRange,
    onRangeSelected: (TrendRange) -> Unit,
    modifier: Modifier = Modifier
) {
    val primaryColor = MaterialTheme.colorScheme.primary
    val gradientColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.4f)
    val gridLineColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f)

    Column(modifier = modifier.fillMaxWidth()) {
        // Chart Header with Range Toggle
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Adherence Trend",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )

            SingleChoiceSegmentedButtonRow {
                TrendRange.entries.forEachIndexed { index, range ->
                    SegmentedButton(
                        selected = selectedRange == range,
                        onClick = { onRangeSelected(range) },
                        shape = SegmentedButtonDefaults.itemShape(index = index, count = TrendRange.entries.size)
                    ) {
                        Text(range.label, style = MaterialTheme.typography.labelSmall)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        if (dataPoints.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(160.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No adherence data available",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            return
        }

        // Smooth Area Canvas
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(160.dp)
                .padding(horizontal = 8.dp, vertical = 8.dp)
        ) {
            val width = size.width
            val height = size.height

            // Horizontal grid lines (0%, 50%, 100%)
            for (percent in listOf(0f, 0.5f, 1f)) {
                val y = height - (percent * height)
                drawLine(
                    color = gridLineColor,
                    start = Offset(0f, y),
                    end = Offset(width, y),
                    strokeWidth = 1.dp.toPx()
                )
            }

            if (dataPoints.size < 2) return@Canvas

            val stepX = width / (dataPoints.size - 1)
            val path = Path()
            val fillPath = Path()

            dataPoints.forEachIndexed { index, point ->
                val x = index * stepX
                val normalizedY = (point.adherencePercent.toFloat() / 100f).coerceIn(0f, 1f)
                val y = height - (normalizedY * height)

                if (index == 0) {
                    path.moveTo(x, y)
                    fillPath.moveTo(x, height)
                    fillPath.lineTo(x, y)
                } else {
                    val prevX = (index - 1) * stepX
                    val prevNormY = (dataPoints[index - 1].adherencePercent.toFloat() / 100f).coerceIn(0f, 1f)
                    val prevY = height - (prevNormY * height)

                    val cx = (prevX + x) / 2
                    path.cubicTo(cx, prevY, cx, y, x, y)
                    fillPath.cubicTo(cx, prevY, cx, y, x, y)
                }
            }

            fillPath.lineTo(width, height)
            fillPath.close()

            // Draw Area Fill Gradient
            drawPath(
                path = fillPath,
                brush = Brush.verticalGradient(
                    colors = listOf(primaryColor.copy(alpha = 0.35f), Color.Transparent),
                    startY = 0f,
                    endY = height
                )
            )

            // Draw Stroke Line
            drawPath(
                path = path,
                color = primaryColor,
                style = Stroke(width = 3.dp.toPx(), cap = StrokeCap.Round)
            )

            // Draw Points
            dataPoints.forEachIndexed { index, point ->
                val x = index * stepX
                val normalizedY = (point.adherencePercent.toFloat() / 100f).coerceIn(0f, 1f)
                val y = height - (normalizedY * height)

                drawCircle(
                    color = Color.White,
                    radius = 4.dp.toPx(),
                    center = Offset(x, y)
                )
                drawCircle(
                    color = primaryColor,
                    radius = 3.dp.toPx(),
                    center = Offset(x, y)
                )
            }
        }

        // X-Axis Labels (First, Middle, Last)
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = dataPoints.first().label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            if (dataPoints.size > 2) {
                Text(
                    text = dataPoints[dataPoints.size / 2].label,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Text(
                text = dataPoints.last().label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
