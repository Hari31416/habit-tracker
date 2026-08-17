package com.productivity.habits.ui.common

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.compose.ui.hapticfeedback.HapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType

object HapticsHelper {

    fun performLightHaptic(haptic: HapticFeedback?) {
        haptic?.performHapticFeedback(HapticFeedbackType.TextHandleMove)
    }

    fun performHeavyConfirmationHaptic(context: Context, haptic: HapticFeedback?) {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }

            if (vibrator != null && vibrator.hasVibrator()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val effect = VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK)
                    vibrator.vibrate(effect)
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(longArrayOf(0, 35, 30, 45), -1)
                }
            } else {
                haptic?.performHapticFeedback(HapticFeedbackType.LongPress)
            }
        } catch (e: Exception) {
            haptic?.performHapticFeedback(HapticFeedbackType.LongPress)
        }
    }
}
