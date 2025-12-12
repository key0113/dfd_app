// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:newdfd/pages/modal_page.dart';
import 'package:newdfd/pages/window_page.dart';
import 'package:newdfd/service/topic_manage.dart';
import 'package:newdfd/utils/app_logger.dart';
import 'package:newdfd/utils/app_plugins.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:newdfd/service/app_env.dart';
import 'package:http/http.dart' as http;
import 'package:newdfd/service/kakao_auth_service.dart';
import 'package:newdfd/service/naver_auth_service.dart';
import 'package:newdfd/service/token_notifier.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AppWebView extends StatefulWidget {
  final String? urlStr;
  final int? windowId;
  final Function(InAppWebViewController) didSetController;
  final Function(Uri?)? onLoadStop;
  const AppWebView({
    Key? key,
    this.urlStr,
    this.windowId,
    required this.didSetController,
    this.onLoadStop,
  }) : super(key: key);

  @override
  State<AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends State<AppWebView> {
  late InAppWebView _webView;

  @override
  void initState() {
    super.initState();
    _webView = _getWidget();
  }

  // Intent 스킴 URL을 안드로이드 웹뷰에서 접근 가능하도록 변환
  Future<String> _convertIntentToAppUrl(String text) async {
    return await appChannel
        .invokeMethod('getAppUrl', <String, Object>{'url': text});
  }

// Intent 스킴 URL을 Market URL로 변환
  Future<String> _convertIntentToMarketUrl(String text) async {
    return await appChannel
        .invokeMethod('getMarketUrl', <String, Object>{'url': text});
  }

  Future<Map<String, dynamic>> _checkSnsAccount(Map<String, dynamic> snsData) async {
    final url = '${AppEnv.webAppUrl}sns/check_account';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'provider': snsData['provider'],
          'provider_user_id': snsData['kakao_user_id'],
          'email': snsData['email'],
          'nickname': snsData['nickname'],
          'fcm_token': await ServiceManager.shared.getPushToken(),
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      logError('SNS 계정 확인 실패: $e', name: "WEBVIEW");
      return {'Stat': false, 'Msg': '서버 연결에 실패했습니다.'};
    }
  }

  _handleCustomScheme(Uri url) async {
    if (Platform.isAndroid) {
      var finalUrl = url.toString();
      await _convertIntentToAppUrl(url.toString()).then((value) async {
        finalUrl = value; // 앱이 설치되었을 경우
      });

      try {
        await launchUrl(Uri.parse(finalUrl),
            mode: LaunchMode.externalApplication);
        logSuccess("payUrl - $finalUrl", name: "Payment");
      } catch (e) {
        final marketUrl = await _convertIntentToMarketUrl(url.toString());
        await launchUrl(Uri.parse(marketUrl),
            mode: LaunchMode.externalApplication);
      }
    } else {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  _getWidget() {
    final urlStr = widget.urlStr;
    final urlRequest =
        (urlStr != null) ? URLRequest(url: Uri.parse(urlStr)) : null;
    final windowId = widget.windowId;

    return InAppWebView(
      initialUrlRequest: urlRequest,
      windowId: windowId,
      initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            applicationNameForUserAgent: 'showgleApp',
            transparentBackground: true, //! true - black, false - white
            useShouldOverrideUrlLoading: true,
            verticalScrollBarEnabled: false,
            horizontalScrollBarEnabled: false,
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
          ),
          android: AndroidInAppWebViewOptions(
              useHybridComposition: true,
              thirdPartyCookiesEnabled: true,
              supportMultipleWindows: true,
              safeBrowsingEnabled: false),
          ios: IOSInAppWebViewOptions(
              alwaysBounceHorizontal: false,
              alwaysBounceVertical: false,
              allowsLinkPreview: false,
              allowsPictureInPictureMediaPlayback: false,
              sharedCookiesEnabled: true,
              allowsInlineMediaPlayback: true)),
      androidOnPermissionRequest: (controller, origin, resources) async {
        return PermissionRequestResponse(
            resources: resources,
            action: PermissionRequestResponseAction.GRANT);
      },
      onCreateWindow: (InAppWebViewController controller,
          CreateWindowAction createWindowAction) async {
        log('onCreateWindow controller - $controller',
            name: 'BigcWebAppWidget');
        log('onCreateWindow createWindowAction - $createWindowAction',
            name: 'BigcWebAppWidget');
        final result = await WindowPage.showWeb(context, createWindowAction);
        log('onCreateWindow result - $result', name: 'BigcWebAppWidget');
        return true;
      },
      onLoadError: (controller, url, code, message) {
        log('onLoadError - $url, code - $code, message - $message',
            name: 'BigcWebAppWidget');
      },
      onCloseWindow: (controller) {
        if (Navigator.canPop(context)) {
          log('onCloseWindow canPop TRUE', name: 'BigcWebAppWidget');
          Navigator.pop(context);
        } else {
          log('onCloseWindow canPop FALSE', name: 'BigcWebAppWidget');
        }
      },
      onWebViewCreated: (webController) {
        widget.didSetController(webController);
        _onWebViewCreated(webController, context);
      },
      onLoadStart: (InAppWebViewController controller, Uri? url) {
        log('onLoadStart - $url', name: 'BigcWebAppWidget loading setCookie');
      },
      onLoadStop: (controller, url) {
        log('onLoadStop - $url', name: 'NavigationActionPolicy.ALLOW');
        if (widget.onLoadStop != null) {
          widget.onLoadStop!(url);
        }
      },
      shouldOverrideUrlLoading: (controller, action) async {
        final url = action.request.url;
        if (url != null) {
          final scheme = url.scheme;
          final path = url.path;
          final host = url.host;
          if (scheme == 'about') {
            log('scheme - $scheme', name: 'NavigationActionPolicy.ALLOW');
            return NavigationActionPolicy.CANCEL;
          }

          if (path == 'blank') {
            return NavigationActionPolicy.CANCEL;
          }

          if (scheme == 'http' || scheme == 'https') {
            log('scheme - $scheme', name: 'NavigationActionPolicy.ALLOW');
            return NavigationActionPolicy.ALLOW;
          }

          _handleCustomScheme(url);
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.CANCEL;
      },
    );
  }

  _onWebViewCreated(
      InAppWebViewController webController, BuildContext context) {
    //! WEB 모달 - 우리 서비스 아님
    webController.addJavaScriptHandler(
        handlerName: 'openUrl',
        callback: (args) {
          logSuccess('openUrl args - $args', name: "WEBVIEW");
          final jsonString = args[0] as String?;
          if (jsonString != null) {
            final map = jsonDecode(jsonString);
            final url = map["url"] as String?;
            if (url != null) {
              // launchUrlString(url, mode: LaunchMode.inAppWebView);
              ModalPage.showWeb(context, url);
            }
          }
        });
    webController.addJavaScriptHandler(
        handlerName: 'fileDownload',
        callback: (args) async {
          logSuccess('fileDownload args - $args', name: "WEBVIEW");
          final jsonString = args[0] as String?;
          if (jsonString != null) {
            final map = jsonDecode(jsonString);
            final url = map["url"] as String?;
            final fileName = map["fileName"] as String?;
            if (url != null) {
              return await ServiceManager.shared
                  .downloadFile(url, fileName: fileName);
            }
          }
          return false;
        });
    webController.addJavaScriptHandler(
        handlerName: 'shareUrl',
        callback: (args) {
          logSuccess('shareUrl args - $args', name: "WEBVIEW");
          final jsonString = args[0] as String?;
          if (jsonString != null) {
            final map = jsonDecode(jsonString);
            final url = map["url"] as String?;
            if (url != null) {
              ServiceManager.shared.shareUrl(url);
            }
          }
        });

    webController.addJavaScriptHandler(
        handlerName: 'setUserLevels',
        callback: (args) async {
          logSuccess('setUserLevel - $args', name: "WEBVIEW");
          final jsonString = args[0] as String?;
          if (jsonString != null) {
            final userLevels = jsonDecode(jsonString);
            ServiceManager.shared.setUserLevesl(userLevels);
            return {
              "bridgeName": "setUserLevels",
              "callback": userLevels,
            };
          }
        });
    webController.addJavaScriptHandler(
        handlerName: 'setPushOnOff',
        callback: (args) async {
          logSuccess('setPushOnOff - $args', name: "WEBVIEW");
          final jsonString = args[0] as String?;
          if (jsonString != null) {
            final map = jsonDecode(jsonString);
            final onOff = map["onOff"] as String?;
            if (onOff != null) {
              ServiceManager.shared.setPushOnOff(onOff);
              return {
                "bridgeName": "setUserLevels",
                "callback": "success",
              };
            }
          }
        });
    webController.addJavaScriptHandler(
        handlerName: 'getPushOnOff',
        callback: (args) async {
          logSuccess('getPushOnOff - $args', name: "WEBVIEW");
          final pushOnOff = ServiceManager.shared.getPushOnOff();
          return {
            "bridgeName": "getPushOnOff",
            "callback": pushOnOff,
          };
        });
    webController.addJavaScriptHandler(
        handlerName: 'getUserLevels',
        callback: (args) {
          logSuccess('getUserLevels - $args', name: "WEBVIEW");
          final userLevels = ServiceManager.shared.getUserLevels();
          return {
            "bridgeName": "getUserLevels",
            "callback": userLevels,
          };
        });
    webController.addJavaScriptHandler(
        handlerName: 'getUUID',
        callback: (args) async {
          logSuccess('getUUID - $args', name: "WEBVIEW");
          final uuid = await ServiceManager.shared.getUUID();
          return {
            "bridgeName": "getUUID",
            "callback": uuid,
          };
        });
    webController.addJavaScriptHandler(
        handlerName: 'getPushToken',
        callback: (args) async {
          logSuccess('getPushToken - $args', name: "WEBVIEW");
          final pushToken = await ServiceManager.shared.getPushToken();
          return {
            "bridgeName": "getPushToken",
            "callback": pushToken,
          };
        });
    webController.addJavaScriptHandler(
        handlerName: 'getVersion',
        callback: (args) async {
          logSuccess('getVersion - $args', name: "WEBVIEW");
          final version = await ServiceManager.shared.getVersion();
          return {
            "bridgeName": "getVersion",
            "callback": version,
          };
        });

    webController.addJavaScriptHandler(
        handlerName: 'closeModal',
        callback: (args) {
          //![OhWebView] addJavaScriptHandler closeModal args - [{isSuccess: false, message: 사용자가 결제를 취소하였습니다}]
          logSuccess('addJavaScriptHandler closeModal args - $args',
              name: "WEBVIEW");
          Navigator.of(context).pop(args[0]);
        });
    webController.addJavaScriptHandler(
        handlerName: 'closeWindow',
        callback: (args) {
          //![OhWebView] addJavaScriptHandler closeModal args - [{isSuccess: false, message: 사용자가 결제를 취소하였습니다}]
          logSuccess('addJavaScriptHandler closeWindow args - $args',
              name: "WEBVIEW");
          Navigator.of(context).pop(args[0]);
        });
    webController.addJavaScriptHandler(
        handlerName: 'setJson',
        callback: (args) {
          //![OhWebView] addJavaScriptHandler closeModal args - [{isSuccess: false, message: 사용자가 결제를 취소하였습니다}]
          logSuccess('addJavaScriptHandler setJson args - $args',
              name: "WEBVIEW");
        });
    webController.addJavaScriptHandler(
        handlerName: 'getJson',
        callback: (args) {
          //![OhWebView] addJavaScriptHandler closeModal args - [{isSuccess: false, message: 사용자가 결제를 취소하였습니다}]
          logSuccess('addJavaScriptHandler getJson args - $args',
              name: "WEBVIEW");
        });

    // SNS 로그인 핸들러
    //20251211 수정전
// webController.addJavaScriptHandler(
//     handlerName: 'KakaoLogin',
//     callback: (args) async {
//       print('🟦 KakaoLogin 핸들러 시작');
//       logSuccess('KakaoLogin handler called', name: "WEBVIEW");

//       final result = await KakaoAuthService.shared.signInWithKakao();
//       print('🟦 signInWithKakao 결과: $result');

//       if (result != null && result['access_token'] != null) {
//         String token = result['access_token'];
//         // 251211 수정
//         // String fcmToken = await ServiceManager.shared.getPushToken() ?? "";
//           String fcmToken = "";
//             try {
//               fcmToken = await ServiceManager.shared.getPushToken() ?? "";
//               print('🟦 FCM 토큰: $fcmToken');
//             } catch (e) {
//               print('🔴 FCM 토큰 가져오기 실패 (무시): $e');
//               fcmToken = "";
//             }
//         String authUrl = "${AppEnv.webAppUrl}sns/kakao_token_login?token=$token&fcm_token=$fcmToken";

//         print('🟦🟦 PHP 인증 URL: $authUrl');
//         logSuccess("PHP 인증 URL 호출: $authUrl", name: "WEBVIEW");

//         try {
//           print('🟦🟦🟦 loadUrl 시작');
//           await webController.loadUrl(
//               urlRequest: URLRequest(url: Uri.parse(authUrl))
//           );
//           print('🟦🟦🟦 loadUrl 완료');
//         } catch (e) {
//           print('🔴 loadUrl 에러: $e');
//         }

//       } else {
//         print('🔴 카카오 로그인 결과가 null');
//         logError("카카오 로그인 실패 또는 취소", name: "WEBVIEW");

//         await webController.evaluateJavascript(
//             source: "alert('카카오 로그인에 실패하였습니다.');"
//         );
//       }
//     });
// 수정후
webController.addJavaScriptHandler(
    handlerName: 'KakaoLogin',
    callback: (args) async {
      print('🟦 KakaoLogin 핸들러 시작');
      logSuccess('KakaoLogin handler called', name: "WEBVIEW");

      final result = await KakaoAuthService.shared.signInWithKakao();
      print('🟦 signInWithKakao 결과: $result');

      if (result != null && result['access_token'] != null) {
        String token = result['access_token'];
        
        // 🟢 FCM 토큰 가져오기 (없으면 재시도)
        String fcmToken = TokenNotifier.shared.getFcmToken() ?? "";
        
        if (fcmToken.isEmpty) {
          print('🟡 FCM 토큰 비어있음, 재시도 중...');
          try {
            await Future.delayed(Duration(milliseconds: 500));
            final newToken = await FirebaseMessaging.instance.getToken();
            if (newToken != null) {
              TokenNotifier.shared.setFemToken(newToken);
              fcmToken = newToken;
              print('🟢 FCM 토큰 재시도 성공: ${fcmToken.substring(0, 20)}...');
            } else {
              print('🔴 FCM 토큰 여전히 null (나중에 업데이트 필요)');
            }
          } catch (e) {
            print('🔴 FCM 토큰 재시도 실패: $e');
          }
        } else {
          print('🟦 FCM 토큰 이미 있음: ${fcmToken.substring(0, 20)}...');
        }
        
        String authUrl = "${AppEnv.webAppUrl}sns/kakao_token_login?token=$token&fcm_token=$fcmToken";

        print('🟦🟦 PHP 인증 URL 호출');
        logSuccess("PHP 인증 URL 호출: $authUrl", name: "WEBVIEW");

        try {
          print('🟦🟦🟦 loadUrl 시작');
await webController.loadUrl(
    urlRequest: URLRequest(url: Uri.parse(authUrl))
);
print('🟦🟦🟦 loadUrl 완료');

// 🍪 세션 쿠키 확인
await Future.delayed(Duration(seconds: 2));
final cookies = await CookieManager.instance().getCookies(
    url: Uri.parse(AppEnv.webAppUrl)
);
print('🍪 로그인 후 쿠키: $cookies');

// 세션 쿠키 있는지 확인
final hasSess = cookies.any((c) => 
    c.name.contains('ci_session') || c.name.contains('PHPSESSID')
);
print('🍪 세션 쿠키 존재: $hasSess');
        } catch (e) {
          print('🔴 loadUrl 에러: $e');
        }

      } else {
        print('🔴 카카오 로그인 결과가 null');
        logError("카카오 로그인 실패 또는 취소", name: "WEBVIEW");

        await webController.evaluateJavascript(
            source: "alert('카카오 로그인에 실패하였습니다.');"
        );
      }
    });

  // 수정전
    // webController.addJavaScriptHandler(
    //     handlerName: 'NaverLogin',
    //     callback: (args) async {
    //       logSuccess('NaverLogin handler called', name: "WEBVIEW");

    //       // 네이버 로그인 실행
    //       final result = await NaverAuthService.shared.signInWithNaver();

    //       if (result != null && result['access_token'] != null) {
    //         String token = result['access_token'];
    //         String fcmToken = await ServiceManager.shared.getPushToken() ?? "";

    //         // String authUrl = "${AppEnv.webAppUrl}sns/naver_token_login?token=$token&fcm_token=$fcmToken";
    //         String authUrl = "${AppEnv.webAppUrl}sns/naver_token_login?token=${Uri.encodeComponent(token)}&fcm_token=$fcmToken";
    //         logSuccess("PHP 인증 URL 호출: $authUrl", name: "WEBVIEW");

    //         await webController.loadUrl(
    //             urlRequest: URLRequest(url: Uri.parse(authUrl))
    //         );

    //       } else {
    //         logError("네이버 로그인 실패 또는 취소", name: "WEBVIEW");

    //         await webController.evaluateJavascript(
    //             source: "alert('네이버 로그인에 실패하였습니다.');"
    //         );
    //       }
    //     });
    //수정후
    webController.addJavaScriptHandler(
    handlerName: 'NaverLogin',
    callback: (args) async {
      logSuccess('NaverLogin handler called', name: "WEBVIEW");

      final result = await NaverAuthService.shared.signInWithNaver();

      if (result != null && result['access_token'] != null) {
        String token = result['access_token'];
        
        // 🟢 FCM 토큰 가져오기 (없으면 재시도)
        String fcmToken = TokenNotifier.shared.getFcmToken() ?? "";
        
        if (fcmToken.isEmpty) {
          print('🟡 FCM 토큰 비어있음, 재시도 중...');
          try {
            await Future.delayed(Duration(milliseconds: 500));
            final newToken = await FirebaseMessaging.instance.getToken();
            if (newToken != null) {
              TokenNotifier.shared.setFemToken(newToken);
              fcmToken = newToken;
              print('🟢 FCM 토큰 재시도 성공');
            }
          } catch (e) {
            print('🔴 FCM 토큰 재시도 실패: $e');
          }
        }

        String authUrl = "${AppEnv.webAppUrl}sns/naver_token_login?token=${Uri.encodeComponent(token)}&fcm_token=$fcmToken";
        logSuccess("PHP 인증 URL 호출: $authUrl", name: "WEBVIEW");

        await webController.loadUrl(
            urlRequest: URLRequest(url: Uri.parse(authUrl))
        );

      } else {
        logError("네이버 로그인 실패 또는 취소", name: "WEBVIEW");

        await webController.evaluateJavascript(
            source: "alert('네이버 로그인에 실패하였습니다.');"
        );
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    return _webView;
  }
}
