import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final db = context.read<AppDatabase>();
    final body = await context.request.json() as Map<String, dynamic>;

    final email = (body['email'] as String?)?.trim() ?? '';
    final otp = (body['otp'] as String?)?.trim() ?? '';
    final newPassword = (body['newPassword'] as String?)?.trim() ?? '';

    if (email.isEmpty || otp.isEmpty || newPassword.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Email, OTP và mật khẩu mới là bắt buộc'},
      );
    }

    if (newPassword.length < 6) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Mật khẩu mới phải có ít nhất 6 ký tự'},
      );
    }

    final user = await (db.select(db.users)
          ..where((t) => t.email.equals(email)))
        .getSingleOrNull();

    if (user == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Không tìm thấy tài khoản với email này'},
      );
    }

    if (user.resetToken == null || user.resetTokenExpiry == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'Chưa yêu cầu đặt lại mật khẩu. Vui lòng gửi OTP trước.'
        },
      );
    }

    if (DateTime.now().isAfter(user.resetTokenExpiry!)) {
      // Clear expired token
      await (db.update(db.users)..where((t) => t.id.equals(user.id))).write(
        const UsersCompanion(
          resetToken: Value(null),
          resetTokenExpiry: Value(null),
        ),
      );
      return Response.json(
        statusCode: 400,
        body: {'error': 'Mã OTP đã hết hạn. Vui lòng gửi lại.'},
      );
    }

    if (user.resetToken != otp) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Mã OTP không đúng'},
      );
    }

    // OTP valid — update password and clear token
    final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    await (db.update(db.users)..where((t) => t.id.equals(user.id))).write(
      UsersCompanion(
        passwordHash: Value(hashedPassword),
        resetToken: const Value(null),
        resetTokenExpiry: const Value(null),
      ),
    );

    return Response.json(
      body: {'message': 'Đặt lại mật khẩu thành công!'},
    );
  } catch (e, stackTrace) {
    print('RESET PASSWORD ERROR: $e');
    print('STACK TRACE: $stackTrace');
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({
        'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.',
      }),
    );
  }
}
