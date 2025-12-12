// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:newdfd/service/app_env.dart';
import 'package:newdfd/service/deeplink_service.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:newdfd/utils/app_logger.dart';
import 'package:newdfd/widgets/app_webview.dart';

class WindowPage extends StatefulWidget {
  final CreateWindowAction createWindowAction;
  const WindowPage({
    Key? key,
    required this.createWindowAction,
  }) : super(key: key);

  static Future showWeb(
      BuildContext context, CreateWindowAction createWindowAction,
      {bool showTop = true}) async {
    final result = await showMaterialModalBottomSheet(
      context: context,
      enableDrag: false,
      builder: (BuildContext bc) {
        return WindowPage(
          createWindowAction: createWindowAction,
        );
      },
    );
    return result;
  }

  @override
  State<WindowPage> createState() => _WindowPageState();
}

class _WindowPageState extends State<WindowPage> {
  Future<bool>? loadingFuture;
  bool isWebLoadFinished = false;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    loadingFuture = startLoading();
  }

  Future<bool> startLoading() async {
    return true;
  }

  Future checkDeepLink() async {
    final deeplink = DeepLinkService.shared.getDeepLinkValue();
    if (deeplink != null) {
      _handleDeepLink(deeplink);
    }
  }

  _handleDeepLink(String deeplink) async {
    if (isWebLoadFinished) {
      AppLogger.deepLink("_handleDeepLink - $deeplink");
      //! 기타 딥링크
      if (_webViewController != null) {
        _webViewController!
            .evaluateJavascript(source: 'bigc_deeplink("$deeplink");');
        DeepLinkService.shared.deleteDeepLinkValue();
      }
    }
  }

  Uri get getHomeUrl {
    return Uri.parse(AppEnv.webAppUrl);
  }

  // Future<bool> setCookies(BuildContext context) async {
  //   final expireDate =
  //       DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;

  //   final url = getHomeUrl;

  //   await CookieManager.instance().setCookie(
  //     url: url,
  //     name: '_aa',
  //     value: '',
  //     domain: AppEnv.cookieDomain,
  //     expiresDate: expireDate,
  //   );

  //   return true;
  // }

  @override
  Widget build(BuildContext context) {
    final windowId = widget.createWindowAction.windowId;
    return FutureBuilder(
        future: loadingFuture,
        builder: (context, snapshot) {
          return Scaffold(
            body: AppWebView(
                windowId: windowId,
                didSetController: (controller) {
                  _webViewController = controller;
                }),
          );
        });
  }
}
