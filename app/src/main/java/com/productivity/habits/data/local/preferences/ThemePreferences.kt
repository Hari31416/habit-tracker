package com.productivity.habits.data.local.preferences

import android.content.Context
import android.content.SharedPreferences
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ThemePreferences @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private val _themeMode = MutableStateFlow(loadThemeMode())
    val themeMode: StateFlow<ThemeMode> = _themeMode.asStateFlow()

    private val _userName = MutableStateFlow(loadUserName())
    val userName: StateFlow<String> = _userName.asStateFlow()

    private val _focusDndEnabled = MutableStateFlow(loadFocusDndEnabled())
    val focusDndEnabled: StateFlow<Boolean> = _focusDndEnabled.asStateFlow()

    private fun loadThemeMode(): ThemeMode {
        val savedName = prefs.getString(KEY_THEME_MODE, ThemeMode.SYSTEM.name)
        return try {
            ThemeMode.valueOf(savedName ?: ThemeMode.SYSTEM.name)
        } catch (e: Exception) {
            ThemeMode.SYSTEM
        }
    }

    private fun loadUserName(): String {
        return prefs.getString(KEY_USER_NAME, "") ?: ""
    }

    private fun loadFocusDndEnabled(): Boolean {
        return prefs.getBoolean(KEY_FOCUS_DND_ENABLED, false)
    }

    fun setThemeMode(mode: ThemeMode) {
        prefs.edit().putString(KEY_THEME_MODE, mode.name).apply()
        _themeMode.value = mode
    }

    fun setUserName(name: String) {
        prefs.edit().putString(KEY_USER_NAME, name.trim()).apply()
        _userName.value = name.trim()
    }

    fun setFocusDndEnabled(enabled: Boolean) {
        prefs.edit().putBoolean(KEY_FOCUS_DND_ENABLED, enabled).apply()
        _focusDndEnabled.value = enabled
    }

    companion object {
        private const val PREFS_NAME = "habit_tracker_theme_prefs"
        private const val KEY_THEME_MODE = "key_theme_mode"
        private const val KEY_USER_NAME = "key_user_name"
        private const val KEY_FOCUS_DND_ENABLED = "key_focus_dnd_enabled"
    }
}

