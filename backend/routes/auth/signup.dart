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
          statusCode: 400, body: {'error': 'Vui lòng nh?p email và m?t kh?u'});
    }
    final user = await repo.createUser(email: email, password: password);
    return Response.json(
        body: {'message': 'Ðang ký thành công', 'id': user.id});
  } catch (e, stackTrace) {
    logger.error('Signup failed',
        error: e, stackTrace: stackTrace, context: 'signup');
    final errorString = e.toString();
    if (errorString.contains('23505') ||
        errorString.contains('already exists')) {
      return Response.json(statusCode: 409, body: {
        'error': 'Email này dã du?c s? d?ng. Vui lòng ch?n email khác.'
      });
    }
    return Response.json(
        statusCode: 500,
        body: {'error': 'Ðã x?y ra l?i h? th?ng. Vui lòng th? l?i sau.'});
  }
}
