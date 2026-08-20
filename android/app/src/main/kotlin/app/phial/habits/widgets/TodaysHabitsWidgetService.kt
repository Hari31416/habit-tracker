package app.phial.habits.widgets

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import app.phial.habits.R
import org.json.JSONArray
import org.json.JSONObject

class TodaysHabitsWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodaysHabitsRemoteViewsFactory(applicationContext, intent)
    }
}

class TodaysHabitsRemoteViewsFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private var habitsArray: JSONArray? = null

    override fun onCreate() {
        loadData()
    }

    override fun onDataSetChanged() {
        loadData()
    }

    private fun loadData() {
        val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("todays_habits", null)
        if (jsonStr != null) {
            try {
                val obj = JSONObject(jsonStr)
                habitsArray = obj.optJSONArray("habits")
            } catch (_: Exception) {
                habitsArray = null
            }
        } else {
            habitsArray = null
        }
    }

    override fun onDestroy() {
        habitsArray = null
    }

    override fun getCount(): Int {
        return habitsArray?.length() ?: 0
    }

    override fun getViewAt(position: Int): RemoteViews {
        val rowView = RemoteViews(context.packageName, R.layout.widget_item_todays_habit)
        val array = habitsArray ?: return rowView
        if (position < 0 || position >= array.length()) return rowView

        try {
            val h = array.getJSONObject(position)
            val id = h.optString("id")
            val title = h.optString("title")
            val isDone = h.optBoolean("isCompleted", false)
            val streak = h.optInt("currentStreak", 0)

            rowView.setTextViewText(R.id.tv_habit_check, if (isDone) "✓" else "○")
            rowView.setTextColor(
                R.id.tv_habit_check,
                if (isDone) Color.parseColor("#10B981") else Color.parseColor("#9EADA9")
            )
            rowView.setTextViewText(R.id.tv_habit_title, title)
            rowView.setTextColor(
                R.id.tv_habit_title,
                if (isDone) Color.parseColor("#10B981") else Color.parseColor("#F1F5F4")
            )
            rowView.setTextViewText(R.id.tv_habit_streak, if (streak > 0) "${streak}d" else "")

            val fillInIntent = Intent().apply {
                putExtra(TodaysHabitsWidgetReceiver.EXTRA_HABIT_ID, id)
            }
            rowView.setOnClickFillInIntent(R.id.ll_habit_row, fillInIntent)
        } catch (_: Exception) {}

        return rowView
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false
}
