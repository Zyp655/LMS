import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:backend/helpers/pagination.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;
  final method = request.method;
  if (method == HttpMethod.get) {
    return _getCourses(context);
  } else if (method == HttpMethod.post) {
    return _createCourse(context);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _getCourses(RequestContext context) async {
  try {
    final db = context.read<AppDatabase>();
    final queryParams = context.request.uri.queryParameters;
    final pg = Pagination.fromQuery(queryParams);

    final filters = <Expression<bool> Function(Courses)>[];

    if (queryParams.containsKey('search')) {
      final search = queryParams['search']!;
      filters.add((tbl) => tbl.title.contains(search));
    }
    if (queryParams.containsKey('level')) {
      final level = queryParams['level']!;
      filters.add((tbl) => tbl.level.equals(level));
    }
    if (queryParams.containsKey('instructorId')) {
      final instructorId = int.tryParse(queryParams['instructorId']!);
      if (instructorId != null) {
        filters.add((tbl) => tbl.instructorId.equals(instructorId));
      }
    }
    if (queryParams.containsKey('majorId')) {
      final majorId = int.tryParse(queryParams['majorId']!);
      if (majorId != null) {
        filters.add((tbl) => tbl.majorId.equals(majorId));
      }
    }

    final countQuery = db.select(db.courses);
    for (final f in filters) {
      countQuery.where((tbl) => f(tbl));
    }
    final total = (await countQuery.get()).length;

    final query = db.select(db.courses);
    for (final f in filters) {
      query.where((tbl) => f(tbl));
    }
    query.limit(pg.limit, offset: pg.offset);
    final courses = await query.get();

    final List<Map<String, dynamic>> coursesJson = [];
    for (final course in courses) {
      String? majorName;
      if (course.majorId != null) {
        final major = await (db.select(db.majors)
              ..where((m) => m.id.equals(course.majorId!)))
            .getSingleOrNull();
        majorName = major?.name;
      }

      final reviews = await (db.select(db.courseReviews)
            ..where((r) => r.courseId.equals(course.id)))
          .get();
      double averageRating = 0;
      if (reviews.isNotEmpty) {
        final t = reviews.fold<int>(0, (sum, r) => sum + r.rating);
        averageRating = t / reviews.length;
      }

      final studentCount = await (db.select(db.enrollments)
            ..where((e) => e.courseId.equals(course.id)))
          .get()
          .then((rows) => rows.length);

      final modules = await (db.select(db.modules)
            ..where((m) => m.courseId.equals(course.id)))
          .get();
      int totalDuration = 0;
      for (final module in modules) {
        final lessons = await (db.select(db.lessons)
              ..where((l) => l.moduleId.equals(module.id)))
            .get();
        for (final lesson in lessons) {
          totalDuration += lesson.durationMinutes;
        }
      }

      coursesJson.add({
        'id': course.id,
        'title': course.title,
        'description': course.description,
        'thumbnailUrl': course.thumbnailUrl,
        'instructorId': course.instructorId,
        'price': course.price,
        'tags': course.tags,
        'level': course.level,
        'durationMinutes': totalDuration,
        'isPublished': course.isPublished,
        'majorId': course.majorId,
        'majorName': majorName,
        'studentCount': studentCount,
        'averageRating': double.parse(averageRating.toStringAsFixed(1)),
        'reviewsCount': reviews.length,
        'createdAt': course.createdAt.toIso8601String(),
        'updatedAt': course.updatedAt?.toIso8601String(),
      });
    }
    return Response.json(
        body: pg.wrap(coursesJson, total: total, key: 'courses'));
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}

Future<Response> _createCourse(RequestContext context) async {
  try {
    final db = context.read<AppDatabase>();
    final body = await context.request.json() as Map<String, dynamic>;
    if (!body.containsKey('title') || !body.containsKey('instructorId')) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'title and instructorId are required'},
      );
    }
    final course = await db.into(db.courses).insertReturning(
          CoursesCompanion.insert(
            title: body['title'] as String,
            instructorId: body['instructorId'] as int,
            description: Value(body['description'] as String?),
            thumbnailUrl: Value(body['thumbnailUrl'] as String?),
            price: Value((body['price'] as num?)?.toDouble() ?? 0.0),
            tags: Value(body['tags'] as String?),
            level: Value(body['level'] as String? ?? 'beginner'),
            durationMinutes: Value(body['durationMinutes'] as int? ?? 0),
            isPublished: Value(body['isPublished'] as bool? ?? true),
            majorId: Value(body['majorId'] as int?),
            createdAt: DateTime.now(),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'message': 'Course created successfully',
        'course': {
          'id': course.id,
          'title': course.title,
          'description': course.description,
          'thumbnailUrl': course.thumbnailUrl,
          'instructorId': course.instructorId,
          'price': course.price,
          'tags': course.tags,
          'level': course.level,
          'durationMinutes': course.durationMinutes,
          'isPublished': course.isPublished,
          'majorId': course.majorId,
          'createdAt': course.createdAt.toIso8601String(),
          'updatedAt': course.updatedAt?.toIso8601String(),
        },
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
