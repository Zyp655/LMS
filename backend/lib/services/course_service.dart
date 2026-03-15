import 'package:backend/database/database.dart';
import 'package:backend/services/redis_service.dart';
import 'package:drift/drift.dart';

class CourseService {
  final AppDatabase db;
  final RedisService _redis = RedisService();
  CourseService(this.db);

  String _cacheKey(int courseId, {int? userId}) =>
      'course:$courseId${userId != null ? ':u$userId' : ''}';

  Future<Map<String, dynamic>> getCourseDetails(
    int courseId, {
    int? userId,
  }) async {
    final key = _cacheKey(courseId, userId: userId);
    final cached = await _redis.getJson(key);
    if (cached != null) return cached;

    final result = await _fetchCourseDetails(courseId, userId: userId);

    if (!result.containsKey('error')) {
      await _redis.setJson(key, result, ttlSeconds: 120);
    }

    return result;
  }

  Future<Map<String, dynamic>> _fetchCourseDetails(
    int courseId, {
    int? userId,
  }) async {
    Set<int> completedLessonIds = {};
    if (userId != null) {
      final progressRows = await (db.select(db.lessonProgress)
            ..where((tbl) =>
                tbl.userId.equals(userId) & tbl.isCompleted.equals(true)))
          .get();
      completedLessonIds = progressRows.map((row) => row.lessonId).toSet();
    }

    final course = await (db.select(db.courses)
          ..where((tbl) => tbl.id.equals(courseId)))
        .getSingleOrNull();

    final academicCourse = course == null
        ? await (db.select(db.academicCourses)
              ..where((tbl) => tbl.id.equals(courseId)))
            .getSingleOrNull()
        : null;

    if (course == null && academicCourse == null) {
      return {'error': 'Course not found', 'statusCode': 404};
    }

    final isAcademic = course == null && academicCourse != null;

    List<Module> modules;
    if (isAcademic) {
      modules = await (db.select(db.modules)
            ..where((tbl) => tbl.academicCourseId.equals(courseId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.orderIndex)]))
          .get();
    } else {
      modules = await (db.select(db.modules)
            ..where((tbl) => tbl.courseId.equals(courseId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.orderIndex)]))
          .get();
    }

    final modulesWithLessons = <Map<String, dynamic>>[];
    int totalDuration = 0;

    for (final module in modules) {
      final lessons = await (db.select(db.lessons)
            ..where((tbl) => tbl.moduleId.equals(module.id))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.orderIndex)]))
          .get();

      for (final lesson in lessons) {
        totalDuration += lesson.durationMinutes;
      }

      modulesWithLessons.add({
        'id': module.id,
        'title': module.title,
        'description': module.description,
        'orderIndex': module.orderIndex,
        'lessons': lessons
            .map((lesson) => {
                  'id': lesson.id,
                  'title': lesson.title,
                  'type': lesson.type,
                  'contentUrl': lesson.contentUrl,
                  'durationMinutes': lesson.durationMinutes,
                  'isFreePreview': lesson.isFreePreview,
                  'orderIndex': lesson.orderIndex,
                  'isCompleted': completedLessonIds.contains(lesson.id),
                })
            .toList(),
      });
    }

    if (isAcademic) {
      return {
        'id': academicCourse!.id,
        'title': academicCourse.name,
        'description': academicCourse.description,
        'thumbnailUrl': academicCourse.thumbnailUrl,
        'instructorId': null,
        'price': 0,
        'tags': null,
        'level': 'beginner',
        'durationMinutes': totalDuration,
        'studentCount': 0,
        'averageRating': 0.0,
        'reviewsCount': 0,
        'isPublished': academicCourse.isPublished,
        'modules': modulesWithLessons,
        'isAcademic': true,
      };
    }

    final studentCount = await (db.select(db.enrollments)
          ..where((e) => e.courseId.equals(courseId)))
        .get()
        .then((rows) => rows.length);

    final reviews = await (db.select(db.courseReviews)
          ..where((r) => r.courseId.equals(courseId)))
        .get();
    double averageRating = 0;
    if (reviews.isNotEmpty) {
      final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
      averageRating = total / reviews.length;
    }

    return {
      'id': course!.id,
      'title': course.title,
      'description': course.description,
      'thumbnailUrl': course.thumbnailUrl,
      'instructorId': course.instructorId,
      'price': course.price,
      'tags': course.tags,
      'level': course.level,
      'durationMinutes': totalDuration,
      'studentCount': studentCount,
      'averageRating': double.parse(averageRating.toStringAsFixed(1)),
      'reviewsCount': reviews.length,
      'isPublished': course.isPublished,
      'modules': modulesWithLessons,
    };
  }

  Future<int> updateCourse(
    int courseId,
    Map<String, dynamic> body,
  ) async {
    final updated = db.update(db.courses)
      ..where((tbl) => tbl.id.equals(courseId));
    final result = await updated.write(
      CoursesCompanion(
        title: body.containsKey('title')
            ? Value(body['title'] as String)
            : const Value.absent(),
        description: body.containsKey('description')
            ? Value(body['description'] as String?)
            : const Value.absent(),
        thumbnailUrl: body.containsKey('thumbnailUrl')
            ? Value(body['thumbnailUrl'] as String?)
            : const Value.absent(),
        price: body.containsKey('price')
            ? Value((body['price'] as num).toDouble())
            : const Value.absent(),
        tags: body.containsKey('tags')
            ? Value(body['tags'] as String?)
            : const Value.absent(),
        level: body.containsKey('level')
            ? Value(body['level'] as String)
            : const Value.absent(),
        durationMinutes: body.containsKey('durationMinutes')
            ? Value(body['durationMinutes'] as int)
            : const Value.absent(),
        isPublished: body.containsKey('isPublished')
            ? Value(body['isPublished'] as bool)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _redis.deletePattern('course:$courseId*');
    return result;
  }

  Future<void> deleteCourse(int courseId) async {
    final course = await (db.select(db.courses)
          ..where((tbl) => tbl.id.equals(courseId)))
        .getSingleOrNull();
    if (course == null) {
      throw CourseNotFoundException(courseId);
    }

    final studyPlans = await (db.select(db.studyPlans)
          ..where((tbl) => tbl.courseId.equals(courseId)))
        .get();
    for (final plan in studyPlans) {
      await (db.delete(db.scheduledLessons)
            ..where((tbl) => tbl.studyPlanId.equals(plan.id)))
          .go();
    }
    await (db.delete(db.studyPlans)
          ..where((tbl) => tbl.courseId.equals(courseId)))
        .go();

    await (db.delete(db.studentActivityLogs)
          ..where((tbl) => tbl.courseId.equals(courseId)))
        .go();

    final roadmaps = await (db.select(db.roadmaps)
          ..where((tbl) => tbl.courseId.equals(courseId)))
        .get();
    for (final roadmap in roadmaps) {
      await (db.delete(db.roadmapEdges)
            ..where((tbl) => tbl.roadmapId.equals(roadmap.id)))
          .go();
      await (db.delete(db.roadmapNodes)
            ..where((tbl) => tbl.roadmapId.equals(roadmap.id)))
          .go();
    }
    await (db.delete(db.roadmaps)
          ..where((tbl) => tbl.courseId.equals(courseId)))
        .go();

    final modules = await (db.select(db.modules)
          ..where((tbl) => tbl.courseId.equals(courseId)))
        .get();

    for (final module in modules) {
      final lessons = await (db.select(db.lessons)
            ..where((tbl) => tbl.moduleId.equals(module.id)))
          .get();

      for (final lesson in lessons) {
        await (db.delete(db.lessonProgress)
              ..where((tbl) => tbl.lessonId.equals(lesson.id)))
            .go();
        await (db.delete(db.comments)
              ..where((tbl) => tbl.lessonId.equals(lesson.id)))
            .go();
        await (db.delete(db.courseFiles)
              ..where((tbl) => tbl.lessonId.equals(lesson.id)))
            .go();
        await (db.delete(db.roadmapNodes)
              ..where((tbl) => tbl.lessonId.equals(lesson.id)))
            .go();
        await (db.delete(db.scheduledLessons)
              ..where((tbl) => tbl.lessonId.equals(lesson.id)))
            .go();
        await (db.delete(db.studentActivityLogs)
              ..where((tbl) => tbl.lessonId.equals(lesson.id)))
            .go();
      }

      await (db.delete(db.lessons)
            ..where((tbl) => tbl.moduleId.equals(module.id)))
          .go();
    }

    await (db.delete(db.modules)..where((tbl) => tbl.courseId.equals(courseId)))
        .go();
    await (db.delete(db.enrollments)
          ..where((tbl) => tbl.courseId.equals(courseId)))
        .go();
    await (db.delete(db.courseReviews)
          ..where((tbl) => tbl.courseId.equals(courseId)))
        .go();
    await (db.delete(db.courses)..where((tbl) => tbl.id.equals(courseId))).go();
    await _redis.deletePattern('course:$courseId*');
  }
}

class CourseNotFoundException implements Exception {
  final int courseId;
  CourseNotFoundException(this.courseId);

  @override
  String toString() => 'Course $courseId not found';
}
