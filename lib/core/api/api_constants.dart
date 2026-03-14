import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConstants {
  static const String _localIP = '192.168.1.42';
  static const int _port = 8080;

  // TODO: Replace with your production backend URL when deployed
  static const String _productionUrl = '';

  static String get baseUrl {
    if (_productionUrl.isNotEmpty) {
      return _productionUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:$_port';
    }
    final host = defaultTargetPlatform == TargetPlatform.android
        ? _localIP
        : 'localhost';
    return 'http://$host:$_port';
  }
}
