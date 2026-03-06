import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  try {
    final db = context.read<AppDatabase>();
    final params = context.request.uri.queryParameters;
    final lessonId = int.tryParse(params['lessonId'] ?? '');

    if (lessonId == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'lessonId query parameter is required'},
      );
    }

    final files = await (db.select(db.courseFiles)
          ..where((f) => f.lessonId.equals(lessonId)))
        .get();

    final result = files
        .map(
          (f) => {
            'id': f.id,
            'fileName': f.fileName,
            'fileType': f.fileType,
            'fileSizeBytes': f.fileSizeBytes,
            'mimeType': f.mimeType,
            'uploadedAt': f.uploadedAt.toIso8601String(),
            'downloadUrl': '/files/${f.id}',
          },
        )
        .toList();

    return Response.json(body: {
      'files': result,
      'total': result.length,
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
