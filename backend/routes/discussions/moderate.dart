import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:backend/services/discussion_broadcaster.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final db = context.read<AppDatabase>();
    final body = await context.request.json() as Map<String, dynamic>;

    final commentId = body['commentId'] as int?;
    final action = body['action'] as String?;

    if (commentId == null || action == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'commentId and action are required'},
      );
    }

    final broadcaster = context.read<DiscussionBroadcaster>();

    switch (action) {
      case 'pin':
        await (db.update(db.comments)..where((t) => t.id.equals(commentId)))
            .write(const CommentsCompanion(isPinned: Value(true)));
        final pinned = await (db.select(db.comments)
              ..where((t) => t.id.equals(commentId)))
            .getSingle();
        broadcaster.onModeration(pinned.lessonId, commentId, action);
        return Response.json(body: {'message': 'Comment pinned'});

      case 'unpin':
        await (db.update(db.comments)..where((t) => t.id.equals(commentId)))
            .write(const CommentsCompanion(isPinned: Value(false)));
        final unpinned = await (db.select(db.comments)
              ..where((t) => t.id.equals(commentId)))
            .getSingle();
        broadcaster.onModeration(unpinned.lessonId, commentId, action);
        return Response.json(body: {'message': 'Comment unpinned'});

      case 'answer':
        await (db.update(db.comments)..where((t) => t.id.equals(commentId)))
            .write(const CommentsCompanion(isAnswered: Value(true)));
        final answered = await (db.select(db.comments)
              ..where((t) => t.id.equals(commentId)))
            .getSingle();
        broadcaster.onModeration(answered.lessonId, commentId, action);
        return Response.json(body: {'message': 'Marked as answer'});

      case 'unanswer':
        await (db.update(db.comments)..where((t) => t.id.equals(commentId)))
            .write(const CommentsCompanion(isAnswered: Value(false)));
        final unanswered = await (db.select(db.comments)
              ..where((t) => t.id.equals(commentId)))
            .getSingle();
        broadcaster.onModeration(unanswered.lessonId, commentId, action);
        return Response.json(body: {'message': 'Unmarked as answer'});

      default:
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'error': 'Invalid action: $action'},
        );
    }
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
