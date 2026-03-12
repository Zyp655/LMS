import 'package:flutter_test/flutter_test.dart';
import 'package:alarmm/features/course/domain/entities/course_entity.dart';

void main() {
  group('CourseEntity', () {
    test('should create CourseEntity with required fields', () {
      final course = CourseEntity(
        id: 1,
        name: 'Lập trình Flutter',
        code: 'CS301',
        credits: 3,
        courseType: 'required',
        isPublished: true,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(course.id, 1);
      expect(course.name, 'Lập trình Flutter');
      expect(course.code, 'CS301');
      expect(course.credits, 3);
      expect(course.courseType, 'required');
      expect(course.isPublished, true);
      expect(course.isRequired, true);
    });

    test('should support equality comparison', () {
      final course1 = CourseEntity(
        id: 1,
        name: 'Flutter',
        code: 'CS301',
        credits: 3,
        courseType: 'required',
        isPublished: true,
        createdAt: DateTime(2024, 1, 1),
      );

      final course2 = CourseEntity(
        id: 1,
        name: 'Flutter',
        code: 'CS301',
        credits: 3,
        courseType: 'required',
        isPublished: true,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(course1, course2);
    });

    test('isRequired returns correct value', () {
      final required = CourseEntity(
        id: 1,
        name: 'Test',
        code: 'T01',
        credits: 2,
        courseType: 'required',
        isPublished: true,
        createdAt: DateTime.now(),
      );

      final elective = CourseEntity(
        id: 2,
        name: 'Test 2',
        code: 'T02',
        credits: 2,
        courseType: 'elective',
        isPublished: true,
        createdAt: DateTime.now(),
      );

      expect(required.isRequired, true);
      expect(elective.isRequired, false);
    });
  });
}
