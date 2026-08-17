package com.productivity.habits.di

import com.productivity.habits.data.scheduler.NoOpHabitReminderScheduler
import com.productivity.habits.domain.scheduler.HabitReminderScheduler
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class SchedulerModule {

    @Binds
    @Singleton
    abstract fun bindHabitReminderScheduler(
        impl: NoOpHabitReminderScheduler
    ): HabitReminderScheduler
}
