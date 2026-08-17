package com.productivity.habits.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Upsert
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface HabitCategoryDao {

    @Query("SELECT * FROM habit_categories ORDER BY name ASC")
    fun getAllCategories(): Flow<List<HabitCategoryEntity>>

    @Query("SELECT * FROM habit_categories ORDER BY name ASC")
    suspend fun getAllCategoriesOnce(): List<HabitCategoryEntity>

    @Query("SELECT * FROM habit_categories WHERE id = :id")
    fun getCategoryById(id: String): Flow<HabitCategoryEntity?>

    @Query("SELECT * FROM habit_categories WHERE id = :id")
    suspend fun getCategoryByIdOnce(id: String): HabitCategoryEntity?

    @Upsert
    suspend fun upsertCategory(category: HabitCategoryEntity)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertDefaultCategories(categories: List<HabitCategoryEntity>)

    @Update
    suspend fun updateCategory(category: HabitCategoryEntity)

    @Delete
    suspend fun deleteCategory(category: HabitCategoryEntity)

    @Query("DELETE FROM habit_categories WHERE id = :id")
    suspend fun deleteCategoryById(id: String)
}
