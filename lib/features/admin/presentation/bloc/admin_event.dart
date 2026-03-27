import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

class LoadUsers extends AdminEvent {
  final int? role;
  final String? search;
  final int? departmentId;
  final String? studentClass;
  const LoadUsers({
    this.role,
    this.search,
    this.departmentId,
    this.studentClass,
  });
  @override
  List<Object?> get props => [role, search, departmentId, studentClass];
}

class EditUser extends AdminEvent {
  final int userId;
  final Map<String, dynamic> data;
  const EditUser({required this.userId, required this.data});
  @override
  List<Object?> get props => [userId, data];
}

class DeleteUser extends AdminEvent {
  final int userId;
  const DeleteUser(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ToggleBan extends AdminEvent {
  final int userId;
  const ToggleBan(this.userId);
  @override
  List<Object?> get props => [userId];
}

class LoadAdminCourses extends AdminEvent {
  final String? search;
  const LoadAdminCourses({this.search});
  @override
  List<Object?> get props => [search];
}

class TogglePublish extends AdminEvent {
  final int courseId;
  final bool currentlyPublished;
  const TogglePublish({
    required this.courseId,
    required this.currentlyPublished,
  });
  @override
  List<Object?> get props => [courseId, currentlyPublished];
}

class DeleteCourse extends AdminEvent {
  final int courseId;
  const DeleteCourse(this.courseId);
  @override
  List<Object?> get props => [courseId];
}

class LoadAnalytics extends AdminEvent {}

class SeedUsers extends AdminEvent {}

class SeedAchievements extends AdminEvent {}

class SeedRoadmap extends AdminEvent {}

class SeedProgress extends AdminEvent {}

class AssignRoadmapTeacher extends AdminEvent {
  final String email;
  const AssignRoadmapTeacher(this.email);
  @override
  List<Object?> get props => [email];
}

class ImportStudents extends AdminEvent {
  final Map<String, dynamic> payload;
  const ImportStudents(this.payload);
  @override
  List<Object?> get props => [payload];
}

class ImportTeachers extends AdminEvent {
  final Map<String, dynamic> payload;
  const ImportTeachers(this.payload);
  @override
  List<Object?> get props => [payload];
}

class ImportSubjects extends AdminEvent {
  final Map<String, dynamic> payload;
  const ImportSubjects(this.payload);
  @override
  List<Object?> get props => [payload];
}

class LoadAcademicData extends AdminEvent {}

class LoadAcademicCoursesWithTeachers extends AdminEvent {}

class CreateCourseClassEvent extends AdminEvent {
  final int academicCourseId;
  final String classCode;
  final String? room;
  final String? schedule;
  final int? maxStudents;
  final int? dayOfWeek;
  final String? startDate;
  final String? endDate;
  const CreateCourseClassEvent({
    required this.academicCourseId,
    required this.classCode,
    this.room,
    this.schedule,
    this.maxStudents,
    this.dayOfWeek,
    this.startDate,
    this.endDate,
  });
  @override
  List<Object?> get props => [
    academicCourseId,
    classCode,
    room,
    schedule,
    maxStudents,
    dayOfWeek,
    startDate,
    endDate,
  ];
}

class AssignCourseTeacherEvent extends AdminEvent {
  final int courseClassId;
  final int teacherId;
  final bool force;
  const AssignCourseTeacherEvent({
    required this.courseClassId,
    required this.teacherId,
    this.force = false,
  });
  @override
  List<Object?> get props => [courseClassId, teacherId, force];
}

class UnassignCourseTeacherEvent extends AdminEvent {
  final int courseClassId;
  const UnassignCourseTeacherEvent({required this.courseClassId});
  @override
  List<Object?> get props => [courseClassId];
}

class DeleteCourseClassEvent extends AdminEvent {
  final int courseClassId;
  const DeleteCourseClassEvent({required this.courseClassId});
  @override
  List<Object?> get props => [courseClassId];
}
