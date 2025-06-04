package com.dexterous.flutterlocalnotifications;

import android.app.Notification;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

import java.util.ArrayList;

public class ForegroundService extends Service {

  private static final String TAG = "ForegroundService";

  @Override
  @SuppressWarnings("deprecation")
  public int onStartCommand(Intent intent, int flags, int startId) {
    Log.d(TAG, "[flutter_local_notification package internal flow] ForegroundService.onStartCommand() called");
    Log.d(TAG, "[flutter_local_notification package internal flow] Intent: " + intent + ", flags: " + flags + ", startId: " + startId);
    
    if (intent == null) {
      Log.e(TAG, "[flutter_local_notification package internal flow] Intent is null! This will cause a crash.");
      // Return START_NOT_STICKY to prevent the service from being restarted with null intent
      return START_NOT_STICKY;
    }

    ForegroundServiceStartParameter parameter;
    try {
      if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
        Log.d(TAG, "[flutter_local_notification package internal flow] Using TIRAMISU+ getSerializableExtra method");
        parameter =
            (ForegroundServiceStartParameter)
                intent.getSerializableExtra(
                    ForegroundServiceStartParameter.EXTRA, ForegroundServiceStartParameter.class);
      } else {
        Log.d(TAG, "[flutter_local_notification package internal flow] Using legacy getSerializableExtra method");
        parameter =
            (ForegroundServiceStartParameter)
                intent.getSerializableExtra(ForegroundServiceStartParameter.EXTRA);
      }
      
      if (parameter == null) {
        Log.e(TAG, "[flutter_local_notification package internal flow] ForegroundServiceStartParameter is null! Cannot start foreground service.");
        return START_NOT_STICKY;
      }
      
      Log.d(TAG, "[flutter_local_notification package internal flow] Successfully extracted ForegroundServiceStartParameter");
    } catch (Exception e) {
      Log.e(TAG, "[flutter_local_notification package internal flow] Exception while extracting parameter: " + e.getMessage());
      return START_NOT_STICKY;
    }

    try {
      Notification notification =
          FlutterLocalNotificationsPlugin.createNotification(this, parameter.notificationData);
      Log.d(TAG, "[flutter_local_notification package internal flow] Created notification for foreground service");
      
      if (parameter.foregroundServiceTypes != null
          && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        Log.d(TAG, "[flutter_local_notification package internal flow] Starting foreground service with service types");
        startForeground(
            parameter.notificationData.id,
            notification,
            orCombineFlags(parameter.foregroundServiceTypes));
      } else {
        Log.d(TAG, "[flutter_local_notification package internal flow] Starting foreground service without service types");
        startForeground(parameter.notificationData.id, notification);
      }
      
      Log.d(TAG, "[flutter_local_notification package internal flow] Foreground service started successfully, returning start mode: " + parameter.startMode);
      return parameter.startMode;
    } catch (Exception e) {
      Log.e(TAG, "[flutter_local_notification package internal flow] Exception while starting foreground service: " + e.getMessage());
      return START_NOT_STICKY;
    }
  }

  private static int orCombineFlags(ArrayList<Integer> flags) {
    int flag = flags.get(0);
    for (int i = 1; i < flags.size(); i++) {
      flag |= flags.get(i);
    }
    return flag;
  }

  @Override
  public IBinder onBind(Intent intent) {
    Log.d(TAG, "[flutter_local_notification package internal flow] ForegroundService.onBind() called");
    return null;
  }
}
