import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/course_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final courseId = int.tryParse(id);
  if (courseId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid course ID'},
    );
  }

  final service = context.read<CourseService>();

  final method = context.request.method;

  if (method == HttpMethod.get) {
    return _handleGet(context, service, courseId);
  } else if (method == HttpMethod.put) {
    return _handlePut(context, service, courseId);
  } else if (method == HttpMethod.delete) {
    return _handleDelete(service, courseId);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _handleGet(
  RequestContext context,
  CourseService service,
  int courseId,
) async {
  try {
    final userId =
        int.tryParse(context.request.uri.queryParameters['userId'] ?? '');
    final result = await service.getCourseDetails(courseId, userId: userId);

    if (result.containsKey('error')) {
      return Response.json(
        statusCode: result['statusCode'] as int,
        body: {'error': result['error']},
      );
    }
    return Response.json(body: result);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}

Future<Response> _handlePut(
  RequestContext context,
  CourseService service,
  int courseId,
) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final count = await service.updateCourse(courseId, body);

    if (count == 0) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Course not found'},
      );
    }
    return Response.json(body: {'message': 'Course updated successfully'});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}

Future<Response> _handleDelete(CourseService service, int courseId) async {
  try {
    await service.deleteCourse(courseId);
    return Response.json(body: {'message': 'Course deleted successfully'});
  } on CourseNotFoundException {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'Course not found'},
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
