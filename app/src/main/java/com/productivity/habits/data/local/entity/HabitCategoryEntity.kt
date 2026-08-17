package com.productivity.habits.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "habit_categories")
data class HabitCategoryEntity(
    @PrimaryKey val id: String,
    val name: String,
    val color: String,
    val icon: String? = null
)
