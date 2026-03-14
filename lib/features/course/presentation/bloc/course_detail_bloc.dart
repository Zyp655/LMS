import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_course_details_usecase.dart';
import '../../domain/usecases/get_course_curriculum_usecase.dart';
import '../../domain/usecases/enroll_course_usecase.dart';
import '../../domain/usecases/get_my_courses_usecase.dart';
import '../../domain/usecases/create_module_usecase.dart';
import '../../domain/usecases/create_lesson_usecase.dart';
import 'course_detail_event.dart';
import 'course_detail_state.dart';
import '../../domain/entities/module_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/enrollment_entity.dart';
import '../../domain/usecases/update_lesson_usecase.dart';
import '../../domain/usecases/delete_lesson_usecase.dart';
import '../../../../core/api/api_client.dart';
import '../../../../injection_container.dart';

class CourseDetailBloc extends Bloc<CourseDetailEvent, CourseDetailState> {
  final GetCourseDetailsUseCase getCourseDetailsUseCase;
  final GetCourseCurriculumUseCase getCourseCurriculumUseCase;
  final EnrollCourseUseCase enrollCourseUseCase;
  final GetMyCoursesUseCase getMyCoursesUseCase;
  final CreateModuleUseCase createModuleUseCase;

  final CreateLessonUseCase createLessonUseCase;
  final UpdateLessonUseCase updateLessonUseCase;
  final DeleteLessonUseCase deleteLessonUseCase;

  CourseDetailBloc({
    required this.getCourseDetailsUseCase,
    required this.getCourseCurriculumUseCase,
    required this.enrollCourseUseCase,
    required this.getMyCoursesUseCase,
    required this.createModuleUseCase,

    required this.createLessonUseCase,
    required this.updateLessonUseCase,
    required this.deleteLessonUseCase,
  }) : super(CourseDetailInitial()) {
    on<LoadCourseDetailEvent>(_onLoadCourseDetail);
    on<EnrollInCourseEvent>(_onEnrollInCourse);
    on<CreateModuleEvent>(_onCreateModule);
    on<CreateLessonEvent>(_onCreateLesson);
    on<UpdateLessonEvent>(_onUpdateLesson);
    on<DeleteLessonEvent>(_onDeleteLesson);
    on<DeleteModuleEvent>(_onDeleteModule);
  }

  Future<void> _onLoadCourseDetail(
    LoadCourseDetailEvent event,
    Emitter<CourseDetailState> emit,
  ) async {
    emit(CourseDetailLoading());

    final courseResult = await getCourseDetailsUseCase(
      event.courseId,
      userId: event.userId,
    );
    final curriculumResult = await getCourseCurriculumUseCase(event.courseId);

    await courseResult.fold(
      (failure) async => emit(CourseDetailError(failure.message)),
      (course) async {
        await curriculumResult.fold(
          (failure) async => emit(CourseDetailError(failure.message)),
          (modules) async {
            EnrollmentEntity? enrollment;
            if (event.userId != null) {
              try {
                final api = sl<ApiClient>();
                final data = await api.get(
                  '/academic/courses/${event.courseId}?userId=${event.userId}',
                );
                final enrollmentData = data['enrollment'];
                if (enrollmentData != null) {
                  enrollment = EnrollmentEntity(
                    id: enrollmentData['id'] as int,
                    userId: event.userId!,
                    courseId: event.courseId,
                    progressPercent:
                        (enrollmentData['progressPercent'] as num?)?.toDouble() ?? 0.0,
                    enrolledAt: DateTime.parse(
                      enrollmentData['enrolledAt'] as String,
                    ),
                  );
                }
              } catch (_) {
              }
            }
            emit(
              CourseDetailLoaded(
                course: course,
                modules: modules,
                enrollment: enrollment,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onEnrollInCourse(
    EnrollInCourseEvent event,
    Emitter<CourseDetailState> emit,
  ) async {
    if (state is CourseDetailLoaded) {
      final currentState = state as CourseDetailLoaded;

      final result = await enrollCourseUseCase(
        userId: event.userId,
        courseId: event.courseId,
      );

      await result.fold(
        (failure) async {
          if (failure.message.contains('đã đăng ký') ||
              failure.message.contains('already enrolled')) {
            final enrollmentsResult = await getMyCoursesUseCase(event.userId);
            enrollmentsResult.fold(
              (e) => emit(currentState.copyWith(actionError: failure.message)),
              (enrollments) {
                final enrollment = enrollments
                    .where((e) => e.courseId == event.courseId)
                    .firstOrNull;
                if (enrollment != null) {
                  emit(
                    currentState.copyWith(
                      enrollment: enrollment,
                      actionError: failure.message,
                    ),
                  );
                } else {
                  emit(currentState.copyWith(actionError: failure.message));
                }
              },
            );
          } else {
            emit(currentState.copyWith(actionError: failure.message));
          }
        },
        (enrollment) async {
          emit(
            currentState.copyWith(enrollment: enrollment, isJustEnrolled: true),
          );
        },
      );
    }
  }

  Future<void> _onCreateModule(
    CreateModuleEvent event,
    Emitter<CourseDetailState> emit,
  ) async {
    final result = await createModuleUseCase(
      CreateModuleParams(
        courseId: event.courseId,
        title: event.title,
        description: event.description,
      ),
    );

    result.fold((failure) => emit(CourseDetailError(failure.message)), (
      module,
    ) {
      if (state is CourseDetailLoaded) {
        final currentState = state as CourseDetailLoaded;
        final updatedModules = List<ModuleEntity>.from(currentState.modules)
          ..add(module);
        emit(currentState.copyWith(modules: updatedModules));
      }
    });
  }

  Future<void> _onCreateLesson(
    CreateLessonEvent event,
    Emitter<CourseDetailState> emit,
  ) async {
    final result = await createLessonUseCase(
      CreateLessonParams(
        moduleId: event.moduleId,
        title: event.title,
        type: event.type,
        contentUrl: event.contentUrl,
        textContent: event.textContent,
        durationMinutes: event.durationMinutes,
      ),
    );

    result.fold((failure) => emit(CourseDetailError(failure.message)), (
      lesson,
    ) {
      if (state is CourseDetailLoaded) {
        final currentState = state as CourseDetailLoaded;
        final updatedModules = currentState.modules.map((module) {
          if (module.id == event.moduleId) {
            final updatedLessons = List<LessonEntity>.from(module.lessons ?? [])
              ..add(lesson);
            return ModuleEntity(
              id: module.id,
              courseId: module.courseId,
              title: module.title,
              description: module.description,
              orderIndex: module.orderIndex,
              lessons: updatedLessons,
              createdAt: module.createdAt,
            );
          }
          return module;
        }).toList();
        emit(currentState.copyWith(modules: updatedModules));
      }
    });
  }

  Future<void> _onUpdateLesson(
    UpdateLessonEvent event,
    Emitter<CourseDetailState> emit,
  ) async {
    final result = await updateLessonUseCase(
      UpdateLessonParams(
        courseId: event.courseId,
        moduleId: event.moduleId,
        lessonId: event.lessonId,
        title: event.title,
        type: event.type,
        contentUrl: event.contentUrl,
        textContent: event.textContent,
        durationMinutes: event.durationMinutes,
      ),
    );

    result.fold((failure) => emit(CourseDetailError(failure.message)), (_) {
      if (state is CourseDetailLoaded) {
        final currentState = state as CourseDetailLoaded;
        final updatedModules = currentState.modules.map((module) {
          if (module.id == event.moduleId) {
            final updatedLessons = module.lessons!.map((lesson) {
              if (lesson.id == event.lessonId) {
                return LessonEntity(
                  id: lesson.id,
                  moduleId: lesson.moduleId,
                  title: event.title ?? lesson.title,
                  type: event.type != null
                      ? (event.type == 'video'
                            ? LessonType.video
                            : (event.type == 'document'
                                  ? LessonType.text
                                  : LessonType.video)) 
                      : lesson.type,
                  contentUrl: event.contentUrl ?? lesson.contentUrl,
                  textContent: event.textContent ?? lesson.textContent,
                  durationMinutes:
                      event.durationMinutes ?? lesson.durationMinutes,
                  isFreePreview: lesson.isFreePreview, 
                  orderIndex: lesson.orderIndex,
                  createdAt: lesson.createdAt,
                );
              }
              return lesson;
            }).toList();

            return ModuleEntity(
              id: module.id,
              courseId: module.courseId,
              title: module.title,
              description: module.description,
              orderIndex: module.orderIndex,
              lessons: updatedLessons,
              createdAt: module.createdAt,
            );
          }
          return module;
        }).toList();

        emit(currentState.copyWith(modules: updatedModules));
      }
    });
  }

  Future<void> _onDeleteLesson(
    DeleteLessonEvent event,
    Emitter<CourseDetailState> emit,
  ) async {
    final result = await deleteLessonUseCase(
      DeleteLessonParams(
        courseId: event.courseId,
        moduleId: event.moduleId,
        lessonId: event.lessonId,
      ),
    );

    result.fold((failure) => emit(CourseDetailError(failure.message)), (_) {
      if (state is CourseDetailLoaded) {
        final currentState = state as CourseDetailLoaded;
        final updatedModules = currentState.modules.map((module) {
          if (module.id == event.moduleId) {
            final updatedLessons = module.lessons!
                .where((lesson) => lesson.id != event.lessonId)
                .toList();

            return ModuleEntity(
              id: module.id,
              courseId: module.courseId,
              title: module.title,
              description: module.description,
              orderIndex: module.orderIndex,
              lessons: updatedLessons,
              createdAt: module.createdAt,
            );
          }
          return module;
        }).toList();

        emit(currentState.copyWith(modules: updatedModules));
      }
    });
  }

  Future<void> _onDeleteModule(
    DeleteModuleEvent event,
    Emitter<CourseDetailState> emit,
  ) async {
    try {
      final api = sl<ApiClient>();
      await api.delete('/courses/${event.courseId}/modules/${event.moduleId}');
      if (state is CourseDetailLoaded) {
        final currentState = state as CourseDetailLoaded;
        final updatedModules = currentState.modules
            .where((m) => m.id != event.moduleId)
            .toList();
        emit(currentState.copyWith(modules: updatedModules));
      }
    } catch (e) {
      emit(CourseDetailError(e.toString()));
    }
  }
}
