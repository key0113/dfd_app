import 'dart:io';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:newdfd/service/token_notifier.dart';
import 'package:newdfd/utils/app_logger.dart';
import 'package:newdfd/service/app_storage.dart';
import 'package:newdfd/service/deeplink_service.dart';
import 'package:newdfd/service/local_notification.dart';
import 'package:newdfd/main_app.dart';
import 'package:newdfd/controller/shared_controller.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:newdfd/utils/app_plugins.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:http/http.dart' as http;
import 'package:newdfd/service/app_env.dart';
import 'package:newdfd/service/topic_manage.dart';  // 🟢 추가

checkDeeplink() async {
  // ! 다이나믹 링크
  final PendingDynamicLinkData? fbinitialLink =
  await FirebaseDynamicLinks.instance.getInitialLink();
  if (fbinitialLink != null) {
    AppLogger.deepLink("FirebaseDynamicLinks.getInitialLink $fbinitialLink",
        isSystemLog: true);
    log("${fbinitialLink.link}", name: "deeplink initial link");
    DeepLinkService.shared.setDeepLinkValue(fbinitialLink.link.path);
  }

  //! 앱이 꺼져 있을 때, 푸시 메세지를 터치 해서 앱 실행될 때 호출
  final initalMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initalMessage != null) {
    final data = initalMessage.data;
    final title = initalMessage.notification?.title;
    final body = initalMessage.notification?.body;
    final logMessage =
        "getInitialMessage : title - $title, body - $body, data - $data";

    AppPlugin.shared.systemLog(logMessage);
    print("getInitialMessage : title - $title, body - $body, data - $data");
    DeepLinkService.shared.setDeeplinkValueByRemoteMessage(initalMessage);
  }
}

//251211 추가
Future<void> _registerTokenToServer(String fcmToken) async {
  try {
    final uuid = await ServiceManager.shared.getUUID();
    final deviceType = Platform.isIOS ? 'iOS' : 'Android';
    final version = await ServiceManager.shared.getVersion();
    
    final response = await http.post(
      Uri.parse('${AppEnv.webAppUrl}app/token_insert'),
      body: {
        'token': fcmToken,
        'uniqueId': uuid,
        'deviceType': deviceType,
        'appVersion': version,
        // userId는 로그인 후 따로 업데이트
      },
    );
    
    print('🟢 토큰 서버 등록 완료: ${response.body}');
  } catch (e) {
    print('🔴 토큰 서버 등록 실패: $e');
  }
}
//여기까지


void main() async {
  HttpOverrides.global = _HttpOverrides();

  //! https://inappwebview.dev/docs/5.x.x/intro
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  KakaoSdk.init(
    nativeAppKey: '91c634c2201ae4899f63df65c7c1c0ba',
  );

  await AppStorage.shared.init();

  Get.put(SharedController());

  final app = await Firebase.initializeApp();

  FlutterAppBadger.removeBadge();

  try {
    // If the system can show an authorization request dialog
    final trakingStatus =
    await AppTrackingTransparency.trackingAuthorizationStatus;
    if (trakingStatus == TrackingStatus.authorized) {
    } else if (trakingStatus == TrackingStatus.notDetermined) {
      // Wait for dialog popping animation
      await Future.delayed(const Duration(milliseconds: 2000));
      // Request system's tracking authorization dialog
      final trakingStatus =
      await AppTrackingTransparency.requestTrackingAuthorization();
      if (trakingStatus == TrackingStatus.authorized) {}
    }
  } on PlatformException {
    AppLogger.pushMessage('AppTrackingTransparency : PlatformException');
  }
  await LocalNotificationService.shared.setting();

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, // Required to display a heads up notification
    badge: true,
    sound: true,
  );
  // 20251211 기존 
  // FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
  //   AppLogger.pushMessage('onTokenRefresh : $fcmToken');
  //   // AppStorage.shared.pushToken = fcmToken;
  //   TokenNotifier.shared.setFemToken(fcmToken);
  //   logSuccess("onTokenRefresh - $fcmToken", name: "FCM_TOKEN");
  // });
  // 수정후
  FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
  AppLogger.pushMessage('onTokenRefresh : $fcmToken');
  TokenNotifier.shared.setFemToken(fcmToken);
  logSuccess("onTokenRefresh - $fcmToken", name: "FCM_TOKEN");
  
  // 🟢 서버에 토큰 등록
  _registerTokenToServer(fcmToken);
});

// 20251211
// 기존

  // FirebaseMessaging.instance.getToken().then((fcmToken) {
  //   AppLogger.pushMessage("getToken() : $fcmToken", isSystemLog: false);
  //   // AppStorage.shared.pushToken = fcmToken;
  //   if (fcmToken != null) {
  //     TokenNotifier.shared.setFemToken(fcmToken);
  //     FirebaseMessaging.instance.subscribeToTopic("AA");
  //   }
  //   logSuccess("getToken - $fcmToken", name: "FCM_TOKEN");
  // });
  // 수정 후
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    AppLogger.pushMessage("getToken() : $fcmToken", isSystemLog: false);
    if (fcmToken != null) {
      TokenNotifier.shared.setFemToken(fcmToken);
      FirebaseMessaging.instance.subscribeToTopic("AA");
      logSuccess("getToken - $fcmToken", name: "FCM_TOKEN");
      
      // 🟢 서버에 토큰 등록
      await _registerTokenToServer(fcmToken);
    } else {
      print("FCM 토큰이 null (iOS 첫 실행 시 정상)");
    }
  } catch (e) {
    print("FCM 토큰 가져오기 실패: $e");
  }

  // 기존
  // FirebaseMessaging.instance.getAPNSToken().then((apnsToken) {
  //   AppLogger.pushMessage("apnsToken : $apnsToken");
  //   AppStorage.shared.apnsToken = apnsToken;
  // });

  // 수정 후
  try {
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    AppLogger.pushMessage("apnsToken : $apnsToken");
    AppStorage.shared.apnsToken = apnsToken;
  } catch (e) {
    print("APNS 토큰 가져오기 실패 (첫 실행 시 정상): $e");
}

  FirebaseMessaging.onMessageOpenedApp.listen((event) {
    final data = event.data;
    final title = event.notification?.title;
    final body = event.notification?.body;

    final logMessage =
        "onMessageOpenedApp : title - $title, body - $body, data - $data";
    AppLogger.pushMessage(logMessage);
    DeepLinkService.shared.setDeeplinkValueByRemoteMessage(event);
  });

  FirebaseMessaging.onMessage.listen((event) {
    final data = event.data;
    final title = event.notification?.title;
    final body = event.notification?.body;
    final logMessage = "onMessage : title - $title, body - $body, data - $data";
    AppLogger.pushMessage(logMessage);
    LocalNotificationService.shared.sendLocalNotification(event);
  });

  // //! 다이나믹 링크
  final authDomain = app.options.authDomain;
  final deepLinkURLScheme = app.options.deepLinkURLScheme;
  AppLogger.deepLink(
      "authDomain : $authDomain, deepLinkURLScheme : $deepLinkURLScheme");
  
  FirebaseDynamicLinks.instanceFor(app: app).onLink.listen((event) {
    AppLogger.deepLink("FirebaseDynamicLinks onLink.listen : $event");
    DeepLinkService.shared.setDeepLinkValue(event.link.path);
  }).onError((error) {
    AppLogger.deepLink("onLink.listen : $error");
  });

  await checkDeeplink();
  // IOS 빌드시 흰 화면 오류로 임시 주석
  // String? token = await FirebaseMessaging.instance.getToken();
  // print("FCM 토큰: $token");
  String fcmToken = TokenNotifier.shared.getFcmToken() ?? "";
    print('🟦 FCM 토큰: $fcmToken');
      runApp(const MainApp());
    }

class _HttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}
