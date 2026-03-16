import 'package:equatable/equatable.dart';

class CourseClassEntity extends Equatable {
  final int id;
  final String classCode;
  final String courseName;
  final String courseCode;
  final int courseId;
  final int credits;
  final String courseType;
  final String teacherName;
  final String? room;
  final String? schedule;
  final int? dayOfWeek;
  final DateTime? startDate;
  final DateTime? endDate;
  final int maxStudents;
  final int enrolledCount;
  final String? semesterName;
  final String? departmentName;
  final String? description;
  final String? thumbnailUrl;
  final int? moduleCount;

  final int? enrollmentId;
  final String? enrollmentStatus;
  final double progressPercent;
  final DateTime? enrolledAt;
  final DateTime? completedAt;

  const CourseClassEntity({
    required this.id,
    required this.classCode,
    required this.courseName,
    required this.courseCode,
    required this.courseId,
    required this.credits,
    required this.courseType,
    required this.teacherName,
    this.room,
    this.schedule,
    this.dayOfWeek,
    this.startDate,
    this.endDate,
    required this.maxStudents,
    required this.enrolledCount,
    this.semesterName,
    this.departmentName,
    this.description,
    this.thumbnailUrl,
    this.moduleCount,
    this.enrollmentId,
    this.enrollmentStatus,
    this.progressPercent = 0.0,
    this.enrolledAt,
    this.completedAt,
  });

  bool get isRequired => courseType == 'required';
  bool get isEnrolled => enrollmentStatus == 'enrolled';
  bool get isCompleted =>
      enrollmentStatus == 'completed' || progressPercent >= 100;
  bool get isFull => enrolledCount >= maxStudents;

  String? get scheduleLabel {
    if (dayOfWeek != null) {
      final dayNames = {2: 'Thứ 2', 3: 'Thứ 3', 4: 'Thứ 4', 5: 'Thứ 5', 6: 'Thứ 6', 7: 'Thứ 7', 8: 'CN'};
      final parts = <String>[dayNames[dayOfWeek] ?? 'T$dayOfWeek'];
      if (startDate != null) parts.add('${startDate!.day}/${startDate!.month}/${startDate!.year}');
      if (endDate != null) parts.add('→ ${endDate!.day}/${endDate!.month}/${endDate!.year}');
      return parts.join(' ');
    }
    return schedule;
  }

  factory CourseClassEntity.fromCourseEntity(dynamic course) {
    return CourseClassEntity(
      id: 0,
      classCode: course.code ?? '',
      courseName: course.name ?? '',
      courseCode: course.code ?? '',
      courseId: course.id,
      credits: course.credits ?? 0,
      courseType: course.courseType ?? 'required',
      teacherName: '',
      maxStudents: 0,
      enrolledCount: 0,
      departmentName: course.departmentName,
      description: course.description,
      thumbnailUrl: course.thumbnailUrl,
      moduleCount: course.moduleCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    classCode,
    courseName,
    courseCode,
    courseId,
    credits,
    courseType,
    teacherName,
    room,
    schedule,
    dayOfWeek,
    startDate,
    endDate,
    maxStudents,
    enrolledCount,
    semesterName,
    departmentName,
    enrollmentId,
    enrollmentStatus,
    progressPercent,
  ];
}
