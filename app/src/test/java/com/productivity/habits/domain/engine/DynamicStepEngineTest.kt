package com.productivity.habits.domain.engine

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class DynamicStepEngineTest {

    @Test
    fun getDynamicStepConfig_milliliters_returnsCorrectSteps() {
        val large = DynamicStepEngine.getDynamicStepConfig(2000.0, "ml")
        assertThat(large.primaryStep).isEqualTo(250.0)
        assertThat(large.quickAddValues).containsExactly(250.0, 500.0, 1000.0).inOrder()

        val medium = DynamicStepEngine.getDynamicStepConfig(500.0, "ml")
        assertThat(medium.primaryStep).isEqualTo(50.0)
        assertThat(medium.quickAddValues).containsExactly(100.0, 250.0).inOrder()

        val small = DynamicStepEngine.getDynamicStepConfig(100.0, "ml")
        assertThat(small.primaryStep).isEqualTo(10.0)
        assertThat(small.quickAddValues).containsExactly(25.0, 50.0).inOrder()
    }

    @Test
    fun getDynamicStepConfig_steps_returnsCorrectSteps() {
        val large = DynamicStepEngine.getDynamicStepConfig(10000.0, "steps")
        assertThat(large.primaryStep).isEqualTo(500.0)
        assertThat(large.quickAddValues).containsExactly(1000.0, 2500.0, 5000.0).inOrder()

        val medium = DynamicStepEngine.getDynamicStepConfig(3000.0, "steps")
        assertThat(medium.primaryStep).isEqualTo(200.0)
        assertThat(medium.quickAddValues).containsExactly(500.0, 1000.0).inOrder()
    }

    @Test
    fun getDynamicStepConfig_calories_returnsCorrectSteps() {
        val large = DynamicStepEngine.getDynamicStepConfig(2000.0, "kcal")
        assertThat(large.primaryStep).isEqualTo(100.0)
        assertThat(large.quickAddValues).containsExactly(250.0, 500.0).inOrder()

        val small = DynamicStepEngine.getDynamicStepConfig(500.0, "cal")
        assertThat(small.primaryStep).isEqualTo(50.0)
        assertThat(small.quickAddValues).containsExactly(100.0, 200.0).inOrder()
    }

    @Test
    fun getDynamicStepConfig_generalNumeric_scalesWithTarget() {
        val small = DynamicStepEngine.getDynamicStepConfig(5.0, "pages")
        assertThat(small.primaryStep).isEqualTo(1.0)
        assertThat(small.quickAddValues).containsExactly(1.0, 2.0).inOrder()

        val mid = DynamicStepEngine.getDynamicStepConfig(100.0, "pages")
        assertThat(mid.primaryStep).isEqualTo(5.0)
        assertThat(mid.quickAddValues).containsExactly(10.0, 25.0).inOrder()

        val big = DynamicStepEngine.getDynamicStepConfig(500.0, "words")
        assertThat(big.primaryStep).isEqualTo(10.0)
        assertThat(big.quickAddValues).containsExactly(25.0, 50.0, 100.0).inOrder()
    }

    @Test
    fun getDynamicTimerConfig_returnsCorrectSteps() {
        val quick = DynamicStepEngine.getDynamicTimerConfig(15.0)
        assertThat(quick.primaryStep).isEqualTo(1.0)
        assertThat(quick.quickAddValues).containsExactly(2.0, 5.0, 10.0).inOrder()

        val pomodoro = DynamicStepEngine.getDynamicTimerConfig(25.0)
        assertThat(pomodoro.primaryStep).isEqualTo(5.0)
        assertThat(pomodoro.quickAddValues).containsExactly(5.0, 10.0, 15.0).inOrder()

        val longSession = DynamicStepEngine.getDynamicTimerConfig(90.0)
        assertThat(longSession.primaryStep).isEqualTo(15.0)
        assertThat(longSession.quickAddValues).containsExactly(15.0, 30.0, 60.0).inOrder()
    }
}
