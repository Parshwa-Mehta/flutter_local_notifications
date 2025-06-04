package com.dexterous.flutterlocalnotifications;

import android.app.Notification;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.Keep;
import androidx.core.app.NotificationManagerCompat;

import com.dexterous.flutterlocalnotifications.models.NotificationDetails;
import com.dexterous.flutterlocalnotifications.utils.StringUtils;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;

/** Created by michaelbui on 24/3/18. */
@Keep
public class ScheduledNotificationReceiver extends BroadcastReceiver {

  private static final String TAG = "ScheduledNotifReceiver";

  @Override
  @SuppressWarnings("deprecation")
  public void onReceive(final Context context, Intent intent) {
    Log.d(TAG, "[flutter_local_notification package internal flow] ScheduledNotificationReceiver.onReceive() called");
    
    String notificationDetailsJson =
        intent.getStringExtra(FlutterLocalNotificationsPlugin.NOTIFICATION_DETAILS);
    Log.d(TAG, "[flutter_local_notification package internal flow] Notification details JSON: " + (notificationDetailsJson != null ? "present" : "null"));
    
    if (StringUtils.isNullOrEmpty(notificationDetailsJson)) {
      Log.d(TAG, "[flutter_local_notification package internal flow] Using legacy notification handling (pre-0.3.4)");
      // This logic is needed for apps that used the plugin prior to 0.3.4

      Notification notification;
      int notificationId = intent.getIntExtra("notification_id", 0);
      Log.d(TAG, "[flutter_local_notification package internal flow] Legacy notification ID: " + notificationId);

      if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
        notification = intent.getParcelableExtra("notification", Notification.class);
      } else {
        notification = intent.getParcelableExtra("notification");
      }

      if (notification == null) {
        // This means the notification is corrupt
        Log.e(TAG, "[flutter_local_notification package internal flow] Failed to parse notification from Intent. ID: " + notificationId + " - removing from cache");
        FlutterLocalNotificationsPlugin.removeNotificationFromCache(context, notificationId);
        Log.e(TAG, "Failed to parse a notification from  Intent. ID: " + notificationId);
        return;
      }

      Log.d(TAG, "[flutter_local_notification package internal flow] Showing legacy notification");
      notification.when = System.currentTimeMillis();
      NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);
      notificationManager.notify(notificationId, notification);
      boolean repeat = intent.getBooleanExtra("repeat", false);
      if (!repeat) {
        Log.d(TAG, "[flutter_local_notification package internal flow] Removing non-repeating notification from cache");
        FlutterLocalNotificationsPlugin.removeNotificationFromCache(context, notificationId);
      }
    } else {
      Log.d(TAG, "[flutter_local_notification package internal flow] Using modern notification handling");
      Gson gson = FlutterLocalNotificationsPlugin.buildGson();
      Type type = new TypeToken<NotificationDetails>() {}.getType();
      NotificationDetails notificationDetails = gson.fromJson(notificationDetailsJson, type);
      Log.d(TAG, "[flutter_local_notification package internal flow] Parsed notification details for ID: " + notificationDetails.id);

      FlutterLocalNotificationsPlugin.showNotification(context, notificationDetails);
      FlutterLocalNotificationsPlugin.scheduleNextNotification(context, notificationDetails);
      Log.d(TAG, "[flutter_local_notification package internal flow] Notification shown and next occurrence scheduled");
    }
  }
}
