import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

Middleware gzipMiddleware() {
  return (handler) {
    return (context) async {
      final response = await handler(context);

      final acceptEncoding =
          context.request.headers['Accept-Encoding'] ?? '';
      if (!acceptEncoding.contains('gzip')) return response;

      final contentType = response.headers['content-type'] ?? '';
      final isCompressible = contentType.contains('json') ||
          contentType.contains('text') ||
          contentType.contains('javascript') ||
          contentType.contains('xml');
      if (!isCompressible && !contentType.isEmpty) return response;

      final body = await response.body();
      if (body.isEmpty || body.length < 256) return response;

      final compressed = gzip.encode(utf8.encode(body));

      return Response.bytes(
        statusCode: response.statusCode,
        body: compressed,
        headers: {
          ...response.headers,
          'Content-Encoding': 'gzip',
          'Content-Length': '${compressed.length}',
          'Vary': 'Accept-Encoding',
        },
      );
    };
  };
}
