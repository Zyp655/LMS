import 'package:dart_frog/dart_frog.dart';

Middleware rateLimitMiddleware({
  int maxRequests = 60,
  Duration window = const Duration(minutes: 1),
}) {
  final buckets = <String, List<DateTime>>{};

  return (handler) {
    return (context) async {
      final ip = context.request.headers['x-forwarded-for'] ??
          context.request.headers['x-real-ip'] ??
          'unknown';

      final now = DateTime.now();
      final cutoff = now.subtract(window);

      final timestamps = buckets.putIfAbsent(ip, () => []);
      timestamps.removeWhere((t) => t.isBefore(cutoff));

      if (timestamps.length >= maxRequests) {
        final oldestValid = timestamps.first;
        final retryAfter =
            window.inSeconds - now.difference(oldestValid).inSeconds;

        return Response.json(
          statusCode: 429,
          headers: {'Retry-After': '${retryAfter > 0 ? retryAfter : 1}'},
          body: {
            'error': 'Too Many Requests',
            'message':
                'Quá nhiều yêu cầu. Vui lòng thử lại sau $retryAfter giây.',
            'retryAfter': retryAfter > 0 ? retryAfter : 1,
          },
        );
      }

      timestamps.add(now);

      if (timestamps.length == 1 && buckets.length > 500) {
        buckets.removeWhere((_, ts) {
          ts.removeWhere((t) => t.isBefore(cutoff));
          return ts.isEmpty;
        });
      }

      return handler(context);
    };
  };
}
