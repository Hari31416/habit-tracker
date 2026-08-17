package com.productivity.habits.di

import android.content.Context
import androidx.room.Room
import com.productivity.habits.data.local.HabitDatabase
import com.productivity.habits.data.local.PrepopulateDataCallback
import com.productivity.habits.data.local.dao.HabitCategoryDao
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.data.local.dao.HabitLogDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Provider
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideHabitDatabase(
        @ApplicationContext context: Context,
        categoryDaoProvider: Provider<HabitCategoryDao>
    ): HabitDatabase {
        return Room.databaseBuilder(
            context,
            HabitDatabase::class.java,
            "habits_database"
        )
            .addCallback(PrepopulateDataCallback(categoryDaoProvider))
            .fallbackToDestructiveMigration()
            .build()
    }

    @Provides
    fun provideHabitDao(database: HabitDatabase): HabitDao = database.habitDao()

    @Provides
    fun provideHabitLogDao(database: HabitDatabase): HabitLogDao = database.habitLogDao()

    @Provides
    fun provideHabitCategoryDao(database: HabitDatabase): HabitCategoryDao = database.habitCategoryDao()
}
