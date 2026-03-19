import 'package:backend/database/database.dart';
import 'package:backend/helpers/log.dart';
import 'package:backend/services/fcm_push_service.dart';
import 'package:drift/drift.dart';

class NotificationHelper {
  static Future<void> createNotification({
    required AppDatabase db,
    required int userId,
    required String type,
    required String title,
    required String message,
    String? actionUrl,
    int? relatedId,
    String? relatedType,
  }) async {
    final notifId = await db.into(db.notifications).insert(
          NotificationsCompanion.insert(
            userId: userId,
            type: type,
            title: title,
            message: message,
            actionUrl: Value(actionUrl),
            relatedId: Value(relatedId),
            relatedType: Value(relatedType),
            createdAt: DateTime.now(),
          ),
        );

    await _sendFcmPush(
      db: db,
      notificationId: notifId,
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedId: relatedId,
    );
  }

  static Future<void> createBatchNotifications({
    required AppDatabase db,
    required List<int> userIds,
    required String type,
    required String title,
    required String message,
    String? actionUrl,
    int? relatedId,
    String? relatedType,
  }) async {
    final now = DateTime.now();
    final notifIds = <int, int>{};

    for (final userId in userIds) {
      final id = await db.into(db.notifications).insert(
            NotificationsCompanion.insert(
              userId: userId,
              type: type,
              title: title,
              message: message,
              actionUrl: Value(actionUrl),
              relatedId: Value(relatedId),
              relatedType: Value(relatedType),
              createdAt: now,
            ),
          );
      notifIds[userId] = id;
    }

    for (final userId in userIds) {
      await _sendFcmPush(
        db: db,
        notificationId: notifIds[userId]!,
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
      );
    }
  }

  static Future<void> notifyClassStudents({
    required AppDatabase db,
    required int classId,
    required String type,
    required String title,
    required String message,
    String? actionUrl,
    int? relatedId,
    String? relatedType,
  }) async {
    final students = await (db.select(db.schedules)
          ..where((s) => s.classId.equals(classId)))
        .get();

    final userIds = students.map((s) => s.userId).toSet().toList();

    if (userIds.isNotEmpty) {
      await createBatchNotifications(
        db: db,
        userIds: userIds,
        type: type,
        title: title,
        message: message,
        actionUrl: actionUrl,
        relatedId: relatedId,
        relatedType: relatedType,
      );
    }
  }

  static Future<void> _sendFcmPush({
    required AppDatabase db,
    required int notificationId,
    required int userId,
    required String title,
    required String message,
    required String type,
    int? relatedId,
  }) async {
    try {
      final user = await (db.select(db.users)
            ..where((u) => u.id.equals(userId)))
          .getSingleOrNull();

      if (user == null) {
        Log.warning('FCM', 'No user found for userId=$userId');
        return;
      }
      if (user.fcmToken == null || user.fcmToken!.isEmpty) {
        Log.warning('FCM', 'No fcmToken for userId=$userId (${user.fullName})');
        return;
      }

      Log.info('FCM', 'Sending push to userId=$userId type=$type');
      await FcmPushService.sendToToken(
        token: user.fcmToken!,
        title: title,
        body: message,
        data: {
          'type': type,
          if (relatedId != null) 'relatedId': relatedId.toString(),
        },
      );

      await (db.update(db.notifications)
            ..where((n) => n.id.equals(notificationId)))
          .write(const NotificationsCompanion(fcmPushed: Value(true)));
    } catch (e) {
      Log.error('FCM', 'Push to userId=$userId failed', e);
    }
  }
}

