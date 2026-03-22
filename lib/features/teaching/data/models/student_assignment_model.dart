import '../../domain/entities/student_assignment_entity.dart';

class StudentAssignmentModel extends StudentAssignmentEntity {
  const StudentAssignmentModel({
    required super.id,
    required super.studentAssignmentId,
    required super.title,
    super.description,
    required super.dueDate,
    required super.rewardPoints,
    required super.createdAt,
    required super.isCompleted,
    super.completedAt,
    required super.rewardClaimed,
    super.className,
    required super.classId,
    super.moduleId,
    super.moduleName,
    super.courseId,
    super.courseName,
    super.submissionStatus,
    super.grade,
    super.maxGrade,
    super.feedback,
  });

  factory StudentAssignmentModel.fromJson(Map<String, dynamic> json) {
    return StudentAssignmentModel(
      id: json['id'] as int,
      studentAssignmentId: json['studentAssignmentId'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['dueDate'] as String),
      rewardPoints: json['rewardPoints'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      rewardClaimed: json['rewardClaimed'] as bool? ?? false,
      className: json['className'] as String?,
      classId: json['classId'] as int,
      moduleId: json['moduleId'] as int?,
      moduleName: json['moduleName'] as String?,
      courseId: json['courseId'] as int?,
      courseName: json['courseName'] as String?,
      submissionStatus: json['submissionStatus'] as String?,
      grade: json['grade'] as num?,
      maxGrade: json['maxGrade'] as num?,
      feedback: json['feedback'] as String?,
    );
  }
}
