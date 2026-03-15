import 'package:backend/database/database.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final db = context.read<AppDatabase>();
  final body = await context.request.json() as Map<String, dynamic>;
  final scheduleId = body['schedule_id'] as int;
  final absences = body['absences'] as int?;
  final midterm = body['midtermScore'] as double?;
  final finalScore = body['finalScore'] as double?;
  final examScore = body['examScore'] as double?;
  final targetSchedule = await (db.select(db.schedules)
        ..where((t) => t.id.equals(scheduleId)))
      .getSingleOrNull();
  if (targetSchedule == null) {
    return Response(statusCode: 404, body: 'Không tìm thấy lịch học');
  }
  if (targetSchedule.classId != null) {
    await (db.update(db.schedules)
          ..where((t) =>
              t.classId.equals(targetSchedule.classId!) &
              t.userId.equals(targetSchedule.userId)))
        .write(
      SchedulesCompanion(
        currentAbsences:
            absences != null ? Value(absences) : const Value.absent(),
        midtermScore: midterm != null ? Value(midterm) : const Value.absent(),
        finalScore:
            finalScore != null ? Value(finalScore) : const Value.absent(),
        examScore: examScore != null ? Value(examScore) : const Value.absent(),
      ),
    );
  } else {
    await (db.update(db.schedules)..where((t) => t.id.equals(scheduleId)))
        .write(
      SchedulesCompanion(
        currentAbsences:
            absences != null ? Value(absences) : const Value.absent(),
        midtermScore: midterm != null ? Value(midterm) : const Value.absent(),
        finalScore:
            finalScore != null ? Value(finalScore) : const Value.absent(),
        examScore: examScore != null ? Value(examScore) : const Value.absent(),
      ),
    );
  }
  return Response.json(body: {'message': 'Cập nhật thành công'});
}
