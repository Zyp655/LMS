import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final request = context.request;
  final method = request.method;
  final fileId = int.tryParse(id);
  if (fileId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid file ID'},
    );
  }
  if (method == HttpMethod.get) {
    return _getFile(context, fileId);
  } else if (method == HttpMethod.delete) {
    return _deleteFile(context, fileId);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _getFile(RequestContext context, int fileId) async {
  try {
    final db = context.read<AppDatabase>();
    final fileRecord = await (db.select(db.courseFiles)
          ..where((tbl) => tbl.id.equals(fileId)))
        .getSingleOrNull();
    if (fileRecord == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'File not found'},
      );
    }
    final file = File(fileRecord.filePath);
    if (!await file.exists()) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'File not found on disk'},
      );
    }

    final fileLength = await file.length();
    final mimeType = fileRecord.mimeType;
    final rangeHeader = context.request.headers['range'];

    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final rangeSpec = rangeHeader.substring(6);
      final parts = rangeSpec.split('-');
      final start = parts[0].isNotEmpty ? int.parse(parts[0]) : 0;
      final end = parts.length > 1 && parts[1].isNotEmpty
          ? int.parse(parts[1])
          : fileLength - 1;

      if (start >= fileLength || end >= fileLength || start > end) {
        return Response(
          statusCode: HttpStatus.requestedRangeNotSatisfiable,
          headers: {
            'Content-Range': 'bytes */$fileLength',
          },
        );
      }

      final chunkLength = end - start + 1;
      final raf = await file.open(mode: FileMode.read);
      await raf.setPosition(start);
      final bytes = await raf.read(chunkLength);
      await raf.close();

      return Response.bytes(
        statusCode: HttpStatus.partialContent,
        body: bytes,
        headers: {
          'Content-Type': mimeType,
          'Content-Range': 'bytes $start-$end/$fileLength',
          'Accept-Ranges': 'bytes',
          'Content-Length': '$chunkLength',
          'Content-Disposition': 'inline; filename="${fileRecord.fileName}"',
        },
      );
    }

    final fileBytes = await file.readAsBytes();
    return Response.bytes(
      body: fileBytes,
      headers: {
        'Content-Type': mimeType,
        'Accept-Ranges': 'bytes',
        'Content-Length': '$fileLength',
        'Content-Disposition': 'inline; filename="${fileRecord.fileName}"',
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}

Future<Response> _deleteFile(RequestContext context, int fileId) async {
  try {
    final db = context.read<AppDatabase>();
    final fileRecord = await (db.select(db.courseFiles)
          ..where((tbl) => tbl.id.equals(fileId)))
        .getSingleOrNull();
    if (fileRecord == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'File not found'},
      );
    }
    final file = File(fileRecord.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    await (db.delete(db.courseFiles)..where((tbl) => tbl.id.equals(fileId)))
        .go();
    return Response.json(body: {'message': 'File deleted successfully'});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
