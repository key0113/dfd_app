import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:newdfd/service/app_env.dart';
import 'package:newdfd/service/app_storage.dart';
import 'package:newdfd/service/deeplink_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:newdfd/service/token_notifier.dart';
import 'package:newdfd/service/topic_manage.dart';
import 'package:newdfd/utils/app_logger.dart';
import 'package:newdfd/widgets/app_webview.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Future<bool>? loadingFuture;
  bool isWebLoadFinished = false;
  InAppWebViewController? _webViewController;
  late VoidCallback deeplinkListener;
  late VoidCallback tokenListener;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    loadingFuture = startLoading();
    deeplinkListener = () {
      checkDeepLink();
    };
    tokenListener = () {
      setCookies();
    };
    DeepLinkService.shared.addListener(deeplinkListener);
    TokenNotifier.shared.addListener(tokenListener);
  }

  @override
  void dispose() {
    DeepLinkService.shared.removeListener(deeplinkListener);
    TokenNotifier.shared.removeListener(tokenListener);
    super.dispose();
  }

  Future<bool> startLoading() async {
    await setCookies();
    return true;
  }

  checkIsFirstLoad() {
    if (ServiceManager.shared.isFirstLanch) {
      logSuccess("is First Load");
      ServiceManager.shared.setNotFirstLanch();
      _webViewController?.evaluateJavascript(
          source: "modal.open('access_authority_info');");
    } else {
      logSuccess("is NOT! First Load");
    }
  }

  checkAppAuto() {
    _webViewController?.evaluateJavascript(
        source: "if (typeof appAuto != 'undefined') {appAuto();}");

    _sendTokenToServer();
  }

  Future<void> _sendTokenToServer() async {
    final token = AppStorage.shared.pushToken;
    final uuid = await ServiceManager.shared.getUUID();

    if (token != null && _webViewController != null) {
      final jsCode = """
      \$.ajax({
        type: 'post',
        url: '/app/token_insert',
        data: {'token': '$token', 'uniqueId': '$uuid'},
        data: {'token': '$token', 'uniqueId': '$uuid'},
      });
    """;

      await _webViewController?.evaluateJavascript(source: jsCode);
    }
  }


  Future checkDeepLink() async {
    print("checkDeepLink");
    final deeplink = DeepLinkService.shared.getDeepLinkValue();
    if (deeplink != null) {
      print("checkDeepLink - $deeplink");
      _handleDeepLink(deeplink);
    }
  }

  _handleDeepLink(String deeplink) async {
    if (isWebLoadFinished) {
      AppLogger.deepLink("_handleDeepLink - $deeplink");
      //! 기타 딥링크
      if (_webViewController != null) {
        print("_handleDeepLink loadUrl - $deeplink");
        _webViewController!
            .loadUrl(urlRequest: URLRequest(url: Uri.parse(deeplink)));
        DeepLinkService.shared.deleteDeepLinkValue();
      } else {
        print("_handleDeepLink _webViewController NULL");
      }
    } else {
      print("_handleDeepLink isWebLoadFinished NOT");
    }
  }

  Uri get getHomeUrl {
    return Uri.parse(AppEnv.webAppUrl);
  }

  Future<bool> setCookies() async {
    final expireDate =
        DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;

    final url = getHomeUrl;
    final pushToken = AppStorage.shared.pushToken;
    if (pushToken != null) {
      await CookieManager.instance().setCookie(
        url: url,
        name: 'fcmtoken',
        value: pushToken,
        domain: AppEnv.cookieDomain,
        expiresDate: expireDate,
      );
    }

    final uuid = await ServiceManager.shared.getUUID();
    await CookieManager.instance().setCookie(
      url: url,
      name: 'uniqueId',
      value: uuid,
      domain: AppEnv.cookieDomain,
      expiresDate: expireDate,
    );

    return true;
  }

  DateTime? currentBackPressTime;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_webViewController != null) {
          if (await _webViewController!.canGoBack()) {
            _webViewController!.goBack();
          } else {
            if (currentBackPressTime != null) {
              // if (DateTime.now().difference(currentBackPressTime!) <
              //     const Duration(seconds: 2)) {
              //   return true;
              // }
              final diff =
                  DateTime.now().difference(currentBackPressTime!).inSeconds;
              logSuccess("$diff");
              if (diff < 3) {
                currentBackPressTime = null;
                return true;
              }
            }
            currentBackPressTime = DateTime.now();
            const snackBar = SnackBar(
              duration: Duration(seconds: 2),
              content: Text('한번 더 누르면 종료됩니다.'),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
        return false;
      },
      child: FutureBuilder(
          future: loadingFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Scaffold(
                // floatingActionButton: FloatingActionButton(onPressed: () async {
                //   final initalMessage =
                //       await FirebaseMessaging.instance.getInitialMessage();
                //   logSuccess("$initalMessage");
                //   print(initalMessage);
                //   checkDeepLink();
                // // }),

                // 알림함
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    _webViewController?.loadUrl(
                        urlRequest: URLRequest(
                            url: Uri.parse('${AppEnv.webAppUrl}/app/push')
                        )
                    );
                  },
                  child: Icon(Icons.notifications),
                ),
                body: SafeArea(
                  child: AppWebView(
                    urlStr: AppEnv.webAppUrl,
                    didSetController: (controller) {
                      _webViewController = controller;

                      controller.addJavaScriptHandler(
                          handlerName: 'updateBadge',
                          callback: (args) {
                            final count = args[0] as int;
                            print('배지 업데이트: $count');

                            // 앱 배지 설정
                            FlutterAppBadger.updateBadgeCount(count);

                            return count;
                          }
                      );
                    },
                    onLoadStop: (url) {
                      if (!isWebLoadFinished) {
                        isWebLoadFinished = true;
                        checkIsFirstLoad();
                        checkDeepLink();
                      }
                      checkAppAuto();
                    },
                  ),
                ),
              );
            } else {
              return Container();
            }
          }),
    );
  }
}
