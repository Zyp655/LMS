import 'package:flutter/foundation.dart'
    show kIsWeb, kReleaseMode, defaultTargetPlatform, TargetPlatform;

enum AppEnvironment { development, production }

class ApiConstants {
  static const String _env =
      String.fromEnvironment('ENV', defaultValue: 'auto');

  static const String _productionUrl =
      'https://lms-production-c546.up.railway.app';
  static const int _devPort = 8080;

  static AppEnvironment get environment {
    if (_env == 'production' || kReleaseMode) return AppEnvironment.production;
    return AppEnvironment.development;
  }

  static String get baseUrl {
    if (environment == AppEnvironment.production) return _productionUrl;

    if (kIsWeb) return 'http://localhost:$_devPort';

    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
    return 'http://$host:$_devPort';
  }

  static String resolveFileUrl(String url) {
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return url.startsWith('/') ? '$baseUrl$url' : '$baseUrl/$url';
    }
    if (environment == AppEnvironment.production) {
      url = url.replaceFirst(RegExp(r'http://localhost:\d+'), _productionUrl);
      url = url.replaceFirst(RegExp(r'http://10\.0\.2\.2:\d+'), _productionUrl);
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      url = url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }
}
