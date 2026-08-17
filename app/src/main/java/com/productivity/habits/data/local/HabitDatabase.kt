package com.productivity.habits.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.productivity.habits.data.local.converters.HabitConverters
import com.productivity.habits.data.local.dao.HabitCategoryDao
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.data.local.dao.HabitLogDao
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitLogEntity

@Database(
    entities = [
        HabitEntity::class,
        HabitLogEntity::class,
        HabitCategoryEntity::class
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(HabitConverters::class)
abstract class HabitDatabase : RoomDatabase() {
    abstract fun habitDao(): HabitDao
    abstract fun habitLogDao(): HabitLogDao
    abstract fun habitCategoryDao(): HabitCategoryDao
}
