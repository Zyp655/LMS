import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final courseId = int.tryParse(id);
  if (courseId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid course ID'},
    );
  }
  final method = context.request.method;
  if (method == HttpMethod.get) {
    return _getReviews(context, courseId);
  } else if (method == HttpMethod.post) {
    return _createReview(context, courseId);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _getReviews(RequestContext context, int courseId) async {
  try {
    final db = context.read<AppDatabase>();
    final reviews = await (db.select(db.courseReviews)
          ..where((r) => r.courseId.equals(courseId))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .get();
    double avgRating = 0;
    if (reviews.isNotEmpty) {
      final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
      avgRating = total / reviews.length;
    }
    final distribution = <String, int>{'1': 0, '2': 0, '3': 0, '4': 0, '5': 0};
    for (final review in reviews) {
      final key = review.rating.toString();
      distribution[key] = (distribution[key] ?? 0) + 1;
    }
    final List<Map<String, dynamic>> reviewsWithUser = [];
    for (final review in reviews) {
      final user = await (db.select(db.users)
            ..where((u) => u.id.equals(review.userId)))
          .getSingleOrNull();
      reviewsWithUser.add({
        'id': review.id,
        'userId': review.userId,
        'userName': user?.fullName ?? 'Anonymous',
        'rating': review.rating,
        'comment': review.comment,
        'createdAt': review.createdAt.toIso8601String(),
      });
    }
    return Response.json(
      body: {
        'courseId': courseId,
        'averageRating': double.parse(avgRating.toStringAsFixed(1)),
        'totalReviews': reviews.length,
        'distribution': distribution,
        'reviews': reviewsWithUser,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}

Future<Response> _createReview(RequestContext context, int courseId) async {
  try {
    final db = context.read<AppDatabase>();
    final body = await context.request.json() as Map<String, dynamic>;
    final userId = body['userId'] as int?;
    final rating = body['rating'] as int?;
    final comment = body['comment'] as String?;
    if (userId == null || rating == null || rating < 1 || rating > 5) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'userId and rating (1-5) are required'},
      );
    }
    final existingReview = await (db.select(db.courseReviews)
          ..where((r) => r.courseId.equals(courseId) & r.userId.equals(userId)))
        .getSingleOrNull();
    if (existingReview != null) {
      await (db.update(db.courseReviews)
            ..where((r) => r.id.equals(existingReview.id)))
          .write(CourseReviewsCompanion(
        rating: Value(rating),
        comment: Value(comment),
        updatedAt: Value(DateTime.now()),
      ));
      return Response.json(
        body: {
          'id': existingReview.id,
          'message': 'Review updated successfully'
        },
      );
    } else {
      final id = await db.into(db.courseReviews).insert(
            CourseReviewsCompanion.insert(
              courseId: courseId,
              userId: userId,
              rating: rating,
              comment: Value(comment),
              createdAt: DateTime.now(),
            ),
          );
      return Response.json(
        statusCode: HttpStatus.created,
        body: {'id': id, 'message': 'Review created successfully'},
      );
    }
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
