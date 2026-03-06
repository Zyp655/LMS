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
    final userId = body['userId'] as int?;
    final voteType = body['voteType'] as String?;

    if (commentId == null || userId == null || voteType == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'commentId, userId, and voteType are required'},
      );
    }

    if (voteType != 'up' && voteType != 'down') {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'voteType must be "up" or "down"'},
      );
    }

    final existingVote = await (db.select(db.commentVotes)
          ..where((t) => t.commentId.equals(commentId))
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();

    if (existingVote != null) {
      if (existingVote.voteType == voteType) {
        await (db.delete(db.commentVotes)
              ..where((t) => t.id.equals(existingVote.id)))
            .go();

        if (voteType == 'up') {
          await _adjustVotes(db, commentId, upDelta: -1);
        } else {
          await _adjustVotes(db, commentId, downDelta: -1);
        }

        final updated = await (db.select(db.comments)
              ..where((t) => t.id.equals(commentId)))
            .getSingle();
        context.read<DiscussionBroadcaster>().onVoteUpdate(
              updated.lessonId,
              commentId,
              updated.upvotes,
              updated.downvotes,
            );

        return Response.json(body: {'action': 'removed', 'voteType': voteType});
      } else {
        await (db.update(db.commentVotes)
              ..where((t) => t.id.equals(existingVote.id)))
            .write(CommentVotesCompanion(
          voteType: Value(voteType),
          createdAt: Value(DateTime.now()),
        ));

        if (voteType == 'up') {
          await _adjustVotes(db, commentId, upDelta: 1, downDelta: -1);
        } else {
          await _adjustVotes(db, commentId, upDelta: -1, downDelta: 1);
        }

        final switched = await (db.select(db.comments)
              ..where((t) => t.id.equals(commentId)))
            .getSingle();
        context.read<DiscussionBroadcaster>().onVoteUpdate(
              switched.lessonId,
              commentId,
              switched.upvotes,
              switched.downvotes,
            );

        return Response.json(
            body: {'action': 'switched', 'voteType': voteType});
      }
    } else {
      await db.into(db.commentVotes).insert(
            CommentVotesCompanion.insert(
              commentId: commentId,
              userId: userId,
              voteType: voteType,
              createdAt: DateTime.now(),
            ),
          );

      if (voteType == 'up') {
        await _adjustVotes(db, commentId, upDelta: 1);
      } else {
        await _adjustVotes(db, commentId, downDelta: 1);
      }

      final voted = await (db.select(db.comments)
            ..where((t) => t.id.equals(commentId)))
          .getSingle();
      context.read<DiscussionBroadcaster>().onVoteUpdate(
            voted.lessonId,
            commentId,
            voted.upvotes,
            voted.downvotes,
          );

      return Response.json(
        statusCode: HttpStatus.created,
        body: {'action': 'voted', 'voteType': voteType},
      );
    }
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}

Future<void> _adjustVotes(
  AppDatabase db,
  int commentId, {
  int upDelta = 0,
  int downDelta = 0,
}) async {
  final comment = await (db.select(db.comments)
        ..where((t) => t.id.equals(commentId)))
      .getSingle();

  await (db.update(db.comments)..where((t) => t.id.equals(commentId)))
      .write(CommentsCompanion(
    upvotes: Value(comment.upvotes + upDelta),
    downvotes: Value(comment.downvotes + downDelta),
  ));
}
