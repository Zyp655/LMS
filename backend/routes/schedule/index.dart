import 'package:backend/database/database.dart';
import 'package:backend/utils/grade_calculator.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get &&
      context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final userId = context.read<int>();
  final db = context.read<AppDatabase>();
  if (context.request.method == HttpMethod.get) {
    final query = db.select(db.schedules).join([
      leftOuterJoin(db.classes, db.classes.id.equalsExp(db.schedules.classId)),
    ])
      ..where(db.schedules.userId.equals(userId));
    final result = await query.get();
    var jsonList = result.map((row) {
      final schedule = row.readTable(db.schedules);
      final classInfo = row.readTableOrNull(db.classes);
      return {
        'id': schedule.id,
        'userId': schedule.userId,
        'subject': schedule.subjectName,
        'room': schedule.room,
        'start': schedule.startTime.toIso8601String(),
        'end': schedule.endTime.toIso8601String(),
        'note': schedule.note,
        'classCode': classInfo?.classCode,
        'credits': schedule.credits,
        'currentAbsences': schedule.currentAbsences,
        'maxAbsences': schedule.maxAbsences,
        'midtermScore': schedule.midtermScore,
        'finalScore': schedule.finalScore,
        'targetScore': schedule.targetScore,
        'type': schedule.type,
        'format': schedule.format,
        'overallScore': GradeCalculator.calculateOverallScore(
          credits: schedule.credits,
          midtermScore: schedule.midtermScore,
          finalScore: schedule.finalScore,
          examScore: schedule.examScore,
          currentAbsences: schedule.currentAbsences,
          maxAbsences: schedule.maxAbsences,
        ),
      };
    }).toList();

    final selfPacedQuery = db.select(db.scheduledLessons).join([
      innerJoin(db.studyPlans,
          db.studyPlans.id.equalsExp(db.scheduledLessons.studyPlanId)),
      innerJoin(
          db.lessons, db.lessons.id.equalsExp(db.scheduledLessons.lessonId)),
      innerJoin(db.courses, db.courses.id.equalsExp(db.studyPlans.courseId)),
    ])
      ..where(db.studyPlans.userId.equals(userId));

    final selfPacedResults = await selfPacedQuery.get();

    final selfPacedJson = selfPacedResults.map((row) {
      final scheduled = row.readTable(db.scheduledLessons);
      final lesson = row.readTable(db.lessons);
      final course = row.readTable(db.courses);

      final date = scheduled.scheduledDate;
      final timeParts = scheduled.scheduledTime.split(':');
      final startDateTime = DateTime(date.year, date.month, date.day,
          int.parse(timeParts[0]), int.parse(timeParts[1]));
      final endDateTime = startDateTime.add(Duration(
          minutes: lesson.durationMinutes > 0 ? lesson.durationMinutes : 45));

      return {
        'id': -scheduled.id,
        'userId': userId,
        'subject': '${course.title} - ${lesson.title}',
        'room': 'Online',
        'start': startDateTime.toIso8601String(),
        'end': endDateTime.toIso8601String(),
        'note': 'Bài học tự học',
        'classCode': 'ONLINE',
        'credits': 0,
        'currentAbsences': 0,
        'maxAbsences': 0,
        'midtermScore': 0.0,
        'finalScore': 0.0,
        'targetScore': 4.0,
        'type': 'selfPaced',
        'format': 'online',
        'overallScore': 0.0,
      };
    }).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<Map<String, dynamic>> enrolledJson = [];

    final academicQuery = db.select(db.courseClassEnrollments).join([
      innerJoin(db.courseClasses,
          db.courseClasses.id.equalsExp(db.courseClassEnrollments.courseClassId)),
      innerJoin(db.academicCourses,
          db.academicCourses.id.equalsExp(db.courseClasses.academicCourseId)),
    ])
      ..where(db.courseClassEnrollments.studentId.equals(userId))
      ..where(db.courseClassEnrollments.status.equals('enrolled'));

    final academicResults = await academicQuery.get();
    final List<Map<String, dynamic>> academicJson = [];

    for (final row in academicResults) {
      final cc = row.readTable(db.courseClasses);
      final ac = row.readTable(db.academicCourses);

      if (cc.dayOfWeek != null && cc.startDate != null && cc.endDate != null) {
        final dow = cc.dayOfWeek!;
        final rangeStart = DateTime(cc.startDate!.year, cc.startDate!.month, cc.startDate!.day);
        final rangeEnd = DateTime(cc.endDate!.year, cc.endDate!.month, cc.endDate!.day);
        final monday = rangeStart.subtract(Duration(days: rangeStart.weekday - 1));
        final firstTarget = monday.add(Duration(days: dow - 1));
        final start = firstTarget.isBefore(rangeStart)
            ? firstTarget.add(const Duration(days: 7))
            : firstTarget;
        final totalWeeks = ((rangeEnd.difference(start).inDays) / 7).floor() + 1;

        for (var w = 0; w < totalWeeks; w++) {
          final targetDate = start.add(Duration(days: w * 7));
          if (targetDate.isAfter(rangeEnd)) break;
          final startDt = DateTime(
              targetDate.year, targetDate.month, targetDate.day, 7, 0);
          final endDt = DateTime(
              targetDate.year, targetDate.month, targetDate.day, 9, 30);

          academicJson.add({
            'id': -(20000 + cc.id * 100 + w),
            'userId': userId,
            'subject': ac.name,
            'room': cc.room ?? '',
            'start': startDt.toIso8601String(),
            'end': endDt.toIso8601String(),
            'note': 'Lớp ${cc.classCode}',
            'classCode': cc.classCode,
            'credits': ac.credits,
            'currentAbsences': 0,
            'maxAbsences': ac.credits * 3,
            'type': 'classSession',
            'format': 'offline',
          });
        }
        continue;
      }

      final scheduleText = cc.schedule ?? '';
      if (scheduleText.isEmpty) continue;

      final dayTimeMatch =
          RegExp(r'T(\d)\s*\((\d{1,2}:\d{2})-(\d{1,2}:\d{2})\)')
              .firstMatch(scheduleText);
      final dayDateMatch =
          RegExp(r'T(\d)\s*\((\d{1,2})/(\d{1,2})/(\d{4})\)')
              .firstMatch(scheduleText);

      if (dayTimeMatch != null) {
        final dayOfWeek = int.parse(dayTimeMatch.group(1)!);
        final startParts = dayTimeMatch.group(2)!.split(':');
        final endParts = dayTimeMatch.group(3)!.split(':');
        final startHour = int.parse(startParts[0]);
        final startMin = int.parse(startParts[1]);
        final endHour = int.parse(endParts[0]);
        final endMin = int.parse(endParts[1]);

        final monday = today.subtract(Duration(days: today.weekday - 1));
        for (var weekOffset = 0; weekOffset <= 28; weekOffset++) {
          final targetDate = monday
              .add(Duration(days: (dayOfWeek - 1) + (weekOffset * 7)));
          final startDt = DateTime(
              targetDate.year, targetDate.month, targetDate.day,
              startHour, startMin);
          final endDt = DateTime(
              targetDate.year, targetDate.month, targetDate.day,
              endHour, endMin);

          academicJson.add({
            'id': -(20000 + cc.id * 100 + weekOffset),
            'userId': userId,
            'subject': ac.name,
            'room': cc.room ?? '',
            'start': startDt.toIso8601String(),
            'end': endDt.toIso8601String(),
            'note': 'Lớp ${cc.classCode}',
            'classCode': cc.classCode,
            'credits': ac.credits,
            'currentAbsences': 0,
            'maxAbsences': ac.credits * 3,
            'type': 'classSession',
            'format': 'offline',
          });
        }
      } else if (dayDateMatch != null) {
        final day = int.parse(dayDateMatch.group(2)!);
        final month = int.parse(dayDateMatch.group(3)!);
        final year = int.parse(dayDateMatch.group(4)!);
        final targetDate = DateTime(year, month, day, 7, 0);
        final endDate = DateTime(year, month, day, 9, 30);

        academicJson.add({
          'id': -(20000 + cc.id),
          'userId': userId,
          'subject': ac.name,
          'room': cc.room ?? '',
          'start': targetDate.toIso8601String(),
          'end': endDate.toIso8601String(),
          'note': 'Lớp ${cc.classCode}',
          'classCode': cc.classCode,
          'credits': ac.credits,
          'currentAbsences': 0,
          'maxAbsences': ac.credits * 3,
          'type': 'classSession',
          'format': 'offline',
        });
      }
    }

    final allSchedules = [
      ...jsonList,
      ...selfPacedJson,
      ...enrolledJson,
      ...academicJson,
    ];
    allSchedules
        .sort((a, b) => (a['start'] as String).compareTo(b['start'] as String));

    return Response.json(body: allSchedules);
  }
  if (context.request.method == HttpMethod.post) {
    try {
      final json = await context.request.json();
      if (json is List) {
        await db.batch((batch) {
          for (var item in json) {
            final map = item as Map<String, dynamic>;
            final credits = map['credits'] as int? ?? 3;
            batch.insert(
              db.schedules,
              SchedulesCompanion.insert(
                userId: userId,
                subjectName: map['subject'] as String,
                startTime: DateTime.parse(map['start'] as String),
                endTime: DateTime.parse(map['end'] as String),
                room: Value(map['room'] as String? ?? ''),
                credits: Value(credits),
                maxAbsences: Value(credits * 3),
                type: Value(map['type'] as String? ?? 'classSession'),
                format: Value(map['format'] as String? ?? 'offline'),
              ),
            );
          }
        });
        return Response.json(
            body: {'message': 'Đã import ${json.length} lịch học'});
      } else if (json is Map<String, dynamic>) {
        final credits = json['credits'] as int? ?? 3;
        await db.into(db.schedules).insert(
              SchedulesCompanion.insert(
                userId: userId,
                subjectName: json['subject'] as String,
                startTime: DateTime.parse(json['start'] as String),
                endTime: DateTime.parse(json['end'] as String),
                room: Value(json['room'] as String? ?? ''),
                credits: Value(credits),
                maxAbsences: Value(credits * 3),
                type: Value(json['type'] as String? ?? 'classSession'),
                format: Value(json['format'] as String? ?? 'offline'),
              ),
            );
        return Response.json(body: {'message': 'Đã thêm lịch học'});
      }
      return Response.json(
        statusCode: 400,
        body: {'error': 'Dữ liệu không hợp lệ'},
      );
    } catch (e) {
      return Response.json(statusCode: 500, body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'});
    }
  }
  return Response(statusCode: 405);
}
