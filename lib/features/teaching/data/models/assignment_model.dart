import '../../domain/entities/assignment_entity.dart';

class AssignmentModel extends AssignmentEntity {
  const AssignmentModel({
    required super.id,
    required super.classId,
    required super.title,
    super.description,
    required super.dueDate,
    super.rewardPoints,
    required super.createdAt,
    super.totalStudents,
    super.completedStudents,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    return AssignmentModel(
      id: json['id'] as int,
      classId: json['classId'] as int? ?? 0,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: parseDate(json['dueDate']),
      rewardPoints: json['rewardPoints'] as int? ?? 0,
      createdAt: parseDate(json['createdAt']),
      totalStudents: json['totalStudents'] as int? ?? 0,
      completedStudents: json['completedStudents'] as int? ?? json['submittedCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'rewardPoints': rewardPoints,
      'createdAt': createdAt?.toIso8601String(),
      'totalStudents': totalStudents,
      'completedStudents': completedStudents,
    };
  }
}
