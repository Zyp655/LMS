import 'package:flutter_test/flutter_test.dart';
import 'package:alarmm/features/course/data/models/course_class_model.dart';

void main() {
  group('CourseClassModel.fromMyCoursesJson', () {
    test('parses full response correctly', () {
      final json = {
        'course': {
          'id': 10,
          'name': 'Lập trình Flutter',
          'code': 'CS301',
          'credits': 3,
          'courseType': 'required',
          'description': 'Mô tả khóa học',
          'departmentName': 'Khoa CNTT',
          'moduleCount': 8,
        },
        'courseClass': {
          'id': 5,
          'classCode': 'CS301-01',
          'room': 'A301',
          'schedule': 'T2 7:00-9:30',
          'maxStudents': 45,
          'enrolledCount': 30,
        },
        'teacherName': 'TS. Nguyễn Văn A',
        'semesterName': 'HK2 2024-2025',
        'enrollmentId': 100,
        'status': 'enrolled',
        'progressPercent': 65.5,
        'enrolledAt': '2024-09-01T00:00:00.000Z',
        'completedAt': null,
      };

      final model = CourseClassModel.fromMyCoursesJson(json);

      expect(model.courseId, 10);
      expect(model.courseName, 'Lập trình Flutter');
      expect(model.courseCode, 'CS301');
      expect(model.credits, 3);
      expect(model.courseType, 'required');
      expect(model.isRequired, true);
      expect(model.id, 5);
      expect(model.classCode, 'CS301-01');
      expect(model.room, 'A301');
      expect(model.schedule, 'T2 7:00-9:30');
      expect(model.maxStudents, 45);
      expect(model.enrolledCount, 30);
      expect(model.teacherName, 'TS. Nguyễn Văn A');
      expect(model.semesterName, 'HK2 2024-2025');
      expect(model.enrollmentId, 100);
      expect(model.enrollmentStatus, 'enrolled');
      expect(model.isEnrolled, true);
      expect(model.progressPercent, 65.5);
      expect(model.isCompleted, false);
      expect(model.isFull, false);
      expect(model.departmentName, 'Khoa CNTT');
    });

    test('handles missing optional fields gracefully', () {
      final json = {
        'course': {'id': 20, 'name': 'AI Cơ bản', 'code': 'AI101'},
        'courseClass': {'id': 8},
        'status': 'completed',
        'progressPercent': 100.0,
      };

      final model = CourseClassModel.fromMyCoursesJson(json);

      expect(model.courseId, 20);
      expect(model.courseName, 'AI Cơ bản');
      expect(model.classCode, '');
      expect(model.credits, 3); // default
      expect(model.courseType, 'required'); // default
      expect(model.teacherName, 'N/A'); // default
      expect(model.maxStudents, 50); // default
      expect(model.enrolledCount, 0); // default
      expect(model.enrollmentStatus, 'completed');
      expect(model.isCompleted, true);
      expect(model.room, isNull);
      expect(model.schedule, isNull);
      expect(model.semesterName, isNull);
    });

    test('toJson produces correct output', () {
      final json = {
        'course': {
          'id': 1,
          'name': 'Test',
          'code': 'T01',
          'credits': 2,
          'courseType': 'elective',
        },
        'courseClass': {
          'id': 1,
          'classCode': 'T01-01',
          'maxStudents': 30,
          'enrolledCount': 10,
        },
        'teacherName': 'GV Test',
      };

      final model = CourseClassModel.fromMyCoursesJson(json);
      final output = model.toJson();

      expect(output['courseName'], 'Test');
      expect(output['courseCode'], 'T01');
      expect(output['classCode'], 'T01-01');
      expect(output['credits'], 2);
      expect(output['courseType'], 'elective');
      expect(output['teacherName'], 'GV Test');
      expect(output['maxStudents'], 30);
      expect(output['enrolledCount'], 10);
    });
  });
}
