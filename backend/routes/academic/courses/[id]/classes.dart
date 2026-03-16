import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final courseId = int.tryParse(id);
  if (courseId == null) {
    return Response.json(statusCode: 400, body: {'error': 'Invalid course id'});
  }

  final db = context.read<AppDatabase>();

  try {
    final rows = await (db.select(db.courseClasses)
          ..where((c) => c.academicCourseId.equals(courseId)))
        .get();

    final users = await db.select(db.users).get();
    final userMap = {for (final u in users) u.id: u};

    return Response.json(
      body: {
        'classes': rows
            .map((c) => {
                  'id': c.id,
                  'classCode': c.classCode,
                  'teacherId': c.teacherId,
                  'teacherName': userMap[c.teacherId]?.fullName ??
                      userMap[c.teacherId]?.email ??
                      '',
                  'schedule': c.schedule,
                  'dayOfWeek': c.dayOfWeek,
                  'startDate': c.startDate?.toIso8601String(),
                  'endDate': c.endDate?.toIso8601String(),
                  'room': c.room,
                  'maxStudents': c.maxStudents,
                })
            .toList(),
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': 'Lỗi: $e'},
    );
  }
}
