import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:newdfd/service/app_env.dart';
import 'package:newdfd/service/deeplink_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:newdfd/service/topic_manage.dart';
import 'package:newdfd/utils/app_logger.dart';
import 'package:newdfd/widgets/app_webview.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ModalPage extends StatefulWidget {
  final String url;
  const ModalPage({
    Key? key,
    required this.url,
  }) : super(key: key);

  static Future showWeb(BuildContext context, String url,
      {bool showTop = true}) async {
    final result = await showMaterialModalBottomSheet(
      context: context,
      enableDrag: false,
      builder: (BuildContext bc) {
        return ModalPage(
          url: url,
        );
      },
    );
    return result;
  }

  @override
  State<ModalPage> createState() => _ModalPageState();
}

class _ModalPageState extends State<ModalPage> {
  bool isWebLoadFinished = false;
  InAppWebViewController? _webViewController;
  late VoidCallback deeplinkListener;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  checkAppAuto() {
    _webViewController?.evaluateJavascript(
        source: "if (typeof appAuto != 'undefined') {appAuto();}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: AppWebView(
        urlStr: widget.url,
        didSetController: (controller) {
          _webViewController = controller;
        },
        onLoadStop: (url) {
          checkAppAuto();
        },
      ),
    ));
  }
}
