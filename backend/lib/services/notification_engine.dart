import 'package:backend/database/database.dart';
import 'package:backend/helpers/notification_helper.dart';
import 'package:backend/services/fcm_push_service.dart';
import 'package:drift/drift.dart';

class NotificationEngine {
  final AppDatabase db;

  NotificationEngine(this.db);

  Future<void> sendMorningDigest(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final schedules = await (db.select(db.schedules)
          ..where((s) => s.startTime.isBiggerOrEqualValue(dayStart))
          ..where((s) => s.startTime.isSmallerThanValue(dayEnd))
          ..where((s) => s.type.equals('classSession')))
        .get();

    final grouped = <int, List<Schedule>>{};
    for (final s in schedules) {
      grouped.putIfAbsent(s.userId, () => []).add(s);
    }

    for (final entry in grouped.entries) {
      final studentId = entry.key;
      final studentSchedules = entry.value;

      if (await _alreadySent(studentId, null, dayStart, 'morning_summary')) {
        continue;
      }

      final subjects = studentSchedules.map((s) => s.subjectName).join(', ');
      final count = studentSchedules.length;
      final title = '📚 Lịch học hôm nay — $count môn';
      final message = 'Hôm nay bạn có: $subjects. '
          'Hãy hoàn thành bài học trước 00:00 để được tính chuyên cần. '
          'Chúc bạn học tập hiệu quả!';

      await _sendAndLog(
        studentId: studentId,
        scheduleId: null,
        date: dayStart,
        type: 'morning_summary',
        title: title,
        message: message,
      );
    }
  }

  Future<void> sendMiddayReminder(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final pendingLogs = await _getPendingStudents(dayStart, dayEnd);

    for (final studentId in pendingLogs.keys) {
      final scheduleNames = pendingLogs[studentId]!;
      if (await _alreadySent(studentId, null, dayStart, 'reminder_12'))
        continue;

      final title = '⏰ Nhắc nhở học tập';
      final message = 'Bạn chưa truy cập bài học: ${scheduleNames.join(", ")}. '
          'Còn 12 tiếng để hoàn thành. Đừng để bị tính vắng!';

      await _sendAndLog(
        studentId: studentId,
        scheduleId: null,
        date: dayStart,
        type: 'reminder_12',
        title: title,
        message: message,
      );
    }
  }

  Future<void> sendAfternoonReminder(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final logs = await (db.select(db.dailyLearningLogs)
          ..where((l) => l.status.equals('pending'))
          ..where((l) => l.date.isBiggerOrEqualValue(dayStart))
          ..where((l) => l.date.isSmallerThanValue(dayEnd)))
        .get();

    for (final log in logs) {
      if (await _alreadySent(
          log.studentId, log.scheduleId, dayStart, 'reminder_16')) {
        continue;
      }

      final schedule = await (db.select(db.schedules)
            ..where((s) => s.id.equals(log.scheduleId)))
          .getSingleOrNull();
      if (schedule == null) continue;

      final parts = <String>[];
      if (log.watchPercentage < 90) {
        parts.add('Video: ${log.watchPercentage.toStringAsFixed(0)}%/90%');
      }
      if (!log.quizCompleted) {
        parts.add('Quiz: chưa hoàn thành');
      }

      final title = '📋 Tiến độ ${schedule.subjectName}';
      final message = 'Còn 8 tiếng nữa. ${parts.join(". ")}. '
          'Hoàn thành ngay để không bị trừ 4 tiết chuyên cần.';

      await _sendAndLog(
        studentId: log.studentId,
        scheduleId: log.scheduleId,
        date: dayStart,
        type: 'reminder_16',
        title: title,
        message: message,
      );
    }

    final noAccessStudents = await _getPendingStudents(dayStart, dayEnd);
    for (final studentId in noAccessStudents.keys) {
      if (await _alreadySent(studentId, null, dayStart, 'reminder_16'))
        continue;

      final title = '📋 Cảnh báo chuyên cần';
      final message =
          'Bạn chưa truy cập: ${noAccessStudents[studentId]!.join(", ")}. '
          'Còn 8 tiếng. Hãy bắt đầu ngay!';

      await _sendAndLog(
        studentId: studentId,
        scheduleId: null,
        date: dayStart,
        type: 'reminder_16',
        title: title,
        message: message,
      );
    }
  }

  Future<void> sendUrgentReminder(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final logs = await (db.select(db.dailyLearningLogs)
          ..where((l) => l.status.equals('pending'))
          ..where((l) => l.date.isBiggerOrEqualValue(dayStart))
          ..where((l) => l.date.isSmallerThanValue(dayEnd)))
        .get();

    for (final log in logs) {
      if (await _alreadySent(
          log.studentId, log.scheduleId, dayStart, 'urgent_20')) {
        continue;
      }

      final schedule = await (db.select(db.schedules)
            ..where((s) => s.id.equals(log.scheduleId)))
          .getSingleOrNull();
      if (schedule == null) continue;

      final title = '🚨 KHẨN CẤP — ${schedule.subjectName}';
      final message =
          'Chỉ còn 4 giờ nữa hệ thống sẽ đóng điểm danh môn ${schedule.subjectName}. '
          'Hãy hoàn thành bài học ngay để không bị vắng 4 tiết!';

      await _sendAndLog(
        studentId: log.studentId,
        scheduleId: log.scheduleId,
        date: dayStart,
        type: 'urgent_20',
        title: title,
        message: message,
      );
    }

    final noAccessStudents = await _getPendingStudents(dayStart, dayEnd);
    for (final studentId in noAccessStudents.keys) {
      if (await _alreadySent(studentId, null, dayStart, 'urgent_20')) continue;

      final names = noAccessStudents[studentId]!;
      final title = '🚨 KHẨN CẤP — ${names.length} môn chưa học';
      final message = 'Chỉ còn 4 giờ! Bạn chưa truy cập: ${names.join(", ")}. '
          'Nếu không hoàn thành, bạn sẽ bị tính vắng ${names.length * 4} tiết.';

      await _sendAndLog(
        studentId: studentId,
        scheduleId: null,
        date: dayStart,
        type: 'urgent_20',
        title: title,
        message: message,
      );
    }
  }

  Future<Map<int, List<String>>> _getPendingStudents(
    DateTime dayStart,
    DateTime dayEnd,
  ) async {
    final schedules = await (db.select(db.schedules)
          ..where((s) => s.startTime.isBiggerOrEqualValue(dayStart))
          ..where((s) => s.startTime.isSmallerThanValue(dayEnd))
          ..where((s) => s.type.equals('classSession')))
        .get();

    final result = <int, List<String>>{};
    for (final schedule in schedules) {
      final hasLog = await (db.select(db.dailyLearningLogs)
            ..where((l) => l.studentId.equals(schedule.userId))
            ..where((l) => l.scheduleId.equals(schedule.id))
            ..where((l) => l.date.isBiggerOrEqualValue(dayStart))
            ..where((l) => l.date.isSmallerThanValue(dayEnd)))
          .getSingleOrNull();

      if (hasLog == null) {
        result.putIfAbsent(schedule.userId, () => []).add(schedule.subjectName);
      }
    }
    return result;
  }

  Future<bool> _alreadySent(
    int studentId,
    int? scheduleId,
    DateTime date,
    String type,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    var query = db.select(db.aiNotificationLogs)
      ..where((n) => n.studentId.equals(studentId))
      ..where((n) => n.notificationType.equals(type))
      ..where((n) => n.date.isBiggerOrEqualValue(dayStart))
      ..where((n) => n.date.isSmallerThanValue(dayEnd));

    if (scheduleId != null) {
      query = query..where((n) => n.scheduleId.equals(scheduleId));
    }

    return await query.getSingleOrNull() != null;
  }

  Future<void> _sendAndLog({
    required int studentId,
    required int? scheduleId,
    required DateTime date,
    required String type,
    required String title,
    required String message,
  }) async {
    await NotificationHelper.createNotification(
      db: db,
      userId: studentId,
      type: 'ai_attendance',
      title: title,
      message: message,
    );

    await db.into(db.aiNotificationLogs).insert(
          AiNotificationLogsCompanion.insert(
            studentId: studentId,
            scheduleId: Value(scheduleId),
            date: date,
            notificationType: type,
            sentAt: DateTime.now(),
            message: message,
          ),
        );

    final user = await (db.select(db.users)
          ..where((u) => u.id.equals(studentId)))
        .getSingleOrNull();
    if (user?.fcmToken != null && user!.fcmToken!.isNotEmpty) {
      try {
        await FcmPushService.sendToToken(
          token: user.fcmToken!,
          title: title,
          body: message,
          data: {
            'type': 'ai_attendance',
            'notificationType': type,
          },
        );
      } catch (_) {}
    }
  }
}
