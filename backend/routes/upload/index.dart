import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:backend/services/file_upload_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final db = context.read<AppDatabase>();
  final service = FileUploadService(db);

  try {
    final contentType = context.request.headers['content-type'] ?? '';

    if (contentType.contains('multipart/form-data')) {
      return _handleMultipart(context, service);
    }
    return _handleJson(context, service);
  } catch (e, st) {
    print('[Upload] Error: $e\n$st');
    if (e is FileTooLargeException) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': e.message},
      );
    }
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Upload failed: $e'},
    );
  }
}

Future<Response> _handleMultipart(
  RequestContext context,
  FileUploadService service,
) async {
  final formData = await context.request.formData();
  final uploadedByStr = formData.fields['uploadedBy'];
  final fileType = formData.fields['fileType'] ?? 'video';
  final lessonIdStr = formData.fields['lessonId'];

  if (uploadedByStr == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'uploadedBy is required'},
    );
  }
  final uploadedBy = int.tryParse(uploadedByStr);
  if (uploadedBy == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'uploadedBy must be a valid integer'},
    );
  }

  final uploadedFile = formData.files['file'];
  if (uploadedFile == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'No file uploaded'},
    );
  }

  final lessonId = lessonIdStr != null ? int.tryParse(lessonIdStr) : null;
  final fileBytes = await uploadedFile.readAsBytes();

  final record = await service.uploadFromBytes(
    fileName: uploadedFile.name,
    fileBytes: fileBytes,
    uploadedBy: uploadedBy,
    fileType: fileType,
    lessonId: lessonId,
  );

  return Response.json(
    statusCode: HttpStatus.created,
    body: {
      'message': 'File uploaded successfully',
      'file': {
        'id': record.id,
        'fileName': record.fileName,
        'filePath': record.filePath,
        'fileType': record.fileType,
        'fileSizeBytes': record.fileSizeBytes,
        'mimeType': record.mimeType,
        'uploadUrl': 'http://localhost:8080/files/${record.id}',
      },
    },
  );
}

Future<Response> _handleJson(
  RequestContext context,
  FileUploadService service,
) async {
  final body = await context.request.json() as Map<String, dynamic>;

  if (!body.containsKey('fileName') || !body.containsKey('uploadedBy')) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'fileName and uploadedBy are required'},
    );
  }

  final record = await service.uploadFromMetadata(
    fileName: body['fileName'] as String,
    uploadedBy: body['uploadedBy'] as int,
    fileType: body['fileType'] as String? ?? 'video',
    lessonId: body['lessonId'] as int?,
    fileSizeBytes: body['fileSizeBytes'] as int? ?? 0,
    mimeType: body['mimeType'] as String?,
  );

  return Response.json(
    statusCode: HttpStatus.created,
    body: {
      'message': 'File uploaded successfully',
      'file': {
        'id': record.id,
        'fileName': record.fileName,
        'filePath': record.filePath,
        'fileType': record.fileType,
        'uploadUrl': record.filePath,
      },
    },
  );
}
