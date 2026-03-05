import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';
Future<Response> onRequest(RequestContext context) async {
  final request = context.request;
  final method = request.method;
  if (method == HttpMethod.get) {
    return _getComments(context);
  } else if (method == HttpMethod.post) {
    return _createComment(context);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}
Future<Response> _getComments(RequestContext context) async {
  try {
    final db = context.read<AppDatabase>();
    final params = context.request.uri.queryParameters;
    final lessonIdStr = params['lessonId'];
    if (lessonIdStr == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'lessonId is required'},
      );
    }
    final lessonId = int.tryParse(lessonIdStr);
    if (lessonId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Invalid lessonId'},
      );
    }
    final query = db.select(db.comments).join([
      innerJoin(db.users, db.users.id.equalsExp(db.comments.userId)),
    ]);
    query.where(db.comments.lessonId.equals(lessonId));
    query.orderBy([OrderingTerm.desc(db.comments.createdAt)]);
    final results = await query.get();
    final comments = results.map((row) {
      final comment = row.readTable(db.comments);
      final user = row.readTable(db.users);
      return {
        'id': comment.id,
        'lessonId': comment.lessonId,
        'userId': comment.userId,
        'userName': user.fullName ?? user.email,
        'userRole': user.role,
        'content': comment.content,
        'parentId': comment.parentId,
        'createdAt': comment.createdAt.toIso8601String(),
        'isTeacherResponse': comment.isTeacherResponse,
      };
    }).toList();
    return Response.json(body: comments);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
Future<Response> _createComment(RequestContext context) async {
  try {
    final db = context.read<AppDatabase>();
    final body = await context.request.json() as Map<String, dynamic>;
    final lessonId = body['lessonId'] as int?;
    final userId = body['userId'] as int?;
    final content = body['content'] as String?;
    final parentId = body['parentId'] as int?;
    if (lessonId == null || userId == null || content == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'lessonId, userId and content are required'},
      );
    }
    final user = await (db.select(db.users)
          ..where((tbl) => tbl.id.equals(userId)))
        .getSingleOrNull();
    final isTeacher = user?.role == 1;
    final commentId = await db.into(db.comments).insert(
          CommentsCompanion.insert(
            lessonId: lessonId,
            userId: userId,
            content: content,
            parentId: Value(parentId),
            isTeacherResponse: Value(isTeacher),
            createdAt: DateTime.now(),
          ),
        );
    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'id': commentId,
        'message': 'Comment created successfully',
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
