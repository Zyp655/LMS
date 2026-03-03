import 'package:backend/middleware/rate_limit_middleware.dart';
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return handler.use(
    rateLimitMiddleware(maxRequests: 10, window: const Duration(minutes: 1)),
  );
}
