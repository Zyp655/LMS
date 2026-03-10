import 'dart:async';
import 'package:backend/database/database.dart';
import 'package:backend/services/attendance_engine.dart';
import 'package:backend/services/notification_engine.dart';

class CronService {
  final AppDatabase db;
  late final AttendanceEngine _attendanceEngine;
  late final NotificationEngine _notificationEngine;
  Timer? _timer;
  int _lastHourRun = -1;

  CronService(this.db) {
    _attendanceEngine = AttendanceEngine(db);
    _notificationEngine = NotificationEngine(db);
  }

  void start() {
    print('[Cron] Service started. Checking every 60 seconds.');
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _tick());
    _tick();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    print('[Cron] Service stopped.');
  }

  Future<void> _tick() async {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    if (hour == _lastHourRun) return;

    if (hour == 7 && minute < 5) {
      _lastHourRun = hour;
      await _runJob(
          'morning_digest', () => _notificationEngine.sendMorningDigest(now));
    } else if (hour == 12 && minute < 5) {
      _lastHourRun = hour;
      await _runJob(
          'midday_reminder', () => _notificationEngine.sendMiddayReminder(now));
    } else if (hour == 16 && minute < 5) {
      _lastHourRun = hour;
      await _runJob('afternoon_reminder',
          () => _notificationEngine.sendAfternoonReminder(now));
    } else if (hour == 20 && minute < 5) {
      _lastHourRun = hour;
      await _runJob(
          'urgent_reminder', () => _notificationEngine.sendUrgentReminder(now));
    } else if (hour == 0 && minute >= 5 && minute < 10) {
      _lastHourRun = hour;
      final yesterday = now.subtract(const Duration(days: 1));
      await _runJob('finalize_attendance',
          () => _attendanceEngine.finalizeDay(yesterday));
    }
  }

  Future<void> _runJob(String name, Future<void> Function() job) async {
    print('[Cron] Running job: $name at ${DateTime.now()}');
    try {
      await job();
      print('[Cron] Job $name completed successfully.');
    } catch (e, st) {
      print('[Cron] Job $name failed: $e\n$st');
    }
  }

  Future<void> triggerJob(String jobName) async {
    final now = DateTime.now();
    switch (jobName) {
      case 'morning_digest':
        await _notificationEngine.sendMorningDigest(now);
      case 'midday_reminder':
        await _notificationEngine.sendMiddayReminder(now);
      case 'afternoon_reminder':
        await _notificationEngine.sendAfternoonReminder(now);
      case 'urgent_reminder':
        await _notificationEngine.sendUrgentReminder(now);
      case 'finalize_attendance':
        await _attendanceEngine.finalizeDay(now);
      default:
        throw ArgumentError('Unknown job: $jobName');
    }
  }
}
