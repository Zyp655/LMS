import 'package:equatable/equatable.dart';

abstract class CourseDetailEvent extends Equatable {
  const CourseDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadCourseDetailEvent extends CourseDetailEvent {
  final int courseId;
  final int? userId; 

  const LoadCourseDetailEvent(this.courseId, {this.userId});

  @override
  List<Object?> get props => [courseId, userId];
}

class EnrollInCourseEvent extends CourseDetailEvent {
  final int userId;
  final int courseId;

  const EnrollInCourseEvent({required this.userId, required this.courseId});

  @override
  List<Object?> get props => [userId, courseId];
}

class CreateModuleEvent extends CourseDetailEvent {
  final int courseId;
  final String title;
  final String? description;

  const CreateModuleEvent({
    required this.courseId,
    required this.title,
    this.description,
  });

  @override
  List<Object?> get props => [courseId, title, description];
}

class CreateLessonEvent extends CourseDetailEvent {
  final int courseId;
  final int moduleId;
  final String title;
  final String type;
  final String? contentUrl;
  final String? textContent;
  final int? durationMinutes;

  const CreateLessonEvent({
    required this.courseId,
    required this.moduleId,
    required this.title,
    this.type = 'video',
    this.contentUrl,
    this.textContent,
    this.durationMinutes,
  });

  @override
  List<Object?> get props => [
    courseId,
    moduleId,
    title,
    type,
    contentUrl,
    textContent,
    durationMinutes,
  ];
}

class UpdateLessonEvent extends CourseDetailEvent {
  final int courseId;
  final int moduleId;
  final int lessonId;
  final String? title;
  final String? type;
  final String? contentUrl;
  final String? textContent;
  final int? durationMinutes;

  const UpdateLessonEvent({
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
    this.title,
    this.type,
    this.contentUrl,
    this.textContent,
    this.durationMinutes,
  });

  @override
  List<Object?> get props => [
    courseId,
    moduleId,
    lessonId,
    title,
    type,
    contentUrl,
    textContent,
    durationMinutes,
  ];
}

class DeleteLessonEvent extends CourseDetailEvent {
  final int courseId;
  final int moduleId;
  final int lessonId;

  const DeleteLessonEvent({
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
  });

  @override
  List<Object?> get props => [courseId, moduleId, lessonId];
}

class DeleteModuleEvent extends CourseDetailEvent {
  final int courseId;
  final int moduleId;

  const DeleteModuleEvent({
    required this.courseId,
    required this.moduleId,
  });

  @override
  List<Object?> get props => [courseId, moduleId];
}
