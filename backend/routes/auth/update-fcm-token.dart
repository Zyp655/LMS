import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:backend/services/fcm_push_service.dart';
import 'package:backend/helpers/log.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  try {
    final db = context.read<AppDatabase>();
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final userId = data['userId'] as int?;
    final fcmToken = data['fcmToken'] as String?;

    if (userId == null || fcmToken == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'userId and fcmToken are required'},
      );
    }

    await (db.update(db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(fcmToken: Value(fcmToken)),
    );

    _pushUnreadNotifications(db, userId, fcmToken);

    return Response.json(body: {'message': 'FCM token updated'});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': 'Failed to update FCM token: $e'},
    );
  }
}

Future<void> _pushUnreadNotifications(
  AppDatabase db,
  int userId,
  String fcmToken,
) async {
  try {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final unread = await (db.select(db.notifications)
          ..where((n) => n.userId.equals(userId))
          ..where((n) => n.isRead.equals(false))
          ..where((n) => n.fcmPushed.equals(false))
          ..where((n) => n.createdAt.isBiggerThanValue(cutoff))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
          ..limit(10))
        .get();

    if (unread.isEmpty) return;

    Log.info('FCM', 'Pushing ${unread.length} unread notifications to userId=$userId');

    for (final n in unread) {
      await FcmPushService.sendToToken(
        token: fcmToken,
        title: n.title,
        body: n.message,
        data: {
          'type': n.type,
          if (n.relatedId != null) 'relatedId': n.relatedId.toString(),
          if (n.relatedType != null) 'relatedType': n.relatedType!,
        },
      );

      await (db.update(db.notifications)
            ..where((x) => x.id.equals(n.id)))
          .write(const NotificationsCompanion(fcmPushed: Value(true)));
    }
  } catch (e) {
    Log.error('FCM', 'pushUnread failed for userId=$userId', e);
  }
}

