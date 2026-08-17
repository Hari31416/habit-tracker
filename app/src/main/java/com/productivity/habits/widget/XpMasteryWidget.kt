package com.productivity.habits.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.productivity.habits.domain.gamification.GamificationEngine
import com.productivity.habits.domain.gamification.PlayerProgression
import com.productivity.habits.domain.gamification.PlayerTitle
import com.productivity.habits.domain.repository.GamificationRepository
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext

data class XpMasteryWidgetData(
    val progression: PlayerProgression,
    val xpNeededForNextLevel: Long,
    val nextTitle: PlayerTitle?
)

class XpMasteryWidget : GlanceAppWidget() {

    override val sizeMode: SizeMode = SizeMode.Exact

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface XpMasteryEntryPoint {
        fun gamificationRepository(): GamificationRepository
    }

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            XpMasteryEntryPoint::class.java
        )

        val data = withContext(Dispatchers.IO) {
            val progression = entryPoint.gamificationRepository().getPlayerProgression().first()
            val xpNeeded = (progression.nextLevelTargetXp - progression.totalXp).coerceAtLeast(0L)
            val nextTitle = PlayerTitle.nextTitle(progression.level)

            XpMasteryWidgetData(
                progression = progression,
                xpNeededForNextLevel = xpNeeded,
                nextTitle = nextTitle
            )
        }

        provideContent {
            GlanceTheme {
                val layoutSize = resolveWidgetLayoutSize(LocalSize.current)
                when (layoutSize) {
                    WidgetLayoutSize.SMALL -> XpMasterySmall(data)
                    WidgetLayoutSize.MEDIUM -> XpMasteryMedium(data)
                    WidgetLayoutSize.LARGE -> XpMasteryLarge(data)
                }
            }
        }
    }
}

@Composable
fun XpMasterySmall(data: XpMasteryWidgetData) {
    val prog = data.progression

    WidgetCard(padding = 10.dp, deepLinkUri = "app://habits/badges") {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Lv.${prog.level} ${prog.title.displayName}",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.TextPrimary),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    ),
                    modifier = GlanceModifier.defaultWeight()
                )

                Text(
                    text = "${prog.totalXp} XP",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.Primary),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }

            Spacer(modifier = GlanceModifier.height(6.dp))

            WidgetProgressBar(progressFraction = prog.progressFraction, height = 5.dp)
        }
    }
}

@Composable
fun XpMasteryMedium(data: XpMasteryWidgetData) {
    val prog = data.progression

    WidgetCard(padding = 12.dp, deepLinkUri = "app://habits/badges") {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            WidgetHeader(
                title = "Lv.${prog.level} ${prog.title.displayName}",
                badgeText = "${prog.unlockedBadgesCount}/${prog.totalBadgesCount} Badges",
                badgeColor = WidgetColors.AccentAmber
            )

            Spacer(modifier = GlanceModifier.height(6.dp))

            Text(
                text = "${prog.totalXp} XP",
                style = TextStyle(
                    color = ColorProvider(WidgetColors.Primary),
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold
                )
            )

            Spacer(modifier = GlanceModifier.height(6.dp))

            WidgetProgressBar(progressFraction = prog.progressFraction, height = 6.dp)

            Spacer(modifier = GlanceModifier.height(8.dp))

            val nextText = if (data.nextTitle != null) {
                "${data.xpNeededForNextLevel} XP to ${data.nextTitle.displayName}"
            } else {
                "${data.xpNeededForNextLevel} XP to Level ${prog.level + 1}"
            }

            Text(
                text = nextText,
                style = TextStyle(
                    color = ColorProvider(WidgetColors.TextSecondary),
                    fontSize = 11.sp
                )
            )
        }
    }
}

@Composable
fun XpMasteryLarge(data: XpMasteryWidgetData) {
    val prog = data.progression

    WidgetCard(padding = 12.dp, deepLinkUri = "app://habits/badges") {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            WidgetHeader(
                title = "Level ${prog.level} - ${prog.title.displayName}",
                badgeText = "${prog.unlockedBadgesCount}/${prog.totalBadgesCount} Badges Unlocked",
                badgeColor = WidgetColors.AccentAmber
            )

            Spacer(modifier = GlanceModifier.height(8.dp))

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "${prog.totalXp} / ${prog.nextLevelTargetXp} XP",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.Primary),
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    ),
                    modifier = GlanceModifier.defaultWeight()
                )

                val percent = (prog.progressFraction * 100).toInt()
                Text(
                    text = "$percent%",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.TextSecondary),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }

            Spacer(modifier = GlanceModifier.height(6.dp))

            WidgetProgressBar(progressFraction = prog.progressFraction, height = 6.dp)

            Spacer(modifier = GlanceModifier.height(8.dp))

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                val nextMilestone = if (data.nextTitle != null) {
                    "${data.xpNeededForNextLevel} XP to ${data.nextTitle.displayName}"
                } else {
                    "${data.xpNeededForNextLevel} XP to Level ${prog.level + 1}"
                }

                Text(
                    text = nextMilestone,
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.TextPrimary),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium
                    ),
                    modifier = GlanceModifier.defaultWeight()
                )

                if (prog.activeStreakMultiplier > 1.0) {
                    Box(
                        modifier = GlanceModifier
                            .background(WidgetColors.SurfaceElevated)
                            .cornerRadius(6.dp)
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = "${prog.activeStreakMultiplier}x Multiplier",
                            style = TextStyle(
                                color = ColorProvider(WidgetColors.AccentAmber),
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold
                            )
                        )
                    }
                }
            }
        }
    }
}
