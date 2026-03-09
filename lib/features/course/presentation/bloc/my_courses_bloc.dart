import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_my_courses_usecase.dart';
import '../../domain/repositories/course_repository.dart';
import 'my_courses_event.dart';
import 'my_courses_state.dart';

class MyCoursesBloc extends Bloc<MyCoursesEvent, MyCoursesState> {
  final GetMyCoursesUseCase getMyCoursesUseCase;
  final CourseRepository courseRepository;

  MyCoursesBloc({
    required this.getMyCoursesUseCase,
    required this.courseRepository,
  }) : super(MyCoursesInitial()) {
    on<LoadMyCoursesEvent>(_onLoadMyCourses);
    on<RefreshMyCoursesEvent>(_onRefreshMyCourses);
    on<LoadMyAcademicCoursesEvent>(_onLoadMyAcademicCourses);
  }

  Future<void> _onLoadMyCourses(
    LoadMyCoursesEvent event,
    Emitter<MyCoursesState> emit,
  ) async {
    emit(MyCoursesLoading());

    final result = await getMyCoursesUseCase(event.userId);

    result.fold(
      (failure) => emit(MyCoursesError(failure.message)),
      (enrollments) => emit(MyCoursesLoaded(enrollments)),
    );
  }

  Future<void> _onRefreshMyCourses(
    RefreshMyCoursesEvent event,
    Emitter<MyCoursesState> emit,
  ) async {
    final result = await getMyCoursesUseCase(event.userId);

    result.fold(
      (failure) => emit(MyCoursesError(failure.message)),
      (enrollments) => emit(MyCoursesLoaded(enrollments)),
    );
  }

  Future<void> _onLoadMyAcademicCourses(
    LoadMyAcademicCoursesEvent event,
    Emitter<MyCoursesState> emit,
  ) async {
    emit(MyCoursesLoading());

    final result = await courseRepository.getMyAcademicCourses(
      userId: event.userId,
      semesterId: event.semesterId,
      status: event.status,
    );

    result.fold(
      (failure) => emit(MyCoursesError(failure.message)),
      (courseClasses) => emit(MyAcademicCoursesLoaded(courseClasses)),
    );
  }
}
