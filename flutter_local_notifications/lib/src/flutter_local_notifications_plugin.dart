// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications_linux/flutter_local_notifications_linux.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_local_notifications_windows/flutter_local_notifications_windows.dart';
import 'package:timezone/timezone.dart';

import 'initialization_settings.dart';
import 'notification_details.dart';
import 'platform_flutter_local_notifications.dart';
import 'platform_specifics/android/schedule_mode.dart';
import 'types.dart';

/// Provides cross-platform functionality for displaying local notifications.
///
/// The plugin will check the platform that is running on to use the appropriate
/// platform-specific implementation of the plugin. The plugin methods will be a
/// no-op when the platform can't be detected.
///
/// Use [resolvePlatformSpecificImplementation] and pass the platform-specific
/// type of the plugin to get the underlying platform-specific implementation
/// if access to platform-specific APIs are needed.
class FlutterLocalNotificationsPlugin {
  /// Factory for create an instance of [FlutterLocalNotificationsPlugin].
  factory FlutterLocalNotificationsPlugin() => _instance;

  FlutterLocalNotificationsPlugin._();

  static final FlutterLocalNotificationsPlugin _instance =
      FlutterLocalNotificationsPlugin._();

  /// Returns the underlying platform-specific implementation of given type [T],
  /// which must be a concrete subclass of [FlutterLocalNotificationsPlatform](https://pub.dev/documentation/flutter_local_notifications_platform_interface/latest/flutter_local_notifications_platform_interface/FlutterLocalNotificationsPlatform-class.html)
  ///
  /// Requires running on the appropriate platform that matches the specified
  /// type for a result to be returned. For example, when the specified type
  /// argument is of type [AndroidFlutterLocalNotificationsPlugin], this will
  /// only return a result of that type when running on Android.
  T? resolvePlatformSpecificImplementation<
      T extends FlutterLocalNotificationsPlatform>() {
    if (T == FlutterLocalNotificationsPlatform) {
      throw ArgumentError.value(
          T,
          'The type argument must be a concrete subclass of '
          'FlutterLocalNotificationsPlatform');
    }
    if (kIsWeb) {
      return null;
    }

    if (defaultTargetPlatform == TargetPlatform.android &&
        T == AndroidFlutterLocalNotificationsPlugin &&
        FlutterLocalNotificationsPlatform.instance
            is AndroidFlutterLocalNotificationsPlugin) {
      return FlutterLocalNotificationsPlatform.instance as T?;
    } else if (defaultTargetPlatform == TargetPlatform.iOS &&
        T == IOSFlutterLocalNotificationsPlugin &&
        FlutterLocalNotificationsPlatform.instance
            is IOSFlutterLocalNotificationsPlugin) {
      return FlutterLocalNotificationsPlatform.instance as T?;
    } else if (defaultTargetPlatform == TargetPlatform.macOS &&
        T == MacOSFlutterLocalNotificationsPlugin &&
        FlutterLocalNotificationsPlatform.instance
            is MacOSFlutterLocalNotificationsPlugin) {
      return FlutterLocalNotificationsPlatform.instance as T?;
    } else if (defaultTargetPlatform == TargetPlatform.linux &&
        T == LinuxFlutterLocalNotificationsPlugin &&
        FlutterLocalNotificationsPlatform.instance
            is LinuxFlutterLocalNotificationsPlugin) {
      return FlutterLocalNotificationsPlatform.instance as T?;
    } else if (defaultTargetPlatform == TargetPlatform.windows &&
        T == FlutterLocalNotificationsWindows &&
        FlutterLocalNotificationsPlatform.instance
            is FlutterLocalNotificationsWindows) {
      return FlutterLocalNotificationsPlatform.instance as T?;
    }

    return null;
  }

  /// Initializes the plugin.
  ///
  /// Call this method on application before using the plugin further.
  ///
  /// Will return a [bool] value to indicate if initialization succeeded.
  /// On iOS this is dependent on if permissions have been granted to show
  /// notification When running in environment that is neither Android and
  /// iOS (e.g. when running tests), this will be a no-op and return true.
  ///
  /// Note that on iOS, initialisation may also request notification
  /// permissions where users will see a permissions prompt. This may be fine
  /// in cases where it's acceptable to do this when the application runs for
  /// the first time. However, if your application needs to do this at a later
  /// point in time, set the
  /// [DarwinInitializationSettings.requestAlertPermission],
  /// [DarwinInitializationSettings.requestBadgePermission] and
  /// [DarwinInitializationSettings.requestSoundPermission] values to false.
  /// [IOSFlutterLocalNotificationsPlugin.requestPermissions] can then be called
  /// to request permissions when needed.
  ///
  /// The [onDidReceiveNotificationResponse] callback is fired when the user
  /// selects a notification or notification action that should show the
  /// application/user interface.
  /// application was running. To handle when a notification launched an
  /// application, use [getNotificationAppLaunchDetails]. For notification
  /// actions that don't show the application/user interface, the
  /// [onDidReceiveBackgroundNotificationResponse] callback is invoked on
  /// a background isolate. Functions passed to the
  /// [onDidReceiveBackgroundNotificationResponse]
  /// callback need to be annotated with the `@pragma('vm:entry-point')`
  /// annotation to ensure they are not stripped out by the Dart compiler.
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    debugPrint(
        '[flutter_local_notification package internal flow] FlutterLocalNotificationsPlugin.initialize() called');

    if (kIsWeb) {
      debugPrint(
          '[flutter_local_notification package internal flow] Running on web, returning true');
      return true;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint(
          '[flutter_local_notification package internal flow] Initializing for Android platform');
      if (initializationSettings.android == null) {
        debugPrint(
            '[flutter_local_notification package internal flow] Error: Android settings are null');
        throw ArgumentError(
            'Android settings must be set when targeting Android platform.');
      }

      debugPrint(
          '[flutter_local_notification package internal flow] Resolving Android platform-specific implementation');
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      debugPrint(
          '[flutter_local_notification package internal flow] Android plugin resolved: ${androidPlugin != null ? 'success' : 'failed'}');

      if (androidPlugin != null) {
        debugPrint(
            '[flutter_local_notification package internal flow] Calling Android platform initialize()');
        final bool result = await androidPlugin.initialize(
          initializationSettings.android!,
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
          onDidReceiveBackgroundNotificationResponse:
              onDidReceiveBackgroundNotificationResponse,
        );
        debugPrint(
            '[flutter_local_notification package internal flow] Android platform initialize() completed with result: $result');
        return result;
      } else {
        debugPrint(
            '[flutter_local_notification package internal flow] Android plugin is null, returning null');
        return null;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint(
          '[flutter_local_notification package internal flow] Initializing for iOS platform');
      if (initializationSettings.iOS == null) {
        debugPrint(
            '[flutter_local_notification package internal flow] Error: iOS settings are null');
        throw ArgumentError(
            'iOS settings must be set when targeting iOS platform.');
      }

      debugPrint(
          '[flutter_local_notification package internal flow] Resolving iOS platform-specific implementation');
      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
          resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      debugPrint(
          '[flutter_local_notification package internal flow] iOS plugin resolved: ${iosPlugin != null ? 'success' : 'failed'}');

      if (iosPlugin != null) {
        debugPrint(
            '[flutter_local_notification package internal flow] Calling iOS platform initialize()');
        final bool? result = await iosPlugin.initialize(
          initializationSettings.iOS!,
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
          onDidReceiveBackgroundNotificationResponse:
              onDidReceiveBackgroundNotificationResponse,
        );
        debugPrint(
            '[flutter_local_notification package internal flow] iOS platform initialize() completed with result: $result');
        return result;
      } else {
        debugPrint(
            '[flutter_local_notification package internal flow] iOS plugin is null, returning null');
        return null;
      }
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      debugPrint(
          '[flutter_local_notification package internal flow] Initializing for macOS platform');
      if (initializationSettings.macOS == null) {
        debugPrint(
            '[flutter_local_notification package internal flow] Error: macOS settings are null');
        throw ArgumentError(
            'macOS settings must be set when targeting macOS platform.');
      }

      debugPrint(
          '[flutter_local_notification package internal flow] Resolving macOS platform-specific implementation');
      final MacOSFlutterLocalNotificationsPlugin? macosPlugin =
          resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      debugPrint(
          '[flutter_local_notification package internal flow] macOS plugin resolved: ${macosPlugin != null ? 'success' : 'failed'}');

      if (macosPlugin != null) {
        debugPrint(
            '[flutter_local_notification package internal flow] Calling macOS platform initialize()');
        final bool? result = await macosPlugin.initialize(
          initializationSettings.macOS!,
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
        );
        debugPrint(
            '[flutter_local_notification package internal flow] macOS platform initialize() completed with result: $result');
        return result;
      } else {
        debugPrint(
            '[flutter_local_notification package internal flow] macOS plugin is null, returning null');
        return null;
      }
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      debugPrint(
          '[flutter_local_notification package internal flow] Initializing for Linux platform');
      if (initializationSettings.linux == null) {
        debugPrint(
            '[flutter_local_notification package internal flow] Error: Linux settings are null');
        throw ArgumentError(
            'Linux settings must be set when targeting Linux platform.');
      }

      debugPrint(
          '[flutter_local_notification package internal flow] Resolving Linux platform-specific implementation');
      final LinuxFlutterLocalNotificationsPlugin? linuxPlugin =
          resolvePlatformSpecificImplementation<
              LinuxFlutterLocalNotificationsPlugin>();
      debugPrint(
          '[flutter_local_notification package internal flow] Linux plugin resolved: ${linuxPlugin != null ? 'success' : 'failed'}');

      if (linuxPlugin != null) {
        debugPrint(
            '[flutter_local_notification package internal flow] Calling Linux platform initialize()');
        final bool? result = await linuxPlugin.initialize(
          initializationSettings.linux!,
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
        );
        debugPrint(
            '[flutter_local_notification package internal flow] Linux platform initialize() completed with result: $result');
        return result;
      } else {
        debugPrint(
            '[flutter_local_notification package internal flow] Linux plugin is null, returning null');
        return null;
      }
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint(
          '[flutter_local_notification package internal flow] Initializing for Windows platform');
      if (initializationSettings.windows == null) {
        debugPrint(
            '[flutter_local_notification package internal flow] Error: Windows settings are null');
        throw ArgumentError(
            'Windows settings must be set when targeting Windows platform.');
      }

      debugPrint(
          '[flutter_local_notification package internal flow] Resolving Windows platform-specific implementation');
      final FlutterLocalNotificationsWindows? windowsPlugin =
          resolvePlatformSpecificImplementation<
              FlutterLocalNotificationsWindows>();
      debugPrint(
          '[flutter_local_notification package internal flow] Windows plugin resolved: ${windowsPlugin != null ? 'success' : 'failed'}');

      if (windowsPlugin != null) {
        debugPrint(
            '[flutter_local_notification package internal flow] Calling Windows platform initialize()');
        final bool result = await windowsPlugin.initialize(
          initializationSettings.windows!,
          onNotificationReceived: onDidReceiveNotificationResponse,
        );
        debugPrint(
            '[flutter_local_notification package internal flow] Windows platform initialize() completed with result: $result');
        return result;
      } else {
        debugPrint(
            '[flutter_local_notification package internal flow] Windows plugin is null, returning null');
        return null;
      }
    }
    debugPrint(
        '[flutter_local_notification package internal flow] No matching platform found, returning true');
    return true;
  }

  /// Returns info on if a notification created from this plugin had been used
  /// to launch the application.
  ///
  /// An example of how this could be used is to change the initial route of
  /// your application when it starts up. If the plugin isn't running on either
  /// Android, iOS or macOS then an instance of the
  /// `NotificationAppLaunchDetails` class is returned with
  /// `didNotificationLaunchApp` set to false.
  ///
  /// Note that this will return null for applications running on macOS
  /// versions older than 10.14. This is because there's currently no mechanism
  /// for plugins to receive information on lifecycle events.
  Future<NotificationAppLaunchDetails?>
      getNotificationAppLaunchDetails() async {
    debugPrint(
        '[flutter_local_notification package internal flow] getNotificationAppLaunchDetails() called');
    if (kIsWeb) {
      debugPrint(
          '[flutter_local_notification package internal flow] Running on web, returning null');
      return null;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint(
          '[flutter_local_notification package internal flow] Getting Android launch details');
      final NotificationAppLaunchDetails? result =
          await resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.getNotificationAppLaunchDetails();
      debugPrint(
          '[flutter_local_notification package internal flow] Android launch details result: $result');
      return result;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint(
          '[flutter_local_notification package internal flow] Getting iOS launch details');
      final NotificationAppLaunchDetails? result =
          await resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.getNotificationAppLaunchDetails();
      debugPrint(
          '[flutter_local_notification package internal flow] iOS launch details result: $result');
      return result;
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      debugPrint(
          '[flutter_local_notification package internal flow] Getting macOS launch details');
      final NotificationAppLaunchDetails? result =
          await resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin>()
              ?.getNotificationAppLaunchDetails();
      debugPrint(
          '[flutter_local_notification package internal flow] macOS launch details result: $result');
      return result;
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint(
          '[flutter_local_notification package internal flow] Getting Windows launch details');
      final NotificationAppLaunchDetails? result =
          await resolvePlatformSpecificImplementation<
                  FlutterLocalNotificationsWindows>()
              ?.getNotificationAppLaunchDetails();
      debugPrint(
          '[flutter_local_notification package internal flow] Windows launch details result: $result');
      return result;
    } else {
      debugPrint(
          '[flutter_local_notification package internal flow] Using default platform instance for launch details');
      final NotificationAppLaunchDetails result =
          await FlutterLocalNotificationsPlatform.instance
                  .getNotificationAppLaunchDetails() ??
              const NotificationAppLaunchDetails(false);
      debugPrint(
          '[flutter_local_notification package internal flow] Default launch details result: $result');
      return result;
    }
  }

  /// Show a notification with an optional payload that will be passed back to
  /// the app when a notification is tapped.
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    debugPrint(
        '[flutter_local_notification package internal flow] show() called with id: $id, title: $title, body: $body, payload: $payload');

    if (kIsWeb) {
      debugPrint(
          '[flutter_local_notification package internal flow] Running on web, skipping show()');
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint(
          '[flutter_local_notification package internal flow] Showing notification on Android platform');
      await resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.show(id, title, body,
              notificationDetails: notificationDetails?.android,
              payload: payload);
      debugPrint(
          '[flutter_local_notification package internal flow] Android notification show() completed');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint(
          '[flutter_local_notification package internal flow] Showing notification on iOS platform');
      await resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.show(id, title, body,
              notificationDetails: notificationDetails?.iOS, payload: payload);
      debugPrint(
          '[flutter_local_notification package internal flow] iOS notification show() completed');
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      debugPrint(
          '[flutter_local_notification package internal flow] Showing notification on macOS platform');
      await resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.show(id, title, body,
              notificationDetails: notificationDetails?.macOS,
              payload: payload);
      debugPrint(
          '[flutter_local_notification package internal flow] macOS notification show() completed');
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      debugPrint(
          '[flutter_local_notification package internal flow] Showing notification on Linux platform');
      await resolvePlatformSpecificImplementation<
              LinuxFlutterLocalNotificationsPlugin>()
          ?.show(id, title, body,
              notificationDetails: notificationDetails?.linux,
              payload: payload);
      debugPrint(
          '[flutter_local_notification package internal flow] Linux notification show() completed');
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint(
          '[flutter_local_notification package internal flow] Showing notification on Windows platform');
      await resolvePlatformSpecificImplementation<
              FlutterLocalNotificationsWindows>()
          ?.show(id, title, body,
              details: notificationDetails?.windows, payload: payload);
      debugPrint(
          '[flutter_local_notification package internal flow] Windows notification show() completed');
    } else {
      debugPrint(
          '[flutter_local_notification package internal flow] Using default platform instance for show()');
      await FlutterLocalNotificationsPlatform.instance.show(id, title, body);
      debugPrint(
          '[flutter_local_notification package internal flow] Default platform show() completed');
    }
  }

  /// Cancel/remove the notification with the specified id.
  ///
  /// This applies to notifications that have been scheduled and those that
  /// have already been presented.
  ///
  /// The `tag` parameter specifies the Android tag. If it is provided,
  /// then the notification that matches both the id and the tag will
  /// be canceled. `tag` has no effect on other platforms.
  Future<void> cancel(int id, {String? tag}) async {
    debugPrint(
        '[flutter_local_notification package internal flow] cancel() called with id: $id, tag: $tag');

    if (kIsWeb) {
      debugPrint(
          '[flutter_local_notification package internal flow] Running on web, skipping cancel()');
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint(
          '[flutter_local_notification package internal flow] Canceling notification on Android platform');
      await resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.cancel(id, tag: tag);
      debugPrint(
          '[flutter_local_notification package internal flow] Android notification cancel() completed');
    } else {
      debugPrint(
          '[flutter_local_notification package internal flow] Canceling notification on default platform instance');
      await FlutterLocalNotificationsPlatform.instance.cancel(id);
      debugPrint(
          '[flutter_local_notification package internal flow] Default platform cancel() completed');
    }
  }

  /// Cancels/removes all notifications.
  ///
  /// This applies to notifications that have been scheduled and those that
  /// have already been presented.
  Future<void> cancelAll() async {
    debugPrint(
        '[flutter_local_notification package internal flow] cancelAll() called');
    await FlutterLocalNotificationsPlatform.instance.cancelAll();
    debugPrint(
        '[flutter_local_notification package internal flow] cancelAll() completed');
  }

  /// Schedules a notification to be shown at the specified date and time
  /// relative to a specific time zone.
  ///
  /// Note that to get the appropriate representation of the time at the native
  /// level (i.e. Android/iOS), the plugin needs to pass the time over the
  /// platform channel in yyyy-mm-dd hh:mm:ss format. Therefore, the precision
  /// is at the best to the second.
  ///
  /// If a value for [matchDateTimeComponents] parameter is given, this tells
  /// the plugin to schedule a recurring notification that matches the
  /// specified date and time components. Specifying
  /// [DateTimeComponents.time] would result in a daily notification at the
  /// same time whilst [DateTimeComponents.dayOfWeekAndTime] would result
  /// in a weekly notification that occurs on the same day of the week and time.
  /// This is similar to how recurring notifications on iOS/macOS work using a
  /// calendar trigger. Note that when a value is given, the [scheduledDate]
  /// may not represent the first time the notification will be shown. An
  /// example would be if the date and time is currently 2020-10-19 11:00
  /// (i.e. 19th October 2020 11:00AM) and [scheduledDate] is 2020-10-21
  /// 10:00 and the value of the [matchDateTimeComponents] is
  /// [DateTimeComponents.time], then the next time a notification will
  /// appear is 2020-10-20 10:00.
  ///
  /// On Android, this will also require additional setup for the app,
  /// especially in the app's `AndroidManifest.xml` file. Please see check the
  /// readme for further details.
  ///
  /// On Windows, this will only set a notification on the [scheduledDate], and
  /// not repeat, regardless of the value for [matchDateTimeComponents].
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    debugPrint(
        '[flutter_local_notification package internal flow] zonedSchedule() called with id: $id, title: $title, scheduledDate: $scheduledDate, androidScheduleMode: $androidScheduleMode');

    if (kIsWeb) {
      debugPrint(
          '[flutter_local_notification package internal flow] Running on web, skipping zonedSchedule()');
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint(
          '[flutter_local_notification package internal flow] Scheduling notification on Android platform');
      await resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!
          .zonedSchedule(
              id, title, body, scheduledDate, notificationDetails.android,
              payload: payload,
              scheduleMode: androidScheduleMode,
              matchDateTimeComponents: matchDateTimeComponents);
      debugPrint(
          '[flutter_local_notification package internal flow] Android notification zonedSchedule() completed');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint(
          '[flutter_local_notification package internal flow] Scheduling notification on iOS platform');
      await resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.zonedSchedule(
              id, title, body, scheduledDate, notificationDetails.iOS,
              payload: payload,
              matchDateTimeComponents: matchDateTimeComponents);
      debugPrint(
          '[flutter_local_notification package internal flow] iOS notification zonedSchedule() completed');
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      debugPrint(
          '[flutter_local_notification package internal flow] Scheduling notification on macOS platform');
      await resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.zonedSchedule(
              id, title, body, scheduledDate, notificationDetails.macOS,
              payload: payload,
              matchDateTimeComponents: matchDateTimeComponents);
      debugPrint(
          '[flutter_local_notification package internal flow] macOS notification zonedSchedule() completed');
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint(
          '[flutter_local_notification package internal flow] Scheduling notification on Windows platform');
      await resolvePlatformSpecificImplementation<
              FlutterLocalNotificationsWindows>()
          ?.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails.windows,
        payload: payload,
      );
      debugPrint(
          '[flutter_local_notification package internal flow] Windows notification zonedSchedule() completed');
    } else {
      debugPrint(
          '[flutter_local_notification package internal flow] zonedSchedule() not implemented for current platform');
      throw UnimplementedError('zonedSchedule() has not been implemented');
    }
  }

  /// Periodically show a notification using the specified interval.
  ///
  /// For example, specifying a hourly interval means the first time the
  /// notification will be an hour after the method has been called and
  /// then every hour after that.
  ///
  /// On Android, this will also require additional setup for the app,
  /// especially in the app's `AndroidManifest.xml` file. Please see check the
  /// readme for further details.
  Future<void> periodicallyShow(
    int id,
    String? title,
    String? body,
    RepeatInterval repeatInterval,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
  }) async {
    debugPrint(
        '[flutter_local_notification package internal flow] periodicallyShow() called with id: $id, title: $title, repeatInterval: $repeatInterval');

    if (kIsWeb) {
      debugPrint(
          '[flutter_local_notification package internal flow] Running on web, skipping periodicallyShow()');
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint(
          '[flutter_local_notification package internal flow] Setting up periodic notification on Android platform');
      await resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.periodicallyShow(id, title, body, repeatInterval,
              notificationDetails: notificationDetails.android,
              payload: payload,
              scheduleMode: androidScheduleMode);
      debugPrint(
          '[flutter_local_notification package internal flow] Android periodic notification setup completed');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint(
          '[flutter_local_notification package internal flow] Setting up periodic notification on iOS platform');
      await resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.periodicallyShow(id, title, body, repeatInterval,
              notificationDetails: notificationDetails.iOS, payload: payload);
      debugPrint(
          '[flutter_local_notification package internal flow] iOS periodic notification setup completed');
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      debugPrint(
          '[flutter_local_notification package internal flow] Setting up periodic notification on macOS platform');
      await resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.periodicallyShow(id, title, body, repeatInterval,
              notificationDetails: notificationDetails.macOS, payload: payload);
      debugPrint(
          '[flutter_local_notification package internal flow] macOS periodic notification setup completed');
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint(
          '[flutter_local_notification package internal flow] Windows does not support periodic notifications');
      throw UnsupportedError('Notifications do not repeat on Windows');
    } else {
      debugPrint(
          '[flutter_local_notification package internal flow] Using default platform instance for periodic notification');
      await FlutterLocalNotificationsPlatform.instance
          .periodicallyShow(id, title, body, repeatInterval);
      debugPrint(
          '[flutter_local_notification package internal flow] Default platform periodic notification setup completed');
    }
  }

  /// Periodically show a notification using the specified custom duration
  /// interval.
  ///
  /// For example, specifying a 5 minutes repeat duration interval means
  /// the first time the notification will be an 5 minutes after the method
  /// has been called and then every 5 minutes after that.
  ///
  /// On Android, this will also require additional setup for the app,
  /// especially in the app's `AndroidManifest.xml` file. Please see check the
  /// readme for further details.
  Future<void> periodicallyShowWithDuration(
    int id,
    String? title,
    String? body,
    Duration repeatDurationInterval,
    NotificationDetails notificationDetails, {
    AndroidScheduleMode androidScheduleMode = AndroidScheduleMode.exact,
    String? payload,
  }) async {
    debugPrint(
        '[flutter_local_notification package internal flow] periodicallyShowWithDuration() called with id: $id, title: $title, duration: $repeatDurationInterval');

    if (kIsWeb) {
      debugPrint(
          '[flutter_local_notification package internal flow] Running on web, skipping periodicallyShowWithDuration()');
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint(
          '[flutter_local_notification package internal flow] Setting up duration-based periodic notification on Android platform');
      await resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.periodicallyShowWithDuration(
              id, title, body, repeatDurationInterval,
              notificationDetails: notificationDetails.android,
              payload: payload,
              scheduleMode: androidScheduleMode);
      debugPrint(
          '[flutter_local_notification package internal flow] Android duration-based periodic notification setup completed');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint(
          '[flutter_local_notification package internal flow] Setting up duration-based periodic notification on iOS platform');
      await resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.periodicallyShowWithDuration(
              id, title, body, repeatDurationInterval,
              notificationDetails: notificationDetails.iOS, payload: payload);
      debugPrint(
          '[flutter_local_notification package internal flow] iOS duration-based periodic notification setup completed');
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      debugPrint(
          '[flutter_local_notification package internal flow] Setting up duration-based periodic notification on macOS platform');
      await resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.periodicallyShowWithDuration(
              id, title, body, repeatDurationInterval,
              notificationDetails: notificationDetails.macOS, payload: payload);
      debugPrint(
          '[flutter_local_notification package internal flow] macOS duration-based periodic notification setup completed');
    } else {
      debugPrint(
          '[flutter_local_notification package internal flow] Using default platform instance for duration-based periodic notification');
      await FlutterLocalNotificationsPlatform.instance
          .periodicallyShowWithDuration(
              id, title, body, repeatDurationInterval);
      debugPrint(
          '[flutter_local_notification package internal flow] Default platform duration-based periodic notification setup completed');
    }
  }

  /// Returns a list of notifications pending to be delivered/shown.
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() {
    debugPrint(
        '[flutter_local_notification package internal flow] pendingNotificationRequests() called');
    return FlutterLocalNotificationsPlatform.instance
        .pendingNotificationRequests();
  }

  /// Returns the list of active notifications shown by the application that
  /// haven't been dismissed/removed.
  ///
  /// The supported OS versions are
  /// - Android: Android 6.0 or newer
  /// - iOS: iOS 10.0 or newer
  /// - macOS: macOS 10.14 or newer
  ///
  /// On Linux it will throw an [UnimplementedError].
  ///
  /// On Windows, your application must be packaged as an MSIX to be able
  /// to use this API. If not, this function will return an empty list.
  /// For more details, see: https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/modernize-wpf-tutorial-5
  Future<List<ActiveNotification>> getActiveNotifications() {
    debugPrint(
        '[flutter_local_notification package internal flow] getActiveNotifications() called');
    return FlutterLocalNotificationsPlatform.instance.getActiveNotifications();
  }
}
