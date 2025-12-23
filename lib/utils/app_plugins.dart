import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';

const appChannel = MethodChannel('com.newdfd.membership/plugins');

class AppPlugin {
  static final AppPlugin shared = AppPlugin._privateConstructor();

  AppPlugin._privateConstructor() {}

  Future<void> systemLog(String message) async {
    if (Platform.isIOS) {
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
