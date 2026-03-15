import 'package:dart_frog/dart_frog.dart';

Middleware cacheHeadersMiddleware() {
  return (handler) {
    return (context) async {
      final response = await handler(context);

      if (context.request.method != HttpMethod.get) return response;

      final path = context.request.uri.path;

      final cacheSeconds = _getCacheDuration(path);
      if (cacheSeconds <= 0) return response;

      return response.copyWith(
        headers: {
          ...response.headers,
          'Cache-Control': 'public, max-age=$cacheSeconds',
        },
      );
    };
  };
}

int _getCacheDuration(String path) {
  if (path.startsWith('/auth/')) return 0;
  if (path.startsWith('/chat/')) return 0;
  if (path.startsWith('/notifications')) return 0;
  if (path.contains('/analytics/')) return 120;
  if (path.startsWith('/courses')) return 60;
  if (path.startsWith('/files/')) return 3600;
  return 30;
}
