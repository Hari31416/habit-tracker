# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn com.google.android.play.core.**

# WorkManager & Room
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.CoroutineWorker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.** { *; }

# AndroidX Startup
-keep class androidx.startup.** { *; }
-keep class * extends androidx.startup.Initializer { *; }

# AndroidX Room
-keep class * extends androidx.room.RoomDatabase { *; }
-dontwarn androidx.room.paging.**

# Google Health Connect
-keep class androidx.health.connect.** { *; }
-keep class androidx.health.platform.client.** { *; }
-keep interface androidx.health.connect.** { *; }
-keep class androidx.health.connect.client.records.** { *; }
-keep class androidx.health.connect.client.aggregate.** { *; }
-keep class androidx.health.connect.client.response.** { *; }
-keep class androidx.health.connect.client.units.** { *; }

# Application Native Classes, Receivers & Workers
-keep class app.phial.habits.** { *; }
-keepclassmembers class app.phial.habits.** { *; }

# Kotlin Coroutines & Guava
-keep class kotlinx.coroutines.guava.** { *; }
-dontwarn kotlinx.coroutines.guava.**
-dontwarn java.lang.instrument.ClassFileTransformer

# SQLite & Desugaring
-keep class org.sqlite.** { *; }
-keep class androidx.sqlite.** { *; }
-dontwarn java.time.**
