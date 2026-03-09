import 'package:equatable/equatable.dart';
import '../../domain/entities/enrollment_entity.dart';
import '../../domain/entities/course_class_entity.dart';

abstract class MyCoursesState extends Equatable {
  const MyCoursesState();

  @override
  List<Object?> get props => [];
}

class MyCoursesInitial extends MyCoursesState {}

class MyCoursesLoading extends MyCoursesState {}

class MyCoursesLoaded extends MyCoursesState {
  final List<EnrollmentEntity> enrollments;

  const MyCoursesLoaded(this.enrollments);

  @override
  List<Object?> get props => [enrollments];
}

class MyAcademicCoursesLoaded extends MyCoursesState {
  final List<CourseClassEntity> courseClasses;

  const MyAcademicCoursesLoaded(this.courseClasses);

  @override
  List<Object?> get props => [courseClasses];
}

class MyCoursesError extends MyCoursesState {
  final String message;

  const MyCoursesError(this.message);

  @override
  List<Object?> get props => [message];
}
