import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:get_storage/get_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static final AppStorage shared = AppStorage._internal();
  AppStorage._internal();

  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  setIsPushOn(String newValue) {
    writStorage(newValue, key: "isPushOn");
  }

  String getPushOn() {
    final value = readStorage(key: "isPushOn");
    if (value == null) {
      return "Y";
    } else {
      return value;
    }
  }

  setUserLevel(List newValue) {
    final encoded = jsonEncode(newValue);
    writStorage(encoded, key: "userLevels");
  }

  List getUserLevel() {
    final value = readStorage(key: "userLevels");
    if (value != null) {
      final topicList = jsonDecode(value) as List?;
      if (topicList != null) {
        return topicList;
      }
    }
    return ["AA"];
  }

  setFirstLaunch(String? newValue) {
    writStorage(newValue, key: "didLaunched");
  }

  bool get isFirstLaunch {
    final value = readStorage(key: "didLaunched");
    if (value == null) {
      return true;
    } else {
      return false;
    }
  }

  /// pushToken
  set pushToken(newValue) {
    writStorage(newValue, key: "pushToken");
  }

  String? get pushToken {
    return readStorage(key: "pushToken");
  }

  /// apnsToken
  set apnsToken(newValue) {
    writStorage(newValue, key: "apnsToken");
  }

  String? get apnsToken {
    return readStorage(key: "apnsToken");
  }

  /// deviceId
  set deviceId(newValue) {
    writStorage(newValue, key: "deviceId");
  }

  String? get deviceId {
    return readStorage(key: "deviceId");
  }

  writStorage(String? newValue, {required String key}) {
    if (newValue != null) {
      storage.setString(key, newValue);
    } else {
      storage.remove(key);
    }
  }

  writBoolStorage(bool? newValue, {required String key}) {
    if (newValue != null) {
      storage.setBool(key, newValue);
    } else {
      storage.remove(key);
    }
  }

  String? readStorage({required String key}) {
    return storage.getString(key);
  }

  bool? readBoolStorage({required String key}) {
    return storage.getBool(key);
  }

  Future<String> getDeviceId() async {
    if (deviceId == null) {
      if (Platform.isAndroid) {
        final build = await deviceInfoPlugin.androidInfo;
        deviceId = build.id;
        return deviceId ?? '';
      } else if (Platform.isIOS) {
        final build = await deviceInfoPlugin.iosInfo;
        deviceId = build.identifierForVendor;
        return deviceId ?? '';
      }
    } else {
      return deviceId!;
    }
    return '';
  }

  late SharedPreferences storage;

  init() async {
    storage = await SharedPreferences.getInstance();
  }
}
