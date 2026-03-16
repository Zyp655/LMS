import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final courseId = int.tryParse(id);
  if (courseId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'ID học phần không hợp lệ'},
    );
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _getCourseDetail(context, courseId);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getCourseDetail(
  RequestContext context,
  int courseId,
) async {
  try {
    final db = context.read<AppDatabase>();
    final params = context.request.uri.queryParameters;
    final userId = int.tryParse(params['userId'] ?? '');

    final course = await (db.select(db.academicCourses)
          ..where((c) => c.id.equals(courseId)))
        .getSingleOrNull();

    if (course == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Không tìm thấy học phần'},
      );
    }

    final dept = await (db.select(db.departments)
          ..where((d) => d.id.equals(course.departmentId)))
        .getSingleOrNull();

    final modules = await (db.select(db.modules)
          ..where((m) => m.academicCourseId.equals(courseId))
          ..orderBy([(m) => OrderingTerm.asc(m.orderIndex)]))
        .get();

    final moduleList = <Map<String, dynamic>>[];
    for (final mod in modules) {
      final lessons = await (db.select(db.lessons)
            ..where((l) => l.moduleId.equals(mod.id))
            ..orderBy([(l) => OrderingTerm.asc(l.orderIndex)]))
          .get();

      moduleList.add({
        'id': mod.id,
        'title': mod.title,
        'description': mod.description,
        'orderIndex': mod.orderIndex,
        'lessons': lessons
            .map((l) => {
                  'id': l.id,
                  'title': l.title,
                  'type': l.type,
                  'contentUrl': l.contentUrl,
                  'textContent': l.textContent,
                  'quizId': l.quizId,
                  'assignmentId': l.assignmentId,
                  'durationMinutes': l.durationMinutes,
                  'isFreePreview': l.isFreePreview,
                  'orderIndex': l.orderIndex,
                  'createdAt': l.createdAt.toIso8601String(),
                })
            .toList(),
      });
    }

    final classes = await (db.select(db.courseClasses)
          ..where((c) => c.academicCourseId.equals(courseId)))
        .get();

    final classList = <Map<String, dynamic>>[];
    for (final cls in classes) {
      final teacher = cls.teacherId != null
          ? await (db.select(db.users)
                ..where((u) => u.id.equals(cls.teacherId!)))
              .getSingleOrNull()
          : null;

      final semester = await (db.select(db.semesters)
            ..where((s) => s.id.equals(cls.semesterId)))
          .getSingleOrNull();

      final enrolledCount = await (db.selectOnly(db.courseClassEnrollments)
            ..addColumns([db.courseClassEnrollments.id.count()])
            ..where(
              db.courseClassEnrollments.courseClassId.equals(cls.id) &
                  db.courseClassEnrollments.status.equals('enrolled'),
            ))
          .map((row) => row.read(db.courseClassEnrollments.id.count()) ?? 0)
          .getSingle();

      classList.add({
        'id': cls.id,
        'classCode': cls.classCode,
        'teacherId': cls.teacherId,
        'teacherName': teacher?.fullName ?? teacher?.email ?? 'N/A',
        'room': cls.room,
        'schedule': cls.schedule,
        'dayOfWeek': cls.dayOfWeek,
        'startDate': cls.startDate?.toIso8601String(),
        'endDate': cls.endDate?.toIso8601String(),
        'maxStudents': cls.maxStudents,
        'enrolledCount': enrolledCount,
        'semesterName': semester?.name,
      });
    }

    Map<String, dynamic>? enrollment;
    if (userId != null) {
      final ccIds = classes.map((c) => c.id).toList();
      if (ccIds.isNotEmpty) {
        for (final ccId in ccIds) {
          final e = await (db.select(db.courseClassEnrollments)
                ..where(
                  (t) =>
                      t.courseClassId.equals(ccId) & t.studentId.equals(userId),
                ))
              .getSingleOrNull();
          if (e != null) {
            final cls = classes.firstWhere((c) => c.id == e.courseClassId);
            enrollment = {
              'id': e.id,
              'classCode': cls.classCode,
              'status': e.status,
              'progressPercent': e.progressPercent,
              'enrolledAt': e.enrolledAt.toIso8601String(),
            };
            break;
          }
        }
      }
    }

    return Response.json(body: {
      'course': {
        'id': course.id,
        'name': course.name,
        'code': course.code,
        'credits': course.credits,
        'courseType': course.courseType,
        'description': course.description,
        'thumbnailUrl': course.thumbnailUrl,
        'departmentName': dept?.name,
        'isPublished': course.isPublished,
        'createdAt': course.createdAt.toIso8601String(),
      },
      'modules': moduleList,
      'classes': classList,
      'enrollment': enrollment,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Lỗi khi tải chi tiết học phần: $e'},
    );
  }
}
