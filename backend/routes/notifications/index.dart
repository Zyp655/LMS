import 'package:backend/database/database.dart';
import 'package:backend/helpers/pagination.dart';
import 'package:backend/services/redis_service.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  final db = context.read<AppDatabase>();
  final redis = context.read<RedisService>();
  final params = context.request.uri.queryParameters;
  if (!params.containsKey('userId')) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Missing userId parameter'},
    );
  }
  final userId = int.parse(params['userId']!);
  final pg = Pagination.fromQuery(params);
  final unreadOnly = params['unreadOnly'] == 'true';
  try {
    final unreadKey = 'notif:unread:$userId';
    int unreadCount;
    final cachedUnread = await redis.get(unreadKey);
    if (cachedUnread != null) {
      unreadCount = int.tryParse(cachedUnread) ?? 0;
    } else {
      unreadCount = await (db.select(db.notifications)
            ..where((n) => n.userId.equals(userId))
            ..where((n) => n.isRead.equals(false)))
          .get()
          .then((rows) => rows.length);
      await redis.set(unreadKey, '$unreadCount', ttlSeconds: 30);
    }

    var countQ = db.select(db.notifications)
      ..where((n) => n.userId.equals(userId));
    if (unreadOnly) {
      countQ = countQ..where((n) => n.isRead.equals(false));
    }
    final total = (await countQ.get()).length;

    var query = db.select(db.notifications)
      ..where((n) => n.userId.equals(userId));
    if (unreadOnly) {
      query = query..where((n) => n.isRead.equals(false));
    }
    query = query
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
      ..limit(pg.limit, offset: pg.offset);
    final notifications = await query.get();

    final result = notifications.map((n) {
      return {
        'id': n.id,
        'userId': n.userId,
        'type': n.type,
        'title': n.title,
        'message': n.message,
        'isRead': n.isRead,
        'actionUrl': n.actionUrl,
        'relatedId': n.relatedId,
        'relatedType': n.relatedType,
        'createdAt': n.createdAt.toIso8601String(),
      };
    }).toList();

    final body = pg.wrap(result, total: total, key: 'notifications');
    body['unreadCount'] = unreadCount;
    return Response.json(body: body);
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': '\u0110\u00e3 x\u1ea3y ra l\u1ed7i h\u1ec7 th\u1ed1ng. Vui l\u00f2ng th\u1eed l\u1ea1i sau.'},
    );
  }
}
