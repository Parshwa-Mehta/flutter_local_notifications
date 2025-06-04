package com.dexterous.flutterlocalnotifications;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.Keep;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import androidx.core.app.NotificationManagerCompat;

import com.dexterous.flutterlocalnotifications.isolate.IsolatePreferences;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.view.FlutterCallbackInformation;

public class ActionBroadcastReceiver extends BroadcastReceiver {
  public static final String ACTION_TAPPED =
      "com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver.ACTION_TAPPED";
  private static final String TAG = "ActionBroadcastReceiver";
  @Nullable private static ActionEventSink actionEventSink;
  @Nullable private static FlutterEngine engine;
  IsolatePreferences preferences;

  @VisibleForTesting
  ActionBroadcastReceiver(IsolatePreferences preferences) {
    this.preferences = preferences;
  }

  @Keep
  public ActionBroadcastReceiver() {}

  @Override
  public void onReceive(Context context, Intent intent) {
    Log.d(TAG, "[flutter_local_notification package internal flow] ActionBroadcastReceiver.onReceive() called with action: " + intent.getAction());
    
    if (!ACTION_TAPPED.equalsIgnoreCase(intent.getAction())) {
      Log.d(TAG, "[flutter_local_notification package internal flow] Action not recognized, ignoring");
      return;
    }

    preferences = preferences == null ? new IsolatePreferences(context) : preferences;

    final Map<String, Object> action =
        FlutterLocalNotificationsPlugin.extractNotificationResponseMap(intent);
    Log.d(TAG, "[flutter_local_notification package internal flow] Extracted notification response: " + action);

    if (intent.getBooleanExtra(FlutterLocalNotificationsPlugin.CANCEL_NOTIFICATION, false)) {
      int notificationId = (int) action.get(FlutterLocalNotificationsPlugin.NOTIFICATION_ID);
      Object tag = action.get(FlutterLocalNotificationsPlugin.NOTIFICATION_TAG);
      Log.d(TAG, "[flutter_local_notification package internal flow] Cancelling notification ID: " + notificationId + ", tag: " + tag);

      if (tag instanceof String) {
        NotificationManagerCompat.from(context).cancel((String) tag, notificationId);
      } else {
        NotificationManagerCompat.from(context).cancel(notificationId);
      }
    }

    if (actionEventSink == null) {
      Log.d(TAG, "[flutter_local_notification package internal flow] Creating new ActionEventSink");
      actionEventSink = new ActionEventSink();
    }
    actionEventSink.addItem(action);
    Log.d(TAG, "[flutter_local_notification package internal flow] Added action to event sink");

    startEngine(context);
  }

  private void startEngine(Context context) {
    Log.d(TAG, "[flutter_local_notification package internal flow] startEngine() called");
    
    if (engine != null) {
      Log.e(TAG, "[flutter_local_notification package internal flow] Engine is already initialised");
      return;
    }

    Log.d(TAG, "[flutter_local_notification package internal flow] Initializing Flutter engine for background isolate");
    FlutterInjector injector = FlutterInjector.instance();
    FlutterLoader loader = injector.flutterLoader();

    loader.startInitialization(context);
    loader.ensureInitializationComplete(context, null);

    engine = new FlutterEngine(context);
    Log.d(TAG, "[flutter_local_notification package internal flow] Flutter engine created");

    /// This lookup needs to be done after creating an instance of `FlutterEngine` or lookup may
    // fail
    FlutterCallbackInformation dispatcherHandle = preferences.lookupDispatcherHandle();
    if (dispatcherHandle == null) {
      Log.w(TAG, "[flutter_local_notification package internal flow] Callback information could not be retrieved");
      return;
    }
    Log.d(TAG, "[flutter_local_notification package internal flow] Retrieved dispatcher handle: " + dispatcherHandle.callbackName);

    DartExecutor dartExecutor = engine.getDartExecutor();

    initializeEventChannel(dartExecutor);
    Log.d(TAG, "[flutter_local_notification package internal flow] Event channel initialized");

    String dartBundlePath = loader.findAppBundlePath();
    Log.d(TAG, "[flutter_local_notification package internal flow] Executing Dart callback in background isolate");
    dartExecutor.executeDartCallback(
        new DartExecutor.DartCallback(context.getAssets(), dartBundlePath, dispatcherHandle));
  }

  private void initializeEventChannel(DartExecutor dartExecutor) {
    EventChannel channel =
        new EventChannel(
            dartExecutor.getBinaryMessenger(), "dexterous.com/flutter/local_notifications/actions");
    channel.setStreamHandler(actionEventSink);
  }

  private static class ActionEventSink implements StreamHandler {

    final List<Map<String, Object>> cache = new ArrayList<>();

    @Nullable private EventSink eventSink;

    public void addItem(Map<String, Object> item) {
      if (eventSink != null) {
        eventSink.success(item);
      } else {
        cache.add(item);
      }
    }

    @Override
    public void onListen(Object arguments, EventSink events) {
      for (Map<String, Object> item : cache) {
        events.success(item);
      }

      cache.clear();
      eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
      eventSink = null;
    }
  }
}
