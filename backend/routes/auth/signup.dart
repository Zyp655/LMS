import 'package:backend/repositories/user_repository.dart';
import 'package:backend/services/logger_service.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final repo = context.read<UserRepository>();
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email'] as String?;
    final password = body['password'] as String?;
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return Response.json(
          statusCode: 400, body: {'error': 'Vui lòng nhập email và mật khẩu'});
    }
    final user = await repo.createUser(email: email, password: password);
    return Response.json(
        body: {'message': 'Đăng ký thành công', 'id': user.id});
  } catch (e, stackTrace) {
    logger.error('Signup failed',
        error: e, stackTrace: stackTrace, context: 'signup');
    final errorString = e.toString();
    if (errorString.contains('23505') ||
        errorString.contains('already exists')) {
      return Response.json(statusCode: 409, body: {
        'error': 'Email này đã được sử dụng. Vui lòng chọn email khác.'
      });
    }
    return Response.json(
        statusCode: 500,
        body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'});
  }
}
