package com.dexterous.flutterlocalnotifications;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.Keep;

@Keep
public class ScheduledNotificationBootReceiver extends BroadcastReceiver {
  
  private static final String TAG = "BootReceiver";
  
  @Override
  @SuppressWarnings("deprecation")
  public void onReceive(final Context context, Intent intent) {
    Log.d(TAG, "[flutter_local_notification package internal flow] ScheduledNotificationBootReceiver.onReceive() called");
    String action = intent.getAction();
    Log.d(TAG, "[flutter_local_notification package internal flow] Received action: " + action);
    
    if (action != null) {
      if (action.equals(android.content.Intent.ACTION_BOOT_COMPLETED)
          || action.equals(Intent.ACTION_MY_PACKAGE_REPLACED)
          || action.equals("android.intent.action.QUICKBOOT_POWERON")
          || action.equals("com.htc.intent.action.QUICKBOOT_POWERON")) {
        Log.d(TAG, "[flutter_local_notification package internal flow] Triggering notification rescheduling for action: " + action);
        FlutterLocalNotificationsPlugin.rescheduleNotifications(context);
        Log.d(TAG, "[flutter_local_notification package internal flow] Notification rescheduling completed");
      } else {
        Log.d(TAG, "[flutter_local_notification package internal flow] Action not handled: " + action);
      }
    } else {
      Log.w(TAG, "[flutter_local_notification package internal flow] Received null action");
    }
  }
}
