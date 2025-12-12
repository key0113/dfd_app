import 'dart:io';

import 'package:newdfd/service/app_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:newdfd/utils/app_logger.dart';
import 'package:newdfd/utils/app_plugins.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ServiceManager {
  static final ServiceManager shared = ServiceManager._internal();
  ServiceManager._internal();

  setUserLevesl(List userLevels) async {
    final userLevelBf = getUserLevels();
    final toRemove = [];
    for (var lv in userLevelBf) {
      if (!userLevels.contains(lv)) {
        toRemove.add(lv);
      }
    }

    for (var rm in toRemove) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(rm);
    }

    for (var level in userLevels) {
      await FirebaseMessaging.instance.subscribeToTopic(level);
    }
    AppStorage.shared.setUserLevel(userLevels);
  }

  List getUserLevels() {
    return AppStorage.shared.getUserLevel();
  }

  setPushOnOff(String newValue) async {
    AppStorage.shared.setIsPushOn(newValue);
  }

  String getPushOnOff() {
    return AppStorage.shared.getPushOn();
  }

  Future<String> getPushToken() async {
    final pushToken = await FirebaseMessaging.instance.getToken();
    return pushToken ?? "";
  }

  Future<String> getVersion() async {
    var packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<String> getUUID() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor ?? ""; // unique ID on iOS
    } else if (Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.id; // unique ID on Android
    } else {
      return "";
    }
  }

  static Future<String?> _getFileSavePath({required String fileName}) async {
    if (Platform.isAndroid) {
      final savePath = await AppPlugin.shared.getDownloadPath(fileName);
      return savePath;
    }
    final directory = await getApplicationDocumentsDirectory();
    final savePath = '${directory.path}/$fileName';
    return savePath;
  }

  Future downloadFile(String url, {String? fileName}) async {
    final dio = Dio();
    fileName ??= Uri.parse(url).pathSegments.last;
    Response<List<int>> rs = await dio.get<List<int>>(url,
        options: Options(responseType: ResponseType.bytes));
    if (rs.data != null) {
      if (fileName.split(".").length == 1) {
        final headers = rs.headers;
        final contentType = headers['content-type'];
        if (contentType != null) {
          logSuccess("contentType - $contentType", name: "Donwload");
          final ext = contentType[0].split("/").last;
          final savePath = await _getFileSavePath(fileName: "$fileName.$ext");
          if (savePath != null) {
            final File file = File(savePath);
            await file.writeAsBytes(rs.data!);
            return true;
          }
        }
      } else {
        final savePath = await _getFileSavePath(fileName: fileName);
        if (savePath != null) {
          final File file = File(savePath);
          await file.writeAsBytes(rs.data!);
          return true;
        }
      }
    }
    return false;
  }

  // Future downloadFile2(String url) async {
  //   final dio = Dio();
  //   final fileName = Uri.parse(url).pathSegments.last;
  //   final savePath = await _getFileSavePath(fileName: fileName);
  //   final response = await dio.download(
  //     url,
  //     savePath,
  //   );
  //   logSuccess("downloadFile - $response", name: "Donwload");
  // }

  shareUrl(String url) {
    Share.share(url);
  }

  bool get isFirstLanch {
    return AppStorage.shared.isFirstLaunch;
  }

  setNotFirstLanch() {
    AppStorage.shared.setFirstLaunch("N");
  }
}
