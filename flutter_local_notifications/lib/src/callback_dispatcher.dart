// ignore_for_file: lines_longer_than_80_chars

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

// ignore_for_file: public_member_api_docs, avoid_annotating_with_dynamic
@pragma('vm:entry-point')
void callbackDispatcher() {
  debugPrint(
      '[flutter_local_notification package internal flow] callbackDispatcher() entry point called');
  WidgetsFlutterBinding.ensureInitialized();

  const EventChannel backgroundChannel =
      EventChannel('dexterous.com/flutter/local_notifications/actions');

  const MethodChannel channel =
      MethodChannel('dexterous.com/flutter/local_notifications');

  debugPrint(
      '[flutter_local_notification package internal flow] Getting callback handle from native');
  channel.invokeMethod<int>('getCallbackHandle').then((int? handle) {
    debugPrint(
        '[flutter_local_notification package internal flow] Received callback handle: $handle');
    final DidReceiveBackgroundNotificationResponseCallback? callback =
        handle == null
            ? null
            : PluginUtilities.getCallbackFromHandle(
                    CallbackHandle.fromRawHandle(handle))
                as DidReceiveBackgroundNotificationResponseCallback?;

    if (callback == null) {
      debugPrint(
          '[flutter_local_notification package internal flow] No background callback found');
    } else {
      debugPrint(
          '[flutter_local_notification package internal flow] Background callback found, setting up stream listener');
    }

    backgroundChannel
        .receiveBroadcastStream()
        .map<Map<dynamic, dynamic>>((dynamic event) => event)
        .map<Map<String, dynamic>>(
            (Map<dynamic, dynamic> event) => Map.castFrom(event))
        .listen((Map<String, dynamic> event) {
      debugPrint(
          '[flutter_local_notification package internal flow] Background notification event received: $event');
      final Object notificationId = event['notificationId'];
      final int id;
      if (notificationId is int) {
        id = notificationId;
      } else if (notificationId is String) {
        id = int.parse(notificationId);
      } else {
        id = -1;
      }
      debugPrint(
          '[flutter_local_notification package internal flow] Invoking background callback for notification ID: $id');
      callback?.call(NotificationResponse(
        id: id,
        actionId: event['actionId'],
        input: event['input'],
        payload: event['payload'],
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
      ));
    });
  });
}
