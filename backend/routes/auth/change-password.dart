import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:backend/utils/isolate_utils.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';
import 'package:backend/database/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }

  try {
    final authHeader = context.request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Yêu cầu đăng nhập để đổi mật khẩu'},
      );
    }

    final token = authHeader.substring(7);
    final JWT jwt;
    try {
      final env = DotEnv(includePlatformEnvironment: true)..load();
      final jwtSecret = env['JWT_SECRET'] ?? 'my_secret_key_123';
      jwt = JWT.verify(token, SecretKey(jwtSecret));
    } catch (_) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Token không hợp lệ hoặc đã hết hạn'},
      );
    }

    final userId = (jwt.payload as Map<String, dynamic>)['id'] as int;
    final db = context.read<AppDatabase>();

    final body = await context.request.json() as Map<String, dynamic>;
    final currentPassword = body['currentPassword'] as String?;
    final newPassword = body['newPassword'] as String?;

    if (currentPassword == null ||
        currentPassword.isEmpty ||
        newPassword == null ||
        newPassword.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới'},
      );
    }

    if (newPassword.length < 6) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Mật khẩu mới phải có ít nhất 6 ký tự'},
      );
    }

    final user = await (db.select(db.users)..where((t) => t.id.equals(userId)))
        .getSingleOrNull();

    if (user == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Không tìm thấy người dùng'},
      );
    }

    if (!await IsolateUtils.checkPassword(currentPassword, user.passwordHash)) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Mật khẩu hiện tại không đúng'},
      );
    }

    final hashedNewPassword = await IsolateUtils.hashPassword(newPassword);
    await (db.update(db.users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        passwordHash: Value(hashedNewPassword),
      ),
    );

    return Response.json(
      body: {
        'success': true,
        'message': 'Đổi mật khẩu thành công',
      },
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({
        'success': false,
        'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.',
      }),
    );
  }
}
