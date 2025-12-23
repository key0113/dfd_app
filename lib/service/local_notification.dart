import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:newdfd/service/deeplink_service.dart';
import 'package:newdfd/utils/app_logger.dart';
import 'package:path_provider/path_provider.dart';

class LocalNotificationService {
  static final LocalNotificationService shared =
      LocalNotificationService._privateConstructor();
  LocalNotificationService._privateConstructor();

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late AndroidNotificationChannel channel;

  DidReceiveLocalNotificationCallback onDidReceiveLocalNotification =
      (id, title, body, payload) {
    AppLogger.pushMessage(
        "onDidReceiveLocalNotification : $id, title - $title, body - $body, payload - $payload");
  };

  //! 로컬 노티피케이션 터치 시 호출
  DidReceiveNotificationResponseCallback onDidReceiveNotificationResponse =
      (details) {
    final payload = details.payload;
    final id = details.id;
    AppLogger.pushMessage(
        "onDidReceiveNotificationResponse : $id, payload - $payload");
    if (payload != null && payload.isNotEmpty) {
      DeepLinkService.shared.setDeeplinkValueByInitialLink(payload);
    }
  };

  setting() async {
    channel = const AndroidNotificationChannel(
      'dfd_notification_channel',
      'dfd Notification',
      importance: Importance.max,
      playSound: true,
      enableLights: true,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  sendLocalNotification(RemoteMessage event) async {
    final notification = event.notification;
    final hashCode = notification.hashCode;
    final title = notification?.title;
    final body = notification?.body;
    final link = event.data['link'];
    // final imageUrl = event.data['image_url'];

    flutterLocalNotificationsPlugin.show(
        hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            icon: 'ic_launcher',
            // styleInformation: bigPictureStyle,
          ),
        ),
        payload: link);
  }
}
