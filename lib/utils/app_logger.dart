import 'dart:developer' as developer;

import 'package:newdfd/utils/app_plugins.dart';

class AppLogger {
  static String DEEP_LINK = 'DEEPLINK';
  static String PUSH_MESSAGE = 'PUSH_MESSAGE';

  static pushMessage(message, {bool isSystemLog = true}) {
    logMagenta("$message", name: PUSH_MESSAGE);
    if (isSystemLog) {
      AppPlugin.shared.systemLog(message);
    }
  }

  static deepLink(message, {bool isSystemLog = true}) {
    logMagenta("$message", name: DEEP_LINK);
    if (isSystemLog) {
      AppPlugin.shared.systemLog(message);
    }
  }
}

void logMagenta(String msg, {String name = 'BIGC'}) {
  // logger.v("[$name] - $msg");
  developer.log('\x1B[45m$msg\x1B[0m', name: name);
}

// Blue text
void logCyan(String msg, {String name = 'BIGC'}) {
  // logger.v("[$name] - $msg");
  developer.log('\x1B[36m$msg\x1B[0m', name: name);
}

// Blue text
void logInfo(String msg, {String name = 'BIGC'}) {
  // logger.d("[$name] - $msg");
  developer.log('\x1B[34m$msg\x1B[0m', name: name);
}

// Green text
void logSuccess(String msg, {String name = 'BIGC'}) {
  // logger.i("[$name] - $msg");
  developer.log('\x1B[32m$msg\x1B[0m', name: name);
}

// Yellow text
void logWarning(String msg, {String name = 'BIGC'}) {
  // logger.w("[$name] - $msg");
  developer.log('\x1B[33m$msg\x1B[0m', name: name);
}

// Red text
void logError(String msg, {String name = 'BIGC'}) {
  // logger.e("[$name] - $msg");
  developer.log('\x1B[31m$msg\x1B[0m', name: name);
}
