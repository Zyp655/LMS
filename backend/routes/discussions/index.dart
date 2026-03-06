import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:backend/services/discussion_broadcaster.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<AppDatabase>();

  switch (context.request.method) {
    case HttpMethod.get:
      return _getDiscussions(context, db);
    case HttpMethod.post:
      return _createComment(context, db);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getDiscussions(RequestContext context, AppDatabase db) async {
  try {
    final params = context.request.uri.queryParameters;
    final lessonId = int.tryParse(params['lessonId'] ?? '');

    if (lessonId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'lessonId is required'},
      );
    }

    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
    final offset = (page - 1) * limit;

    final query = db.select(db.comments)
      ..where((t) => t.lessonId.equals(lessonId))
      ..where((t) => t.depth.equals(0))
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.desc(t.createdAt),
      ])
      ..limit(limit, offset: offset);

    final rootComments = await query.get();

    final userIds = <int>{};
    final result = <Map<String, dynamic>>[];

    for (final comment in rootComments) {
      userIds.add(comment.userId);

      final pathPrefix = comment.path ?? '${comment.id}';
      final repliesQuery = db.select(db.comments)
        ..where((t) => t.lessonId.equals(lessonId))
        ..where((t) => t.depth.isBiggerThanValue(0))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

      final allReplies = await repliesQuery.get();
      final nested = allReplies
          .where((r) => (r.path ?? '').startsWith('$pathPrefix/'))
          .toList();

      for (final r in nested) {
        userIds.add(r.userId);
      }
    }

    final userMap = await _fetchUserInfoBatch(db, userIds);

    for (final comment in rootComments) {
      final commentMap = _commentToJson(comment, userMap);

      final pathPrefix = comment.path ?? '${comment.id}';
      final repliesQuery = db.select(db.comments)
        ..where((t) => t.lessonId.equals(lessonId))
        ..where((t) => t.depth.isBiggerThanValue(0))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

      final allReplies = await repliesQuery.get();
      final nested = allReplies
          .where((r) => (r.path ?? '').startsWith('$pathPrefix/'))
          .map((r) => _commentToJson(r, userMap))
          .toList();

      commentMap['replies'] = nested;
      commentMap['replyCount'] = nested.length;
      result.add(commentMap);
    }

    final countQuery = db.selectOnly(db.comments)
      ..addColumns([db.comments.id.count()])
      ..where(db.comments.lessonId.equals(lessonId))
      ..where(db.comments.depth.equals(0));
    final countResult = await countQuery.getSingle();
    final total = countResult.read(db.comments.id.count()) ?? 0;

    return Response.json(body: {
      'discussions': result,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': total,
        'totalPages': (total / limit).ceil(),
      },
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}

Future<Response> _createComment(RequestContext context, AppDatabase db) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final broadcaster = context.read<DiscussionBroadcaster>();

    final lessonId = body['lessonId'] as int?;
    final userId = body['userId'] as int?;
    final content = body['content'] as String?;
    final parentId = body['parentId'] as int?;

    if (lessonId == null || userId == null || content == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'lessonId, userId, and content are required'},
      );
    }

    int depth = 0;
    String? path;

    if (parentId != null) {
      final parent = await (db.select(db.comments)
            ..where((t) => t.id.equals(parentId)))
          .getSingleOrNull();

      if (parent != null) {
        depth = (parent.depth) + 1;
        path = '${parent.path ?? parent.id}';
      }
    }

    final id = await db.into(db.comments).insert(
          CommentsCompanion.insert(
            lessonId: lessonId,
            userId: userId,
            content: content,
            parentId: Value(parentId),
            depth: Value(depth),
            path: Value(path),
            createdAt: DateTime.now(),
          ),
        );

    if (path != null) {
      await (db.update(db.comments)..where((t) => t.id.equals(id)))
          .write(CommentsCompanion(path: Value('$path/$id')));
    } else {
      await (db.update(db.comments)..where((t) => t.id.equals(id)))
          .write(CommentsCompanion(path: Value('$id')));
    }

    final userMap = await _fetchUserInfoBatch(db, {userId});
    final userInfo = userMap[userId];

    broadcaster.onNewComment(lessonId, {
      'id': id,
      'lessonId': lessonId,
      'userId': userId,
      'content': content,
      'parentId': parentId,
      'depth': depth,
      'userName': userInfo?['userName'],
      'userAvatar': userInfo?['userAvatar'],
      'createdAt': DateTime.now().toIso8601String(),
    });

    return Response.json(
      statusCode: HttpStatus.created,
      body: {'id': id, 'message': 'Comment created'},
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}

Map<String, dynamic> _commentToJson(
  Comment comment,
  Map<int, Map<String, String?>> userMap,
) {
  final userInfo = userMap[comment.userId];
  return {
    'id': comment.id,
    'lessonId': comment.lessonId,
    'userId': comment.userId,
    'content': comment.content,
    'parentId': comment.parentId,
    'depth': comment.depth,
    'path': comment.path,
    'upvotes': comment.upvotes,
    'downvotes': comment.downvotes,
    'isPinned': comment.isPinned,
    'isAnswered': comment.isAnswered,
    'editedAt': comment.editedAt?.toIso8601String(),
    'createdAt': comment.createdAt.toIso8601String(),
    'userName': userInfo?['userName'],
    'userAvatar': userInfo?['userAvatar'],
  };
}

Future<Map<int, Map<String, String?>>> _fetchUserInfoBatch(
  AppDatabase db,
  Set<int> userIds,
) async {
  if (userIds.isEmpty) return {};

  final result = <int, Map<String, String?>>{};

  final users =
      await (db.select(db.users)..where((u) => u.id.isIn(userIds))).get();

  for (final user in users) {
    result[user.id] = {
      'userName': user.fullName ?? user.email,
      'userAvatar': null,
    };
  }

  final profiles = await (db.select(db.studentProfiles)
        ..where((p) => p.userId.isIn(userIds)))
      .get();

  for (final profile in profiles) {
    if (result.containsKey(profile.userId)) {
      result[profile.userId]!['userAvatar'] = profile.avatarUrl;
    }
  }

  return result;
}
