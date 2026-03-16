import '../../domain/entities/course_class_entity.dart';

class CourseClassModel extends CourseClassEntity {
  const CourseClassModel({
    required super.id,
    required super.classCode,
    required super.courseName,
    required super.courseCode,
    required super.courseId,
    required super.credits,
    required super.courseType,
    required super.teacherName,
    super.room,
    super.schedule,
    super.dayOfWeek,
    super.startDate,
    super.endDate,
    required super.maxStudents,
    required super.enrolledCount,
    super.semesterName,
    super.departmentName,
    super.description,
    super.thumbnailUrl,
    super.moduleCount,
    super.enrollmentId,
    super.enrollmentStatus,
    super.progressPercent,
    super.enrolledAt,
    super.completedAt,
  });

  factory CourseClassModel.fromMyCoursesJson(Map<String, dynamic> json) {
    final course = json['course'] as Map<String, dynamic>? ?? {};
    final cls = json['courseClass'] as Map<String, dynamic>? ?? {};

    return CourseClassModel(
      id: (cls['id'] as int?) ?? 0,
      classCode: (cls['classCode'] as String?) ?? '',
      courseName: (course['name'] as String?) ?? '',
      courseCode: (course['code'] as String?) ?? '',
      courseId: (course['id'] as int?) ?? 0,
      credits: (course['credits'] as int?) ?? 3,
      courseType: (course['courseType'] as String?) ?? 'required',
      teacherName: (json['teacherName'] as String?) ?? 'N/A',
      room: cls['room'] as String?,
      schedule: cls['schedule'] as String?,
      dayOfWeek: cls['dayOfWeek'] as int?,
      startDate: cls['startDate'] != null
          ? DateTime.tryParse(cls['startDate'] as String)
          : null,
      endDate: cls['endDate'] != null
          ? DateTime.tryParse(cls['endDate'] as String)
          : null,
      maxStudents: (cls['maxStudents'] as int?) ?? 50,
      enrolledCount: (cls['enrolledCount'] as int?) ?? 0,
      semesterName: json['semesterName'] as String?,
      departmentName: course['departmentName'] as String?,
      description: course['description'] as String?,
      thumbnailUrl: course['thumbnailUrl'] as String?,
      moduleCount: course['moduleCount'] as int?,
      enrollmentId: json['enrollmentId'] as int?,
      enrollmentStatus: (json['status'] as String?) ?? 'enrolled',
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      enrolledAt: json['enrolledAt'] != null
          ? DateTime.parse(json['enrolledAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classCode': classCode,
      'courseName': courseName,
      'courseCode': courseCode,
      'courseId': courseId,
      'credits': credits,
      'courseType': courseType,
      'teacherName': teacherName,
      'room': room,
      'schedule': schedule,
      'maxStudents': maxStudents,
      'enrolledCount': enrolledCount,
      'semesterName': semesterName,
      'departmentName': departmentName,
      'enrollmentStatus': enrollmentStatus,
      'progressPercent': progressPercent,
    };
  }
}
