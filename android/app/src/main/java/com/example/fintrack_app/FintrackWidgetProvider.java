package com.example.fintrack_app;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.widget.RemoteViews;

import android.content.SharedPreferences;

public class FintrackWidgetProvider extends AppWidgetProvider {

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int id : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.fintrack_widget);

            SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);
            String period = prefs.getString("fintrack_period", "");
            String spent = prefs.getString("fintrack_total_spent", "—");
            String remaining = prefs.getString("fintrack_remaining", "—");

            views.setTextViewText(R.id.widget_period, period);
            views.setTextViewText(R.id.widget_spent, spent);
            views.setTextViewText(R.id.widget_remaining, remaining);

            // Tap-to-launch
            Intent launchIntent = new Intent(context, MainActivity.class);
            int flags = PendingIntent.FLAG_UPDATE_CURRENT;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                flags |= PendingIntent.FLAG_IMMUTABLE;
            }
            PendingIntent pi = PendingIntent.getActivity(context, 0, launchIntent, flags);
            views.setOnClickPendingIntent(R.id.widget_root, pi);

            appWidgetManager.updateAppWidget(id, views);
        }
    }

    public static void requestUpdate(Context context) {
        AppWidgetManager mgr = AppWidgetManager.getInstance(context);
        ComponentName name = new ComponentName(context, FintrackWidgetProvider.class);
        int[] ids = mgr.getAppWidgetIds(name);
        Intent intent = new Intent(context, FintrackWidgetProvider.class);
        intent.setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE);
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids);
        context.sendBroadcast(intent);
    }
}
