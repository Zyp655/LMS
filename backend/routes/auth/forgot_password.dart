import 'dart:math';
import 'package:backend/repositories/user_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/helpers/env_helper.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final repo = context.read<UserRepository>();
  final body = await context.request.json() as Map<String, dynamic>;
  final email = body['email'] as String;
  final user = await repo.getUserByEmail(email);
  if (user == null) {
    return Response.json(
        body: {'message': 'Nếu email tồn tại, mã OTP đã được gửi.'});
  }
  final otp = (100000 + Random().nextInt(900000)).toString();
  await repo.saveResetToken(email, otp);
  await _sendEmail(email, otp);
  return Response.json(body: {'message': 'Đã gửi mã OTP qua email'});
}

Future<void> _sendEmail(String recipient, String otp) async {
  final env = loadEnv();
  final username = env['SMTP_EMAIL'] ?? '';
  final password = env['SMTP_PASSWORD'] ?? '';

  if (username.isEmpty || password.isEmpty) {
    return;
  }

  final smtpServer = gmail(username, password);
  final message = Message()
    ..from = Address(username, 'LMS App Support')
    ..recipients.add(recipient)
    ..subject = 'Đặt lại mật khẩu - LMS App'
    ..html = '''
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px;">
        <h2 style="color: #6366F1;">Đặt lại mật khẩu</h2>
        <p>Xin chào,</p>
        <p>Mã xác nhận của bạn là:</p>
        <div style="background: #F3F4F6; border-radius: 12px; padding: 20px; text-align: center; margin: 16px 0;">
          <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #6366F1;">$otp</span>
        </div>
        <p>Mã có hiệu lực trong <strong>15 phút</strong>.</p>
        <p style="color: #888; font-size: 13px;">Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.</p>
      </div>
    ''';
  try {
    final result = await send(message, smtpServer);
    print('[SMTP] Email sent to $recipient: ${result.mail.subject}');
  } catch (e) {
    print('[SMTP] Failed to send email to $recipient: $e');
  }
}
