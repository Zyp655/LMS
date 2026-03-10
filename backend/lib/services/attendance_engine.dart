import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

class AttendanceEngine {
  final AppDatabase db;

  AttendanceEngine(this.db);

  Future<void> finalizeDay(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final pendingLogs = await (db.select(db.dailyLearningLogs)
          ..where((l) => l.status.equals('pending'))
          ..where((l) => l.date.isBiggerOrEqualValue(dayStart))
          ..where((l) => l.date.isSmallerThanValue(dayEnd)))
        .get();

    for (final log in pendingLogs) {
      bool allSegmentsDone = true;
      String segmentDetail = '';

      final unpassedAttempts = await db.customSelect(
        '''SELECT vs.start_timestamp, vs.end_timestamp
           FROM segment_quiz_attempts sqa
           JOIN video_segments vs ON vs.id = sqa.segment_id
           WHERE sqa.student_id = \$1 AND sqa.passed = false
           LIMIT 1''',
        variables: [Variable.withInt(log.studentId)],
      ).get();

      final noAttemptSegments = await db.customSelect(
        '''SELECT vs.start_timestamp, vs.end_timestamp
           FROM video_segments vs
           WHERE NOT EXISTS (
             SELECT 1 FROM segment_quiz_attempts sqa
             WHERE sqa.segment_id = vs.id AND sqa.student_id = \$1
           )
           LIMIT 1''',
        variables: [Variable.withInt(log.studentId)],
      ).get();

      if (unpassedAttempts.isNotEmpty || noAttemptSegments.isNotEmpty) {
        allSegmentsDone = false;
        final row = unpassedAttempts.isNotEmpty
            ? unpassedAttempts.first
            : noAttemptSegments.first;
        final startTs = row.read<double>('start_timestamp');
        final endTs = row.read<double>('end_timestamp');
        final startMin = (startTs / 60).floor();
        final startSec = (startTs % 60).floor();
        final endMin = (endTs / 60).floor();
        final endSec = (endTs % 60).floor();
        segmentDetail =
            ' tại phân đoạn phút thứ ${startMin.toString().padLeft(2, '0')}:${startSec.toString().padLeft(2, '0')} - ${endMin.toString().padLeft(2, '0')}:${endSec.toString().padLeft(2, '0')}';
      }

      final isPresent =
          log.watchPercentage >= 80.0 && log.quizCompleted && allSegmentsDone;
      final status = isPresent ? 'present' : 'absent';
      String? reason;

      if (!isPresent) {
        reason = _buildAbsenceReason(
          log.watchPercentage,
          log.quizCompleted,
          allSegmentsDone,
          segmentDetail,
        );
      }

      await (db.update(db.dailyLearningLogs)..where((l) => l.id.equals(log.id)))
          .write(DailyLearningLogsCompanion(
        status: Value(status),
        absenceReason: Value(reason),
        finalizedAt: Value(DateTime.now()),
      ));

      if (!isPresent) {
        await _incrementAbsences(log.scheduleId, 4);

        await _createAttendanceRecord(
          scheduleId: log.scheduleId,
          studentId: log.studentId,
          date: dayStart,
          status: 'absent',
          note: reason,
        );
      } else {
        await _createAttendanceRecord(
          scheduleId: log.scheduleId,
          studentId: log.studentId,
          date: dayStart,
          status: 'present',
          note:
              'Hoàn thành ${log.watchPercentage.toStringAsFixed(0)}% video + quiz + tất cả phân đoạn',
        );
      }
    }

    await _autoCreateAbsentForNoAccess(dayStart, dayEnd);
  }

  Future<void> _autoCreateAbsentForNoAccess(
    DateTime dayStart,
    DateTime dayEnd,
  ) async {
    final schedulesOfDay = await (db.select(db.schedules)
          ..where((s) => s.startTime.isBiggerOrEqualValue(dayStart))
          ..where((s) => s.startTime.isSmallerThanValue(dayEnd))
          ..where((s) => s.type.equals('classSession')))
        .get();

    for (final schedule in schedulesOfDay) {
      final existingLog = await (db.select(db.dailyLearningLogs)
            ..where((l) => l.scheduleId.equals(schedule.id))
            ..where((l) => l.studentId.equals(schedule.userId))
            ..where((l) => l.date.isBiggerOrEqualValue(dayStart))
            ..where((l) => l.date.isSmallerThanValue(dayEnd)))
          .getSingleOrNull();

      if (existingLog == null) {
        await db.into(db.dailyLearningLogs).insert(
              DailyLearningLogsCompanion.insert(
                studentId: schedule.userId,
                scheduleId: schedule.id,
                date: dayStart,
                status: const Value('absent'),
                absenceReason:
                    const Value('Không truy cập hệ thống trong ngày'),
                finalizedAt: Value(DateTime.now()),
              ),
            );

        await _incrementAbsences(schedule.id, 4);

        await _createAttendanceRecord(
          scheduleId: schedule.id,
          studentId: schedule.userId,
          date: dayStart,
          status: 'absent',
          note: 'Vắng mặt — Không truy cập hệ thống trong ngày',
        );
      }
    }
  }

  Future<void> _incrementAbsences(int scheduleId, int count) async {
    await db.customStatement(
      'UPDATE schedules SET current_absences = current_absences + \$1 WHERE id = \$2',
      [count, scheduleId],
    );
  }

  Future<void> _createAttendanceRecord({
    required int scheduleId,
    required int studentId,
    required DateTime date,
    required String status,
    String? note,
  }) async {
    final schedule = await (db.select(db.schedules)
          ..where((s) => s.id.equals(scheduleId)))
        .getSingleOrNull();
    if (schedule == null) return;

    final classId = schedule.classId;
    if (classId == null) return;

    final existing = await (db.select(db.attendances)
          ..where((a) => a.scheduleId.equals(scheduleId))
          ..where((a) => a.studentId.equals(studentId)))
        .getSingleOrNull();

    if (existing != null) return;

    await db.into(db.attendances).insert(
          AttendancesCompanion.insert(
            classId: classId,
            scheduleId: Value(scheduleId),
            studentId: studentId,
            date: date,
            status: status,
            note: Value(note),
            markedBy: studentId,
            markedAt: DateTime.now(),
          ),
        );
  }

  Future<DailyLearningLog> getOrCreateLog({
    required int studentId,
    required int scheduleId,
    required DateTime date,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final existing = await (db.select(db.dailyLearningLogs)
          ..where((l) => l.studentId.equals(studentId))
          ..where((l) => l.scheduleId.equals(scheduleId))
          ..where((l) => l.date.isBiggerOrEqualValue(dayStart))
          ..where((l) => l.date.isSmallerThanValue(dayEnd)))
        .getSingleOrNull();

    if (existing != null) return existing;

    final schedule = await (db.select(db.schedules)
          ..where((s) => s.id.equals(scheduleId)))
        .getSingle();

    final durationSeconds =
        schedule.endTime.difference(schedule.startTime).inSeconds;
    final requiredSeconds = (durationSeconds * 0.8).round();

    final id = await db.into(db.dailyLearningLogs).insert(
          DailyLearningLogsCompanion.insert(
            studentId: studentId,
            scheduleId: scheduleId,
            date: dayStart,
            requiredWatchSeconds: Value(requiredSeconds),
            firstAccessAt: Value(DateTime.now()),
            lastAccessAt: Value(DateTime.now()),
          ),
        );

    return (db.select(db.dailyLearningLogs)..where((l) => l.id.equals(id)))
        .getSingle();
  }

  Future<void> updateWatchTime({
    required int logId,
    required int additionalSeconds,
  }) async {
    final log = await (db.select(db.dailyLearningLogs)
          ..where((l) => l.id.equals(logId)))
        .getSingle();

    if (log.status != 'pending') return;

    final newTotal = log.totalWatchSeconds + additionalSeconds;
    final req = log.requiredWatchSeconds > 0 ? log.requiredWatchSeconds : 1;
    final percentage = (newTotal / req * 100).clamp(0.0, 100.0);

    await (db.update(db.dailyLearningLogs)..where((l) => l.id.equals(logId)))
        .write(DailyLearningLogsCompanion(
      totalWatchSeconds: Value(newTotal),
      watchPercentage: Value(percentage),
      lastAccessAt: Value(DateTime.now()),
    ));

    if (percentage >= 80.0 && log.quizCompleted) {
      await (db.update(db.dailyLearningLogs)..where((l) => l.id.equals(logId)))
          .write(const DailyLearningLogsCompanion(
        status: Value('present'),
      ));
    }
  }

  Future<void> markQuizCompleted({
    required int logId,
    double? score,
  }) async {
    final log = await (db.select(db.dailyLearningLogs)
          ..where((l) => l.id.equals(logId)))
        .getSingle();

    if (log.status != 'pending') return;

    await (db.update(db.dailyLearningLogs)..where((l) => l.id.equals(logId)))
        .write(DailyLearningLogsCompanion(
      quizCompleted: const Value(true),
      quizScore: Value(score),
      lastAccessAt: Value(DateTime.now()),
    ));

    if (log.watchPercentage >= 80.0) {
      await (db.update(db.dailyLearningLogs)..where((l) => l.id.equals(logId)))
          .write(const DailyLearningLogsCompanion(
        status: Value('present'),
      ));
    }
  }

  String _buildAbsenceReason(
    double watchPct,
    bool quizDone,
    bool segmentsDone,
    String segmentDetail,
  ) {
    final parts = <String>[];
    if (watchPct < 80.0) {
      parts.add(
          'Chưa hoàn thành ${80 - watchPct.toInt()}% thời lượng video còn thiếu (đạt ${watchPct.toStringAsFixed(0)}%)');
    }
    if (!quizDone) {
      parts.add('Chưa hoàn thành bài kiểm tra nhanh');
    }
    if (!segmentsDone) {
      parts.add('Chưa hoàn thành câu hỏi tương tác$segmentDetail');
    }
    if (parts.isEmpty) {
      return 'Quá hạn điểm danh trong ngày';
    }
    return 'Vắng mặt: ${parts.join('. ')}.';
  }
}
