import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { dev, prod }

class AppEnv {
  AppEnv._();

  static AppEnvironment _env = AppEnvironment.dev;

  static Future<void> init({AppEnvironment env = AppEnvironment.dev}) async {
    _env = env;
    final fileName = env == AppEnvironment.prod ? '.env.prod' : '.env.dev';
    await dotenv.load(fileName: fileName);
  }

  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  static bool get isDev => _env == AppEnvironment.dev;
}
