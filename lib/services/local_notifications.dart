import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'local_time_zone.dart';


class NettoNotification {
  late final int id = 0;
  late final String title = 'New Netto Coupons!';
  late final String body = "Time to download next week's coupons.";
}


Future<void> resetNotifications(flutterLocalNotificationsPlugin) async {
  await flutterLocalNotificationsPlugin.cancelAll();  // cancel all previous notifications
  await scheduleNextNettoNotification(flutterLocalNotificationsPlugin);  // schedule next notification
}

Future<void> scheduleNextNettoNotification(flutterLocalNotificationsPlugin) async {
  NettoNotification notification = NettoNotification();
  // final scheduledDate = inSeconds(5);  // only for debugging
  final scheduledDate = nextInstanceOfSunday8AM();
  print('Next notification scheduled for $scheduledDate');

  await scheduleNextNotification(flutterLocalNotificationsPlugin, notification, scheduledDate);
}

Future<void> scheduleNextNotification(flutterLocalNotificationsPlugin, notification, scheduledDate) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    notification.id,
    notification.title,
    notification.body,
    scheduledDate,
    loadPlatformChannelSpecifics(),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    payload: '',
  );
}

NotificationDetails loadPlatformChannelSpecifics() {
  AndroidNotificationDetails androidPlatformChannelSpecifics =
  const AndroidNotificationDetails(
    '0',  // channel id
    'Notifications',  // channel name
    channelDescription: 'Notifications',  // channel description
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    ongoing: true,
    autoCancel: false,
    styleInformation: BigTextStyleInformation(''),
  );

  NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  return platformChannelSpecifics;
}


class NotificationService {
  GlobalKey<NavigatorState> navigatorKey;
  NotificationService( {required this.navigatorKey} );

  FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    // Request permission for notifications
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation = notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    // Schedule weekly notification
    await resetNotifications(notificationsPlugin);

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');

    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await notificationsPlugin.initialize(
      initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          await resetNotifications(notificationsPlugin);

          switch (notificationResponse.notificationResponseType) {
            case NotificationResponseType.selectedNotification:
              break;
            case NotificationResponseType.selectedNotificationAction:
              break;
          }

          // App is open
          NavigatorState? key = navigatorKey.currentState;
          if (key != null) {
            key.pushReplacementNamed('/');
          }
        }
    );

    // App is closed
    final NotificationAppLaunchDetails? notificationAppLaunchDetails = await notificationsPlugin.getNotificationAppLaunchDetails();
    bool didNotificationLaunchApp = notificationAppLaunchDetails ?.didNotificationLaunchApp ?? false;
    if (didNotificationLaunchApp) {
      print('Notification launched app');
    }
  }
}
