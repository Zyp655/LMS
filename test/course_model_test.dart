import 'package:flutter_test/flutter_test.dart';
import 'package:alarmm/features/course/data/models/course_model.dart';

void main() {
  test('CourseModel.fromJson parses academic backend data correctly', () {
    final json = {
      'id': 1,
      'name': 'Lập trình Flutter',
      'code': 'CS301',
      'description': 'Học Flutter cơ bản đến nâng cao',
      'thumbnailUrl': 'http://example.com/image.png',
      'credits': 3,
      'courseType': 'required',
      'isPublished': true,
      'departmentName': 'Khoa CNTT',
      'moduleCount': 10,
      'classCount': 2,
      'createdAt': '2024-01-01T00:00:00.000Z',
    };

    try {
      final course = CourseModel.fromJson(json);
      expect(course.id, 1);
      expect(course.name, 'Lập trình Flutter');
      expect(course.code, 'CS301');
      expect(course.credits, 3);
      expect(course.courseType, 'required');
      expect(course.isRequired, true);
      expect(course.departmentName, 'Khoa CNTT');
      expect(course.moduleCount, 10);
    } catch (e) {
      fail('CourseModel.fromJson threw exception: \$e');
    }
  });

  test('CourseModel.fromJson handles missing optional fields', () {
    final json = {
      'id': 2,
      'name': 'AI cơ bản',
      'code': 'AI101',
      'credits': 2,
      'courseType': 'elective',
      'isPublished': false,
      'createdAt': '2024-02-01T00:00:00.000Z',
    };

    final course = CourseModel.fromJson(json);
    expect(course.id, 2);
    expect(course.name, 'AI cơ bản');
    expect(course.isRequired, false);
    expect(course.departmentName, isNull);
    expect(course.moduleCount, isNull);
  });
}
