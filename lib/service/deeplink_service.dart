import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:newdfd/service/app_env.dart';

class DeepLinkService extends ChangeNotifier {
  static final DeepLinkService shared = DeepLinkService._privateConstructor();

  DeepLinkService._privateConstructor();

  start() {}

  String? _deepLinkValue;

  String? getDeepLinkValue() {
    if (_deepLinkValue != null) {
      if (_deepLinkValue != "/" && _deepLinkValue!.endsWith('/')) {
        return _deepLinkValue!.substring(0, _deepLinkValue!.length - 1);
      }
    }
    return _deepLinkValue;
  }

  deleteDeepLinkValue() {
    _deepLinkValue = null;
  }

  setDeeplinkValueByInitialLink(String initialLink) {
    final uri = Uri.parse(initialLink);
    final deepLinkValue = uri.queryParameters['deep_link_value'];
    if (deepLinkValue != null) {
      setDeepLinkValue(deepLinkValue);
    } else {
      setDeepLinkValue(initialLink);
    }
  }

  setDeepLinkValue(String? newValue) {
    if (newValue != null) {
      newValue = Uri.decodeComponent(newValue);
      var pathUri = Uri.parse(newValue);
      newValue = pathUri.toString();
      _deepLinkValue = newValue;
      notifyListeners();
    }
  }

  setDeeplinkValueByRemoteMessage(RemoteMessage initalMessage) {
    final link = initalMessage.data['link_url'];

    if (link != null && link.isNotEmpty) {

      if (link.startsWith('/')) {
        final fullUrl = '${AppEnv.webAppUrl}$link';
        setDeepLinkValue(fullUrl);
        return;
      }

      final Uri? uri = Uri.parse(link);
      if (uri != null) {

        setDeepLinkValue(link);
        return;
      }
    }
  }
}
