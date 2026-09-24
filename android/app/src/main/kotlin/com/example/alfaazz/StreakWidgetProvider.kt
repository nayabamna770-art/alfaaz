package com.example.alfaazz

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class StreakWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val streakCount = widgetData.getInt("streak_count", 0)
        val mascotMood = widgetData.getString("mascot_mood", "happy")
        val mascotDrawable = when (mascotMood) {
            "worried" -> R.drawable.mascot_worried
            "angry" -> R.drawable.mascot_angry
            else -> R.drawable.mascot_happy
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.streak_widget)
            views.setTextViewText(R.id.widget_streak_count, streakCount.toString())
            views.setImageViewResource(R.id.widget_mascot_image, mascotDrawable)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
