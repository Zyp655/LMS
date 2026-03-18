import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';

import 'rbac_middleware.dart';

final _jwtSecret = () {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  return env['JWT_SECRET'] ?? 'my_secret_key_123';
}();

const _publicPrefixes = [
  '/auth/',
  '/files/',
  '/cron/',
];
const _publicExact = [
  '/',
  '/fix_email',
  '/chat/ws',
];

Handler authMiddleware(Handler handler) {
  return (context) async {
    if (context.request.method == HttpMethod.options) {
      return handler(context);
    }

    final path = context.request.uri.path;

    if (_publicExact.contains(path) ||
        _publicPrefixes.any((p) => path.startsWith(p))) {
      return handler(context);
    }

    final authHeader = context.request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(statusCode: 401, body: {'error': 'Missing Token'});
    }

    final token = authHeader.substring(7);

    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final payload = jwt.payload as Map<String, dynamic>;
      final userId = payload['id'] as int;
      final role = (payload['role'] as int?) ?? 0;

      return provider<int>((_) => userId)(
        provider<UserRole>((_) => UserRole(role))(handler),
      )(context);
    } catch (e) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Token không hợp lệ hoặc đã hết hạn.'},
      );
    }
  };
}
