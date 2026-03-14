import 'dart:math';
import 'package:backend/database/database.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
String _generateClassCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rnd = Random();
  return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
}
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final db = context.read<AppDatabase>();
  final body = await context.request.json() as Map<String, dynamic>;
  final className = body['className'] as String?;
  final teacherId = body['teacherId'] as int?;
  final room = body['room'] as String?;
  final subjectName = body['subjectName'] as String?;
  final startTimeStr = body['startTime'] as String?;
  final endTimeStr = body['endTime'] as String?;
  final startDateStr = body['startDate'] as String?;
  final repeatWeeks = body['repeatWeeks'] as int? ?? 1;
  final notificationMinutes = body['notificationMinutes'] as int? ?? 15;
  final credits = body['credits'] as int? ?? 2;
  final maxAbsences = credits * 3;
  if (className == null ||
      teacherId == null ||
      room == null ||
      subjectName == null ||
      startTimeStr == null ||
      endTimeStr == null ||
      startDateStr == null) {
    return Response(
        statusCode: 400,
        body:
            'Thi?u thông tin (className, teacherId, room, subjectName, startTime, endTime, startDate)');
  }
  DateTime baseStartTime;
  DateTime baseEndTime;
  DateTime startDate;
  try {
    baseStartTime = DateTime.parse(startTimeStr);
    baseEndTime = DateTime.parse(endTimeStr);
    startDate = DateTime.parse(startDateStr);
  } catch (e) {
    return Response(
        statusCode: 400, body: 'Ð?nh d?ng th?i gian/ngày không h?p l?');
  }
  if (baseEndTime.isBefore(baseStartTime) ||
      baseEndTime.isAtSameMomentAs(baseStartTime)) {
    return Response(statusCode: 400, body: 'Gi? k?t thúc ph?i sau gi? b?t d?u');
  }
  final code = _generateClassCode();
  final classId = await db.into(db.classes).insert(ClassesCompanion.insert(
        className: className,
        classCode: code,
        teacherId: teacherId,
        createdAt: DateTime.now(),
      ));
  for (int i = 0; i < repeatWeeks; i++) {
    final currentDate = startDate.add(Duration(days: 7 * i));
    final startDateTime = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      baseStartTime.hour,
      baseStartTime.minute,
    );
    final endDateTime = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      baseEndTime.hour,
      baseEndTime.minute,
    );
    final existingSchedules = await (db.select(db.schedules)
          ..where((s) => s.room.equals(room)))
        .get();
    for (final schedule in existingSchedules) {
      final existingStart = schedule.startTime;
      final existingEnd = schedule.endTime;
      if (startDateTime.isBefore(existingEnd) &&
          existingStart.isBefore(endDateTime)) {
        return Response(
            statusCode: 409,
            body:
                'Xung d?t l?ch t?i b?: Tu?n ${i + 1} ($currentDate). Phòng "$room" có l?p k?t thúc lúc $existingEnd và b?n b?t d?u lúc $startDateTime.');
      }
    }
    await db.into(db.schedules).insert(SchedulesCompanion.insert(
          userId: teacherId,
          classId: Value(classId),
          subjectName: subjectName,
          room: Value(room),
          startTime: startDateTime,
          endTime: endDateTime,
          note: Value('L?p: $className - Tu?n ${i + 1}'),
          notificationMinutes: Value(notificationMinutes),
          credits: Value(credits),
          maxAbsences: Value(maxAbsences),
        ));
  }
  return Response.json(body: {
    'message': 'T?o l?p thành công',
    'classCode': code,
    'className': className,
    'room': room,
    'startTime': startTimeStr,
    'endTime': endTimeStr,
    'credits': credits,
    'maxAbsences': maxAbsences,
  });
}
