import 'dart:io';
import 'package:http/http.dart' as http;
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
      'high_importance_channel',
      'High Importance Notifications',
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
    final link = event.data['link_url'];

    final imageUrl = event.data['image_url'];
    AppLogger.pushMessage("===== 푸시 데이터 확인 =====");
    AppLogger.pushMessage("title: $title");
    AppLogger.pushMessage("body: $body");
    AppLogger.pushMessage("link_url: $link");
    AppLogger.pushMessage("image_url: $imageUrl");
    AppLogger.pushMessage("event.data 전체: ${event.data}");

    BigPictureStyleInformation? bigPictureStyle;
    String? imagePath;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        AppLogger.pushMessage("이미지 다운로드 시작: $imageUrl");

        final response = await http.get(Uri.parse(imageUrl));
        AppLogger.pushMessage("이미지 다운로드 완료: ${response.statusCode}");

        final Directory tempDir = await getTemporaryDirectory();
        final String filePath = '${tempDir.path}/notification_image_$hashCode.jpg';
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        imagePath = filePath;

        AppLogger.pushMessage("이미지 저장 완료: $filePath");
        AppLogger.pushMessage("파일 크기: ${file.lengthSync()} bytes");

        bigPictureStyle = BigPictureStyleInformation(
          FilePathAndroidBitmap(filePath),
          largeIcon: FilePathAndroidBitmap(filePath),
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: false,
        );

        AppLogger.pushMessage("BigPictureStyle 생성 완료");
      } catch (e) {
        AppLogger.pushMessage("이미지 처리 실패: $e");
      }
    } else {
      AppLogger.pushMessage("이미지 URL 없음");
    }

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_launcher',
      styleInformation: bigPictureStyle,
      largeIcon: imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
      showWhen: true,
    );

    flutterLocalNotificationsPlugin.show(
        hashCode,
        title,
        body,
        NotificationDetails(android: androidDetails),
        payload: link);

    AppLogger.pushMessage("알림 표시 완료");
  }
}
