import 'package:dart_frog/dart_frog.dart';

import '../services/logger_service.dart';

Middleware errorHandlerMiddleware() {
  return (handler) {
    return (context) async {
      try {
        return await handler(context);
      } catch (e, st) {
        if (e.toString().contains('hijack')) rethrow;

        final path = context.request.uri.path;
        final method = context.request.method.value;

        logger.error(
          'Unhandled exception on $method $path',
          error: e,
          stackTrace: st,
          context: 'ErrorHandler',
        );

        return Response.json(
          statusCode: 500,
          body: {
            'error': 'Internal Server Error',
            'message': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.',
          },
        );
      }
    };
  };
}

Response safeError(
  Object error,
  StackTrace stackTrace, {
  int statusCode = 500,
  String message = 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.',
  String? context,
}) {
  logger.error(
    context ?? 'Route error',
    error: error,
    stackTrace: stackTrace,
    context: context,
  );

  return Response.json(
    statusCode: statusCode,
    body: {
      'error': 'Internal Server Error',
      'message': message,
    },
  );
}
