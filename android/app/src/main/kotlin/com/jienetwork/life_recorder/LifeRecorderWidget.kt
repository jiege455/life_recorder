package com.jienetwork.life_recorder

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent

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
            val mood = prefs.getString("mood_$appWidgetId", "\u5E73\u9759") ?: "\u5E73\u9759"
            val count = prefs.getInt("count_$appWidgetId", 0)

            val views = RemoteViews(context.packageName, R.layout.widget_life_recorder)
            views.setTextViewText(R.id.widget_title, "AI\u4EBA\u751F\u8BB0\u5F55\u5668")
            views.setTextViewText(R.id.widget_mood, "\u4ECA\u65E5\u5FC3\u60C5\uFF1A$mood")
            views.setTextViewText(R.id.widget_count, "\u672C\u5468\u8BB0\u5F55\uFF1A${count}\u6761")

            val intent = Intent(context, MainActivity::class.java)
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
