package app.phial.habits.widgets

import android.graphics.*
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

data class DayAdherence(
    val dayLetter: String,
    val ratePercent: Int,
    val isToday: Boolean,
    val isFuture: Boolean
)

object WidgetGraphicsHelper {

    private const val COLOR_EMERALD = 0xFF10B981.toInt()
    private const val COLOR_TEAL_CYAN = 0xFF14B8A6.toInt()
    private const val COLOR_AMBER = 0xFFF59E0B.toInt()
    private const val COLOR_MUTED = 0xFF9EADA9.toInt()
    private const val COLOR_DARK_MUTED = 0xFF263936.toInt()
    private const val COLOR_SURFACE = 0xFF162320.toInt()
    private const val COLOR_SURFACE_VARIANT = 0xFF20332E.toInt()
    private const val COLOR_TEXT_WHITE = 0xFFF1F5F4.toInt()

    fun drawCircularProgressRing(
        percentage: Int,
        subtitle: String,
        sizeDp: Int,
        strokeWidthDp: Float,
        density: Float,
        showCheckInside: Boolean = false
    ): Bitmap {
        val sizePx = (sizeDp * density).toInt().coerceAtLeast(1)
        val strokePx = strokeWidthDp * density
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val padding = strokePx / 2f + (2f * density)
        val rect = RectF(padding, padding, sizePx - padding, sizePx - padding)

        // 1. Track Paint
        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_SURFACE_VARIANT
            style = Paint.Style.STROKE
            strokeWidth = strokePx
            strokeCap = Paint.Cap.ROUND
        }
        canvas.drawArc(rect, 0f, 360f, false, trackPaint)

        // 2. Progress Arc Paint
        val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_EMERALD
            style = Paint.Style.STROKE
            strokeWidth = strokePx
            strokeCap = Paint.Cap.ROUND
        }
        val sweepAngle = (percentage.coerceIn(0, 100) / 100f) * 360f
        if (sweepAngle > 0f) {
            canvas.drawArc(rect, -90f, sweepAngle, false, progressPaint)
        }

        // 3. Center Content
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_TEXT_WHITE
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }

        val centerX = sizePx / 2f
        val centerY = sizePx / 2f

        if (showCheckInside && percentage >= 100) {
            textPaint.textSize = sizePx * 0.38f
            textPaint.color = COLOR_EMERALD
            val fontMetrics = textPaint.fontMetrics
            val baseline = centerY - (fontMetrics.ascent + fontMetrics.descent) / 2f
            canvas.drawText("✓", centerX, baseline, textPaint)
        } else {
            textPaint.textSize = if (subtitle.isEmpty()) sizePx * 0.32f else sizePx * 0.28f
            val fontMetrics = textPaint.fontMetrics
            val mainBaseline = if (subtitle.isNotEmpty()) {
                centerY - (fontMetrics.descent) - (1f * density)
            } else {
                centerY - (fontMetrics.ascent + fontMetrics.descent) / 2f
            }
            canvas.drawText("$percentage%", centerX, mainBaseline, textPaint)

            if (subtitle.isNotEmpty()) {
                val subPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = COLOR_MUTED
                    textSize = sizePx * 0.14f
                    textAlign = Paint.Align.CENTER
                    typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
                }
                val subMetrics = subPaint.fontMetrics
                val subBaseline = centerY - subMetrics.ascent + (1f * density)
                canvas.drawText(subtitle, centerX, subBaseline, subPaint)
            }
        }

        return bitmap
    }

    fun drawLevelShieldBadge(
        level: Int,
        sizeDp: Int,
        density: Float,
        withRibbon: Boolean = false
    ): Bitmap {
        val widthPx = (sizeDp * density).toInt().coerceAtLeast(1)
        val heightPx = if (withRibbon) (sizeDp * 1.25f * density).toInt() else widthPx
        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val centerX = widthPx / 2f
        val centerY = (widthPx / 2f) * 0.95f
        val radius = (widthPx / 2f) - (3f * density)

        // Ribbon tails for 4x4 variant
        if (withRibbon) {
            val ribbonPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFF0A7A64.toInt()
                style = Paint.Style.FILL
            }
            val leftRibbon = Path().apply {
                moveTo(centerX - radius * 0.5f, centerY + radius * 0.3f)
                lineTo(centerX - radius * 0.9f, heightPx - (2f * density))
                lineTo(centerX - radius * 0.5f, heightPx - (8f * density))
                lineTo(centerX - radius * 0.1f, heightPx - (2f * density))
                close()
            }
            val rightRibbon = Path().apply {
                moveTo(centerX + radius * 0.5f, centerY + radius * 0.3f)
                lineTo(centerX + radius * 0.9f, heightPx - (2f * density))
                lineTo(centerX + radius * 0.5f, heightPx - (8f * density))
                lineTo(centerX + radius * 0.1f, heightPx - (2f * density))
                close()
            }
            canvas.drawPath(leftRibbon, ribbonPaint)
            canvas.drawPath(rightRibbon, ribbonPaint)
        }

        // Draw regular hexagon
        val hexPath = Path()
        for (i in 0 until 6) {
            val angleDeg = 60.0 * i - 30.0
            val angleRad = Math.toRadians(angleDeg)
            val x = (centerX + radius * cos(angleRad)).toFloat()
            val y = (centerY + radius * sin(angleRad)).toFloat()
            if (i == 0) hexPath.moveTo(x, y) else hexPath.lineTo(x, y)
        }
        hexPath.close()

        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_SURFACE
            style = Paint.Style.FILL
        }
        canvas.drawPath(hexPath, fillPaint)

        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_EMERALD
            style = Paint.Style.STROKE
            strokeWidth = 2.5f * density
        }
        canvas.drawPath(hexPath, strokePaint)

        // Inner Level Text
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_TEXT_WHITE
            textSize = radius * 1.05f
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        val fontMetrics = textPaint.fontMetrics
        val baseline = centerY - (fontMetrics.ascent + fontMetrics.descent) / 2f
        canvas.drawText("$level", centerX, baseline, textPaint)

        return bitmap
    }

    fun drawWeeklyBarChart(
        days: List<DayAdherence>,
        widthDp: Int,
        heightDp: Int,
        density: Float
    ): Bitmap {
        val widthPx = (widthDp * density).toInt().coerceAtLeast(1)
        val heightPx = (heightDp * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        if (days.isEmpty()) return bitmap

        val dayCount = days.size
        val colWidth = widthPx.toFloat() / dayCount
        val barWidth = colWidth * 0.48f
        val bottomLabelHeight = 12f * density
        val maxBarHeight = heightPx - bottomLabelHeight - (4f * density)

        val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_MUTED
            textSize = 9f * density
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
        }

        val barPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
        }

        for (i in 0 until dayCount) {
            val day = days[i]
            val colCenter = (i + 0.5f) * colWidth
            val left = colCenter - (barWidth / 2f)
            val right = colCenter + (barWidth / 2f)
            val bottom = heightPx - bottomLabelHeight - (2f * density)

            val frac = if (day.isFuture) 0.1f else (day.ratePercent.coerceIn(0, 100) / 100f).coerceAtLeast(0.12f)
            val barH = maxBarHeight * frac
            val top = bottom - barH

            barPaint.color = when {
                day.isToday -> COLOR_TEAL_CYAN
                day.isFuture -> COLOR_DARK_MUTED
                day.ratePercent >= 75 -> COLOR_EMERALD
                day.ratePercent > 0 -> 0xFF0D9488.toInt()
                else -> COLOR_SURFACE_VARIANT
            }

            val radius = barWidth / 2f
            canvas.drawRoundRect(RectF(left, top, right, bottom), radius, radius, barPaint)

            // Draw Day Letter
            labelPaint.color = if (day.isToday) COLOR_TEAL_CYAN else COLOR_MUTED
            labelPaint.typeface = if (day.isToday) Typeface.create(Typeface.DEFAULT, Typeface.BOLD) else Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
            canvas.drawText(day.dayLetter, colCenter, heightPx - (2f * density), labelPaint)
        }

        return bitmap
    }

    fun drawStreakDots(
        history: List<Boolean>,
        widthDp: Int,
        heightDp: Int,
        density: Float
    ): Bitmap {
        val widthPx = (widthDp * density).toInt().coerceAtLeast(1)
        val heightPx = (heightDp * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        if (history.isEmpty()) return bitmap

        val count = history.size
        val spacing = widthPx.toFloat() / count
        val dotRadius = min(spacing * 0.35f, (heightPx / 2f) * 0.75f)
        val centerY = heightPx / 2f

        val activePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_AMBER
            style = Paint.Style.FILL
        }

        val inactivePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_DARK_MUTED
            style = Paint.Style.FILL
        }

        for (i in 0 until count) {
            val cx = (i + 0.5f) * spacing
            val isDone = history[i]
            canvas.drawCircle(cx, centerY, dotRadius, if (isDone) activePaint else inactivePaint)
        }

        return bitmap
    }

    fun drawHabitStatusDots(
        total: Int,
        completed: Int,
        widthDp: Int,
        heightDp: Int,
        density: Float
    ): Bitmap {
        val widthPx = (widthDp * density).toInt().coerceAtLeast(1)
        val heightPx = (heightDp * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val safeTotal = total.coerceIn(1, 8)
        val spacing = widthPx.toFloat() / safeTotal
        val dotRadius = min(spacing * 0.32f, (heightPx / 2f) * 0.7f)
        val centerY = heightPx / 2f

        val donePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_EMERALD
            style = Paint.Style.FILL
        }

        val pendingPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_MUTED
            style = Paint.Style.STROKE
            strokeWidth = 1.5f * density
        }

        for (i in 0 until safeTotal) {
            val cx = (i + 0.5f) * spacing
            if (i < completed) {
                canvas.drawCircle(cx, centerY, dotRadius, donePaint)
            } else {
                canvas.drawCircle(cx, centerY, dotRadius, pendingPaint)
            }
        }

        return bitmap
    }

    fun drawDropletRow(
        activeCount: Int,
        maxDisplay: Int = 5,
        widthDp: Int,
        heightDp: Int,
        density: Float
    ): Bitmap {
        val widthPx = (widthDp * density).toInt().coerceAtLeast(1)
        val heightPx = (heightDp * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val count = maxDisplay.coerceAtLeast(1)
        val spacing = widthPx.toFloat() / count
        val dropRadius = min(spacing * 0.32f, (heightPx / 2f) * 0.7f)
        val centerY = heightPx / 2f

        val activePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_AMBER
            style = Paint.Style.FILL
        }

        val inactivePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_DARK_MUTED
            style = Paint.Style.FILL
        }

        for (i in 0 until count) {
            val cx = (i + 0.5f) * spacing
            val isActive = i < activeCount
            val paint = if (isActive) activePaint else inactivePaint

            val path = Path().apply {
                moveTo(cx, centerY - dropRadius * 1.35f)
                cubicTo(
                    cx + dropRadius * 1.15f, centerY - dropRadius * 0.1f,
                    cx + dropRadius * 1.15f, centerY + dropRadius * 0.9f,
                    cx, centerY + dropRadius * 1.15f
                )
                cubicTo(
                    cx - dropRadius * 1.15f, centerY + dropRadius * 0.9f,
                    cx - dropRadius * 1.15f, centerY - dropRadius * 0.1f,
                    cx, centerY - dropRadius * 1.35f
                )
                close()
            }
            canvas.drawPath(path, paint)
        }

        return bitmap
    }
}
