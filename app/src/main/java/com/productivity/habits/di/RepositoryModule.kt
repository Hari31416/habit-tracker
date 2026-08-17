package com.productivity.habits.di

import com.productivity.habits.data.repository.GamificationRepositoryImpl
import com.productivity.habits.data.repository.HabitRepositoryImpl
import com.productivity.habits.domain.repository.GamificationRepository
import com.productivity.habits.domain.repository.HabitRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindHabitRepository(
        impl: HabitRepositoryImpl
    ): HabitRepository

    @Binds
    @Singleton
    abstract fun bindGamificationRepository(
        impl: GamificationRepositoryImpl
    ): GamificationRepository
}
