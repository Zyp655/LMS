import 'package:backend/services/redis_service.dart';
import 'package:dart_frog/dart_frog.dart';

Middleware rateLimitMiddleware({
  int maxRequests = 60,
  Duration window = const Duration(minutes: 1),
}) {
  final redis = RedisService();
  final fallbackBuckets = <String, List<DateTime>>{};

  return (handler) {
    return (context) async {
      final ip = context.request.headers['x-forwarded-for'] ??
          context.request.headers['x-real-ip'] ??
          'unknown';

      if (redis.isConnected) {
        return _redisRateLimit(
          context, handler, redis, ip, maxRequests, window);
      }
      return _memoryRateLimit(
        context, handler, fallbackBuckets, ip, maxRequests, window);
    };
  };
}

Future<Response> _redisRateLimit(
  RequestContext context,
  Handler handler,
  RedisService redis,
  String ip,
  int maxRequests,
  Duration window,
) async {
  final key = 'ratelimit:$ip';
  final count = await redis.increment(key, ttlSeconds: window.inSeconds);

  if (count > maxRequests) {
    final remaining = await redis.ttl(key) ?? window.inSeconds;
    return Response.json(
      statusCode: 429,
      headers: {'Retry-After': '$remaining'},
      body: {
        'error': 'Too Many Requests',
        'message':
            'Qu\u00e1 nhi\u1ec1u y\u00eau c\u1ea7u. Vui l\u00f2ng th\u1eed l\u1ea1i sau $remaining gi\u00e2y.',
        'retryAfter': remaining,
      },
    );
  }

  return handler(context);
}

Future<Response> _memoryRateLimit(
  RequestContext context,
  Handler handler,
  Map<String, List<DateTime>> buckets,
  String ip,
  int maxRequests,
  Duration window,
) async {
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
            'Qu\u00e1 nhi\u1ec1u y\u00eau c\u1ea7u. Vui l\u00f2ng th\u1eed l\u1ea1i sau $retryAfter gi\u00e2y.',
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
}
