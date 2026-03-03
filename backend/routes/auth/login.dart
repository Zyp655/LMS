import 'package:backend/repositories/user_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final repo = context.read<UserRepository>();
  final body = await context.request.json() as Map<String, dynamic>;
  final email = body['email'] as String?;
  final password = body['password'] as String?;
  if (email == null || password == null || email.isEmpty || password.isEmpty) {
    return Response.json(
        statusCode: 400,
        body: {'message': 'Vui lòng nhập đầy đủ email và mật khẩu'});
  }
  final user = await repo.getUserByEmail(email);
  if (user == null || !repo.verifyPassword(password, user.passwordHash)) {
    return Response.json(
        statusCode: 401, body: {'message': 'Sai email hoặc mật khẩu'});
  }
  if (user.isBanned) {
    return Response.json(
        statusCode: 403,
        body: {'message': 'Tài khoản đã bị khoá. Liên hệ quản trị viên.'});
  }
  final jwt = JWT({
    'id': user.id,
    'email': user.email,
    'role': user.role,
  });
  final env = DotEnv()..load();
  final jwtSecret = env['JWT_SECRET'] ?? 'my_secret_key_123';
  final token = jwt.sign(SecretKey(jwtSecret));
  return Response.json(body: {
    'message': 'Đăng nhập thành công',
    'token': token,
    'id': user.id,
    'email': user.email,
    'fullName': user.fullName,
    'role': user.role,
    'departmentId': user.departmentId,
  });
}
