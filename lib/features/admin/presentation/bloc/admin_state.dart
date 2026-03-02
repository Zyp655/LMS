import 'package:equatable/equatable.dart';

abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class UsersLoaded extends AdminState {
  final List<Map<String, dynamic>> users;
  const UsersLoaded(this.users);
  @override
  List<Object?> get props => [users];
}

class AdminCoursesLoaded extends AdminState {
  final List<Map<String, dynamic>> courses;
  const AdminCoursesLoaded(this.courses);
  @override
  List<Object?> get props => [courses];
}

class AnalyticsLoaded extends AdminState {
  final Map<String, dynamic> analytics;
  const AnalyticsLoaded(this.analytics);
  @override
  List<Object?> get props => [analytics];
}

class AdminActionSuccess extends AdminState {
  final String message;
  const AdminActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
  @override
  List<Object?> get props => [message];
}

class AcademicDataLoaded extends AdminState {
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> semesters;
  final List<Map<String, dynamic>> academicCourses;
  final List<Map<String, dynamic>> courseClasses;

  const AcademicDataLoaded({
    required this.departments,
    required this.semesters,
    required this.academicCourses,
    required this.courseClasses,
  });

  @override
  List<Object?> get props => [
    departments,
    semesters,
    academicCourses,
    courseClasses,
  ];
}

class AcademicCoursesWithTeachersLoaded extends AdminState {
  final List<Map<String, dynamic>> courses;
  const AcademicCoursesWithTeachersLoaded(this.courses);
  @override
  List<Object?> get props => [courses];
}

class AssignNeedConfirm extends AdminState {
  final String message;
  final int courseClassId;
  final int newTeacherId;
  final Map<String, dynamic> currentTeacher;
  const AssignNeedConfirm({
    required this.message,
    required this.courseClassId,
    required this.newTeacherId,
    required this.currentTeacher,
  });
  @override
  List<Object?> get props => [
    message,
    courseClassId,
    newTeacherId,
    currentTeacher,
  ];
}
