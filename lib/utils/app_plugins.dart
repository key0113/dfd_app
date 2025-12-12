import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';

const appChannel = MethodChannel('com.flutter.showgle/plugins');

class AppPlugin {
  static final AppPlugin shared = AppPlugin._privateConstructor();

  AppPlugin._privateConstructor() {}

  Future<void> systemLog(String message) async {
    if (Platform.isIOS) {
      // appChannel.invokeMethod("systemLog", message);
    }
  }

  Future<String?> getDownloadPath(String fileName) async {
    if (Platform.isAndroid) {
      return await appChannel.invokeMethod(
          'getDownloadPath', <String, Object>{'fileName': fileName});
    }
    return null;
  }
}
