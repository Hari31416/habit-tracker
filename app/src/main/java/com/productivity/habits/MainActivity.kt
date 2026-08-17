package com.productivity.habits

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.productivity.habits.service.TimerStateHolder
import com.productivity.habits.ui.navigation.HabitNavGraph
import com.productivity.habits.ui.theme.HabitTrackerTheme
import androidx.compose.foundation.isSystemInDarkTheme
import com.productivity.habits.data.local.preferences.ThemeMode
import com.productivity.habits.data.local.preferences.ThemePreferences
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var themePreferences: ThemePreferences

    private val requestNotificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        // Permission granted or denied
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                requestNotificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }

        setContent {
            val themeMode by themePreferences.themeMode.collectAsState()
            val isDarkTheme = when (themeMode) {
                ThemeMode.SYSTEM -> isSystemInDarkTheme()
                ThemeMode.LIGHT -> false
                ThemeMode.DARK -> true
            }

            FocusModeEffect()

            HabitTrackerTheme(darkTheme = isDarkTheme) {
                Surface(modifier = Modifier.fillMaxSize()) {
                    HabitNavGraph(
                        themeMode = themeMode,
                        onThemeModeSelected = { themePreferences.setThemeMode(it) },
                        themePreferences = themePreferences
                    )
                }
            }
        }
    }

    /**
     * Observes the focus timer state and toggles immersive mode (hidden system bars)
     * and keep-screen-on when the timer is actively running or paused.
     */
    @Composable
    private fun FocusModeEffect() {
        val timerState by TimerStateHolder.timerState.collectAsState()
        val focusActive = timerState.focusModeActive

        LaunchedEffect(focusActive) {
            val insetsController = WindowCompat.getInsetsController(window, window.decorView)

            if (focusActive) {
                // Hide both status bar and navigation bar for immersive experience
                insetsController.systemBarsBehavior =
                    WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                insetsController.hide(WindowInsetsCompat.Type.systemBars())

                // Keep screen awake during focus session
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                // Restore system bars
                insetsController.show(WindowInsetsCompat.Type.systemBars())

                // Allow screen to turn off normally
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }

        // Safety net: ensure we clean up if the composable leaves the composition
        DisposableEffect(Unit) {
            onDispose {
                val insetsController = WindowCompat.getInsetsController(window, window.decorView)
                insetsController.show(WindowInsetsCompat.Type.systemBars())
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }
}
