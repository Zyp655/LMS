import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

Middleware corsMiddleware() {
  return (handler) {
    return (context) async {
      if (context.request.method == HttpMethod.options) {
        return Response(
          statusCode: HttpStatus.ok,
          headers: _corsHeaders,
        );
      }

      final response = await handler(context);
      return response.copyWith(
        headers: {...response.headers, ..._corsHeaders},
      );
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Range',
  'Access-Control-Expose-Headers':
      'Accept-Ranges, Content-Range, Content-Length',
  'Access-Control-Max-Age': '86400',
};
