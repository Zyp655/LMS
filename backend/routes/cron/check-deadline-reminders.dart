import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:backend/database/database.dart';
import 'package:backend/helpers/notification_helper.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post &&
      context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final db = context.read<AppDatabase>();
  final now = DateTime.now();
  final log = <String>[];

  try {
    final sixHoursLater = now.add(const Duration(hours: 6, minutes: 5));
    final sixHoursEarlier = now.add(const Duration(hours: 5, minutes: 55));

    final thirtyMinLater = now.add(const Duration(minutes: 35));
    final thirtyMinEarlier = now.add(const Duration(minutes: 25));

    final allAssignments = await db.select(db.assignments).get();

    int reminder6h = 0;
    int reminder30m = 0;

    for (final assignment in allAssignments) {
      final due = assignment.dueDate;

      final is6h = due.isAfter(sixHoursEarlier) &&
          due.isBefore(sixHoursLater);

      final is30m = due.isAfter(thirtyMinEarlier) &&
          due.isBefore(thirtyMinLater);

      if (!is6h && !is30m) continue;

      final studentAssignments = await (db.select(db.studentAssignments)
            ..where((s) => s.assignmentId.equals(assignment.id))
            ..where((s) => s.isCompleted.equals(false)))
          .get();

      final pendingStudentIds =
          studentAssignments.map((s) => s.studentId).toSet().toList();

      if (pendingStudentIds.isEmpty) continue;

      if (is6h) {
        final alreadySent = await _alreadySent(
          db, assignment.id, 'deadline_6h', now,
        );
        if (!alreadySent) {
          final hours = due.difference(now).inHours;
          await NotificationHelper.createBatchNotifications(
            db: db,
            userIds: pendingStudentIds,
            type: 'deadline_6h',
            title: '⏰ Sắp hết hạn bài tập',
            message:
                'Bài tập "${assignment.title}" sẽ hết hạn sau $hours giờ nữa. Hãy hoàn thành ngay!',
            relatedId: assignment.id,
            relatedType: 'assignment',
          );
          await _markSent(db, assignment.id, 'deadline_6h', now);
          reminder6h += pendingStudentIds.length;
          log.add(
            '6h: "${assignment.title}" → ${pendingStudentIds.length} SV',
          );
        }
      }

      if (is30m) {
        final alreadySent = await _alreadySent(
          db, assignment.id, 'deadline_30m', now,
        );
        if (!alreadySent) {
          final minutes = due.difference(now).inMinutes;
          await NotificationHelper.createBatchNotifications(
            db: db,
            userIds: pendingStudentIds,
            type: 'deadline_30m',
            title: '🚨 Bài tập sắp hết hạn!',
            message:
                'Bài tập "${assignment.title}" sẽ hết hạn sau $minutes phút nữa! Nộp bài ngay!',
            relatedId: assignment.id,
            relatedType: 'assignment',
          );
          await _markSent(db, assignment.id, 'deadline_30m', now);
          reminder30m += pendingStudentIds.length;
          log.add(
            '30m: "${assignment.title}" → ${pendingStudentIds.length} SV',
          );
        }
      }
    }

    return Response.json(body: {
      'success': true,
      'reminder6h': reminder6h,
      'reminder30m': reminder30m,
      'checkedAt': now.toIso8601String(),
      'log': log,
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': '$e'},
    );
  }
}

Future<bool> _alreadySent(
  AppDatabase db,
  int assignmentId,
  String type,
  DateTime now,
) async {
  final dayStart = DateTime(now.year, now.month, now.day);
  final existing = await (db.select(db.notifications)
        ..where((n) => n.relatedId.equals(assignmentId))
        ..where((n) => n.type.equals(type))
        ..where((n) => n.createdAt.isBiggerOrEqualValue(dayStart))
        ..limit(1))
      .getSingleOrNull();
  return existing != null;
}

Future<void> _markSent(
  AppDatabase db,
  int assignmentId,
  String type,
  DateTime now,
) async {
  await db.into(db.notifications).insert(
        NotificationsCompanion.insert(
          userId: 0,
          type: '${type}_marker',
          title: 'marker',
          message: 'assignment_$assignmentId',
          createdAt: now,
          relatedId: Value(assignmentId),
          relatedType: const Value('deadline_marker'),
        ),
      );
}
