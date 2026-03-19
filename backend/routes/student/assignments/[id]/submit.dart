import 'package:backend/database/database.dart';
import 'package:backend/helpers/notification_helper.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final db = context.read<AppDatabase>();
  final assignmentId = int.parse(id);

  Map<String, dynamic> body;
  final contentType = context.request.headers['content-type'] ?? '';
  if (contentType.contains('multipart/form-data')) {
    final formData = await context.request.formData();
    body = formData.fields.map((k, v) => MapEntry(k, v));
    if (body.containsKey('userId')) {
      body['userId'] = int.tryParse(body['userId'].toString()) ?? 0;
    }
    if (body.containsKey('fileSize')) {
      body['fileSize'] = int.tryParse(body['fileSize'].toString());
    }
  } else {
    body = await context.request.json() as Map<String, dynamic>;
  }

  if (!body.containsKey('userId')) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Missing userId'},
    );
  }
  final studentId = body['userId'] as int;
  try {
    final assignment = await (db.select(db.assignments)
          ..where((a) => a.id.equals(assignmentId)))
        .getSingleOrNull();
    if (assignment == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Assignment not found'},
      );
    }
    final existing = await (db.select(db.submissions)
          ..where(
            (s) =>
                s.assignmentId.equals(assignmentId) &
                s.studentId.equals(studentId),
          )
          ..orderBy([(s) => OrderingTerm.desc(s.version)])
          ..limit(1))
        .getSingleOrNull();
    final isLate = DateTime.now().isAfter(assignment.dueDate);
    final version = existing != null ? existing.version + 1 : 1;
    final submission = await db.into(db.submissions).insertReturning(
          SubmissionsCompanion.insert(
            assignmentId: assignmentId,
            studentId: studentId,
            fileUrl: Value(body['fileUrl'] as String?),
            fileName: Value(body['fileName'] as String?),
            fileSize: Value(body['fileSize'] as int?),
            linkUrl: Value(body['linkUrl'] as String?),
            textContent: Value(body['textContent'] as String?),
            submittedAt: DateTime.now(),
            isLate: Value(isLate),
            status: 'submitted',
            version: Value(version),
            previousVersionId: Value(existing?.id),
          ),
        );
    final student = await (db.select(db.users)
          ..where((u) => u.id.equals(studentId)))
        .getSingle();
    await NotificationHelper.createNotification(
      db: db,
      userId: assignment.teacherId,
      type: 'submission_new',
      title: 'Bài nộp mới',
      message:
          '${student.fullName ?? student.email} đã nộp bài: ${assignment.title}',
      relatedId: submission.id,
      relatedType: 'submission',
    );
    return Response.json(
      statusCode: 201,
      body: {
        'id': submission.id,
        'assignmentId': submission.assignmentId,
        'studentId': submission.studentId,
        'submittedAt': submission.submittedAt.toIso8601String(),
        'isLate': submission.isLate,
        'status': submission.status,
        'version': submission.version,
      },
    );
  } catch (e) {
    print('[Submit] Error: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Submit failed: $e'},
    );
  }
}

