package com.productivity.habits.widget

import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.productivity.habits.MainActivity

enum class WidgetLayoutSize {
    SMALL,   // ~2x1
    MEDIUM,  // ~2x2
    LARGE    // ~4x2+
}

fun resolveWidgetLayoutSize(size: DpSize): WidgetLayoutSize {
    return when {
        size.height < 110.dp || size.width < 180.dp -> WidgetLayoutSize.SMALL
        size.width < 260.dp -> WidgetLayoutSize.MEDIUM
        else -> WidgetLayoutSize.LARGE
    }
}

object WidgetColors {
    val Background = Color(0xFF111C1A)
    val Surface = Color(0xFF172522)
    val SurfaceElevated = Color(0xFF1F332F)
    val Primary = Color(0xFF14B8A6)
    val PrimaryContainer = Color(0xFF112C26)
    val AccentAmber = Color(0xFFF59E0B)
    val Success = Color(0xFF10B981)
    val Error = Color(0xFFEF4444)
    val TextPrimary = Color(0xFFF1F5F4)
    val TextSecondary = Color(0xFF96ABA6)
    val Border = Color(0xFF263936)
    val CheckInactive = Color(0xFF263936)
    val CheckActive = Color(0xFF10B981)
    val ProgressBarTrack = Color(0xFF1F332F)
    val ProgressBarFill = Color(0xFF14B8A6)
}

fun createDeepLinkIntent(uriString: String): Intent {
    return Intent(Intent.ACTION_VIEW, Uri.parse(uriString)).apply {
        setClassName("com.productivity.habits", "com.productivity.habits.MainActivity")
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
    }
}

@Composable
fun WidgetCard(
    modifier: GlanceModifier = GlanceModifier,
    padding: Dp = 12.dp,
    deepLinkUri: String? = null,
    content: @Composable () -> Unit
) {
    val baseModifier = GlanceModifier
        .fillMaxSize()
        .background(WidgetColors.Background)
        .cornerRadius(16.dp)

    val clickModifier = if (deepLinkUri != null) {
        baseModifier.clickable(actionStartActivity(createDeepLinkIntent(deepLinkUri)))
    } else {
        baseModifier
    }

    Box(
        modifier = clickModifier
            .then(modifier)
            .padding(padding)
    ) {
        content()
    }
}

@Composable
fun WidgetHeader(
    title: String,
    badgeText: String? = null,
    badgeColor: Color = WidgetColors.Primary,
    deepLinkUri: String? = null
) {
    val headerModifier = if (deepLinkUri != null) {
        GlanceModifier
            .fillMaxWidth()
            .clickable(actionStartActivity(createDeepLinkIntent(deepLinkUri)))
    } else {
        GlanceModifier.fillMaxWidth()
    }

    Row(
        modifier = headerModifier,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = TextStyle(
                color = ColorProvider(WidgetColors.TextPrimary),
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold
            ),
            modifier = GlanceModifier.defaultWeight()
        )

        if (!badgeText.isNullOrBlank()) {
            Box(
                modifier = GlanceModifier
                    .background(WidgetColors.SurfaceElevated)
                    .cornerRadius(6.dp)
                    .padding(horizontal = 6.dp, vertical = 2.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = badgeText,
                    style = TextStyle(
                        color = ColorProvider(badgeColor),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }
        }
    }
}

@Composable
fun WidgetProgressBar(
    progressFraction: Float,
    modifier: GlanceModifier = GlanceModifier,
    height: Dp = 6.dp,
    fillColor: Color = WidgetColors.ProgressBarFill,
    trackColor: Color = WidgetColors.ProgressBarTrack
) {
    val clamped = progressFraction.coerceIn(0f, 1f)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .background(trackColor)
            .cornerRadius(height / 2)
    ) {
        if (clamped > 0.02f) {
            Row(modifier = GlanceModifier.fillMaxSize()) {
                Box(
                    modifier = GlanceModifier
                        .defaultWeight()
                        .fillMaxHeight()
                        .background(fillColor)
                        .cornerRadius(height / 2)
                ) {}
                if (clamped < 0.99f) {
                    val remainingWeight = (1f - clamped) / clamped
                    Spacer(modifier = GlanceModifier.defaultWeight())
                }
            }
        }
    }
}

@Composable
fun WidgetEmptyState(
    message: String,
    actionText: String? = null,
    actionDeepLink: String? = null
) {
    Column(
        modifier = GlanceModifier.fillMaxSize(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = message,
            style = TextStyle(
                color = ColorProvider(WidgetColors.TextSecondary),
                fontSize = 12.sp
            )
        )

        if (!actionText.isNullOrBlank() && !actionDeepLink.isNullOrBlank()) {
            Spacer(modifier = GlanceModifier.height(6.dp))
            Box(
                modifier = GlanceModifier
                    .background(WidgetColors.SurfaceElevated)
                    .cornerRadius(8.dp)
                    .padding(horizontal = 10.dp, vertical = 4.dp)
                    .clickable(actionStartActivity(createDeepLinkIntent(actionDeepLink))),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = actionText,
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.Primary),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }
        }
    }
}
