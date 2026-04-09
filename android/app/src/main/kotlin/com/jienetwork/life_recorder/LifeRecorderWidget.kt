package com.jienetwork.life_recorder

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity

class LifeRecorderWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "LifeRecorderWidgetPrefs"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val mood = prefs.getString("mood_$appWidgetId", "平静") ?: "平静"
            val count = prefs.getInt("count_$appWidgetId", 0)

            val views = RemoteViews(context.packageName, R.layout.widget_life_recorder)
            views.setTextViewText(R.id.widget_title, "AI人生记录器")
            views.setTextViewText(R.id.widget_mood, "今日心情：$mood")
            views.setTextViewText(R.id.widget_count, "本周记录：${count}条")

            val intent = Intent(context, FlutterFragmentActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onEnabled(context: Context) {
    }

    override fun onDisabled(context: Context) {
    }
}
