import 'dart:developer';

class UtilTools {
  static Map<String, String> getUtmFromUri(Uri uri) {
    final queryParameters = uri.queryParameters;
    final utmMap = <String, String>{};
    (queryParameters).forEach((key, value) {
      log('payload : $key, $value', name: 'appsflyerSdk onAppOpenAttribution');
      if (key.startsWith('utm_')) {
        utmMap[key] = '$value';
      }
    });
    return utmMap;
  }
}
