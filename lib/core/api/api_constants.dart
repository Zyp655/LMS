import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConstants {
  static const String _localIP = '192.168.1.42';
  static const int _port = 8080;

  static const String _productionUrl = 'https://lms-production-c546.up.railway.app';

  static String get baseUrl {
    if (kIsWeb) {
      return _productionUrl;
    }
    final host = defaultTargetPlatform == TargetPlatform.android
        ? _localIP
        : 'localhost';
    return 'http://$host:$_port';
  }
}
