import 'package:backend/database/database.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  final db = context.read<AppDatabase>();
  final params = context.request.uri.queryParameters;
  if (!params.containsKey('userId')) {
    return Response(statusCode: 400, body: 'Missing userId');
  }
  final studentId = int.parse(params['userId']!);
  try {
    final query = db.select(db.studentAssignments).join([
      innerJoin(
        db.assignments,
        db.assignments.id.equalsExp(db.studentAssignments.assignmentId),
      ),
      leftOuterJoin(
        db.classes,
        db.classes.id.equalsExp(db.assignments.classId),
      ),
      leftOuterJoin(
        db.modules,
        db.modules.id.equalsExp(db.assignments.moduleId),
      ),
      leftOuterJoin(
        db.academicCourses,
        db.academicCourses.id.equalsExp(db.modules.academicCourseId),
      ),
    ])
      ..where(db.studentAssignments.studentId.equals(studentId));
    final results = await query.get();

    final assignments = <Map<String, dynamic>>[];
    for (final row in results) {
      final studentAssignment = row.readTable(db.studentAssignments);
      final assignment = row.readTable(db.assignments);
      final classInfo = row.readTableOrNull(db.classes);
      final moduleInfo = row.readTableOrNull(db.modules);
      final courseInfo = row.readTableOrNull(db.academicCourses);

      final submission = await (db.select(db.submissions)
            ..where(
              (s) =>
                  s.assignmentId.equals(assignment.id) &
                  s.studentId.equals(studentId),
            )
            ..orderBy([(s) => OrderingTerm.desc(s.version)])
            ..limit(1))
          .getSingleOrNull();

      final hasSubmission = submission != null;

      assignments.add({
        'id': assignment.id,
        'studentAssignmentId': studentAssignment.id,
        'title': assignment.title,
        'description': assignment.description,
        'dueDate': assignment.dueDate.toIso8601String(),
        'rewardPoints': assignment.rewardPoints,
        'createdAt': assignment.createdAt.toIso8601String(),
        'isCompleted': hasSubmission || studentAssignment.isCompleted,
        'completedAt': studentAssignment.completedAt?.toIso8601String(),
        'rewardClaimed': studentAssignment.rewardClaimed,
        'className': classInfo?.className,
        'classId': assignment.classId,
        'moduleId': assignment.moduleId,
        'moduleName': moduleInfo?.title,
        'courseId': courseInfo?.id,
        'courseName': courseInfo?.name,
        'submissionStatus': submission?.status,
        'grade': submission?.grade,
        'maxGrade': submission?.maxGrade,
        'feedback': submission?.feedback,
        'submittedAt': submission?.submittedAt.toIso8601String(),
      });
    }

    return Response.json(body: assignments);
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'});
  }
}

