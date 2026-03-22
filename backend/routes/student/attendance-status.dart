import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final db = context.read<AppDatabase>();
  final userId = context.read<int>();
  final params = context.request.uri.queryParameters;
  final dateStr = params['date'];

  final date = dateStr != null ? DateTime.tryParse(dateStr) : DateTime.now();
  if (date == null) {
    return Response.json(statusCode: 400, body: {'error': 'Invalid date'});
  }

  final dayStart = DateTime(date.year, date.month, date.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  final schedules = await (db.select(db.schedules)
        ..where((s) => s.userId.equals(userId))
        ..where((s) => s.startTime.isBiggerOrEqualValue(dayStart))
        ..where((s) => s.startTime.isSmallerThanValue(dayEnd))
        ..where((s) => s.type.equals('classSession')))
      .get();

  final results = <Map<String, dynamic>>[];

  for (final schedule in schedules) {
    final log = await (db.select(db.dailyLearningLogs)
          ..where((l) => l.studentId.equals(userId))
          ..where((l) => l.scheduleId.equals(schedule.id))
          ..where((l) => l.date.isBiggerOrEqualValue(dayStart))
          ..where((l) => l.date.isSmallerThanValue(dayEnd)))
        .getSingleOrNull();

    results.add({
      'scheduleId': schedule.id,
      'subjectName': schedule.subjectName,
      'startTime': schedule.startTime.toIso8601String(),
      'endTime': schedule.endTime.toIso8601String(),
      'currentAbsences': schedule.currentAbsences,
      'maxAbsences': schedule.maxAbsences,
      'status': log?.status ?? 'not_accessed',
      'watchPercentage': log?.watchPercentage ?? 0.0,
      'quizCompleted': log?.quizCompleted ?? false,
      'absenceReason': log?.absenceReason,
      'finalizedAt': log?.finalizedAt?.toIso8601String(),
      'conditions': {
        'watchTimeMet': (log?.watchPercentage ?? 0) >= 90.0,
        'quizMet': log?.quizCompleted ?? false,
        'bothMet': (log?.watchPercentage ?? 0) >= 90.0 &&
            (log?.quizCompleted ?? false),
      },
    });
  }

  final totalSchedules = results.length;
  final present = results.where((r) => r['status'] == 'present').length;
  final absent = results.where((r) => r['status'] == 'absent').length;
  final pending = results
      .where((r) => r['status'] == 'pending' || r['status'] == 'not_accessed')
      .length;

  return Response.json(body: {
    'date': dayStart.toIso8601String(),
    'summary': {
      'total': totalSchedules,
      'present': present,
      'absent': absent,
      'pending': pending,
    },
    'schedules': results,
  });
}
