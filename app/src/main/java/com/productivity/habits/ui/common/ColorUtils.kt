package com.productivity.habits.ui.common

import androidx.compose.ui.graphics.Color

object ColorUtils {

    fun parseHexColor(hexString: String?, defaultColor: Color = Color(0xFF10B981)): Color {
        if (hexString.isNullOrBlank()) return defaultColor
        return try {
            val cleanHex = hexString.trim().removePrefix("#")
            when (cleanHex.length) {
                6 -> {
                    val colorInt = cleanHex.toLong(16)
                    Color(0xFF000000 or colorInt)
                }
                8 -> {
                    val colorInt = cleanHex.toLong(16)
                    Color(colorInt)
                }
                else -> defaultColor
            }
        } catch (e: Exception) {
            defaultColor
        }
    }
}
