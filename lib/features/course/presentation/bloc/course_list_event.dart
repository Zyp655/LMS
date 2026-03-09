import 'package:equatable/equatable.dart';

abstract class CourseListEvent extends Equatable {
  const CourseListEvent();

  @override
  List<Object?> get props => [];
}

class LoadCoursesEvent extends CourseListEvent {
  final String? search;
  final int? departmentId;
  final String? courseType;

  const LoadCoursesEvent({this.search, this.departmentId, this.courseType});

  @override
  List<Object?> get props => [search, departmentId, courseType];
}

class RefreshCoursesEvent extends CourseListEvent {}

class CreateCourseEvent extends CourseListEvent {
  final String name;
  final String code;
  final int credits;
  final String? description;
  final String courseType;

  const CreateCourseEvent({
    required this.name,
    required this.code,
    required this.credits,
    this.description,
    this.courseType = 'required',
  });

  @override
  List<Object?> get props => [name, code, credits, description, courseType];
}

class DeleteCourseEvent extends CourseListEvent {
  final int courseId;

  const DeleteCourseEvent(this.courseId);

  @override
  List<Object?> get props => [courseId];
}
