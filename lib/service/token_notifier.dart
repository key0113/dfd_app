import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:newdfd/service/app_storage.dart';

class TokenNotifier extends ChangeNotifier {
  static final TokenNotifier shared = TokenNotifier._privateConstructor();
  TokenNotifier._privateConstructor();

  String? _fcmToken;

  setFemToken(String newValue) {
    _fcmToken = newValue;
    AppStorage.shared.pushToken = newValue;
    notifyListeners();
  }

    String? getFcmToken() {
    return _fcmToken;
  }
}
