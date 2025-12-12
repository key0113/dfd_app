import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static String get webAppUrl {
    return dotenv.env['WEBAPP_URL']!;
  }

  static String get cookieDomain {
    return dotenv.env['COOKIE_DOMAIN']!;
  }
}
