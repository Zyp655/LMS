import 'dart:math';
import 'package:backend/database/database.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:backend/helpers/env_helper.dart';
import 'package:drift/drift.dart';

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
  if (user == null || !await repo.verifyPassword(password, user.passwordHash, email: email)) {
    return Response.json(
        statusCode: 401, body: {'message': 'Sai email hoặc mật khẩu'});
  }
  if (user.isBanned) {
    return Response.json(
        statusCode: 403,
        body: {'message': 'Tài khoản đã bị khoá. Liên hệ quản trị viên.'});
  }

  final sessionToken = _generateSessionToken();

  final db = context.read<AppDatabase>();
  await (db.update(db.users)..where((u) => u.id.equals(user.id))).write(
    UsersCompanion(activeSessionToken: Value(sessionToken)),
  );

  final jwt = JWT({
    'id': user.id,
    'email': user.email,
    'role': user.role,
    'sessionToken': sessionToken,
  });
  final env = loadEnv();
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

String _generateSessionToken() {
  final random = Random.secure();
  final values = List<int>.generate(32, (_) => random.nextInt(256));
  return values.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
}
