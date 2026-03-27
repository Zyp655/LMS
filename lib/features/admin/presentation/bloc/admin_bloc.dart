import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_event.dart';
import 'admin_state.dart';

export 'admin_event.dart';
export 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final GetUsersUseCase getUsers;
  final UpdateUserUseCase updateUser;
  final DeleteUserUseCase deleteUser;
  final ToggleBanUseCase toggleBan;
  final GetAdminCoursesUseCase getAdminCourses;
  final TogglePublishUseCase togglePublish;
  final DeleteCourseUseCase deleteCourse;
  final GetAnalyticsUseCase getAnalytics;
  final GetAcademicDataUseCase getAcademicData;
  final SeedUsersUseCase seedUsers;
  final SeedAchievementsUseCase seedAchievements;
  final SeedRoadmapUseCase seedRoadmap;
  final AssignRoadmapTeacherUseCase assignRoadmapTeacher;
  final ImportStudentsUseCase importStudents;
  final ImportTeachersUseCase importTeachers;
  final ImportSubjectsUseCase importSubjects;
  final GetAcademicCoursesWithTeachersUseCase getAcademicCoursesWithTeachers;
  final CreateCourseClassUseCase createCourseClassUseCase;
  final AssignCourseTeacherUseCase assignCourseTeacherUseCase;
  final UnassignCourseTeacherUseCase unassignCourseTeacherUseCase;
  final DeleteCourseClassUseCase deleteCourseClassUseCase;
  final SeedProgressUseCase seedProgressUseCase;

  AdminBloc({
    required this.getUsers,
    required this.updateUser,
    required this.deleteUser,
    required this.toggleBan,
    required this.getAdminCourses,
    required this.togglePublish,
    required this.deleteCourse,
    required this.getAnalytics,
    required this.getAcademicData,
    required this.seedUsers,
    required this.seedAchievements,
    required this.seedRoadmap,
    required this.assignRoadmapTeacher,
    required this.importStudents,
    required this.importTeachers,
    required this.importSubjects,
    required this.getAcademicCoursesWithTeachers,
    required this.createCourseClassUseCase,
    required this.assignCourseTeacherUseCase,
    required this.unassignCourseTeacherUseCase,
    required this.deleteCourseClassUseCase,
    required this.seedProgressUseCase,
  }) : super(AdminInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<EditUser>(_onEditUser);
    on<DeleteUser>(_onDeleteUser);
    on<ToggleBan>(_onToggleBan);
    on<LoadAdminCourses>(_onLoadCourses);
    on<TogglePublish>(_onTogglePublish);
    on<DeleteCourse>(_onDeleteCourse);
    on<LoadAnalytics>(_onLoadAnalytics);
    on<LoadAcademicData>(_onLoadAcademicData);
    on<SeedUsers>(_onSeedUsers);
    on<SeedAchievements>(_onSeedAchievements);
    on<SeedRoadmap>(_onSeedRoadmap);
    on<AssignRoadmapTeacher>(_onAssignRoadmapTeacher);
    on<ImportStudents>(_onImportStudents);
    on<ImportTeachers>(_onImportTeachers);
    on<ImportSubjects>(_onImportSubjects);
    on<LoadAcademicCoursesWithTeachers>(_onLoadAcademicCoursesWithTeachers);
    on<CreateCourseClassEvent>(_onCreateCourseClass);
    on<AssignCourseTeacherEvent>(_onAssignCourseTeacher);
    on<UnassignCourseTeacherEvent>(_onUnassignCourseTeacher);
    on<DeleteCourseClassEvent>(_onDeleteCourseClass);
    on<SeedProgress>(_onSeedProgress);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final result = await getUsers(
      role: event.role,
      search: event.search,
      departmentId: event.departmentId,
      studentClass: event.studentClass,
    );
    result.fold((failure) => emit(AdminError(failure.message)), (data) {
      final users = List<Map<String, dynamic>>.from(data['users'] ?? []);
      emit(UsersLoaded(users));
    });
  }

  Future<void> _onEditUser(EditUser event, Emitter<AdminState> emit) async {
    final result = await updateUser(event.userId, event.data);
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<AdminState> emit) async {
    final result = await deleteUser(event.userId);
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onToggleBan(ToggleBan event, Emitter<AdminState> emit) async {
    final result = await toggleBan(event.userId);
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onLoadCourses(
    LoadAdminCourses event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await getAdminCourses(search: event.search);
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (courses) => emit(AdminCoursesLoaded(courses)),
    );
  }

  Future<void> _onTogglePublish(
    TogglePublish event,
    Emitter<AdminState> emit,
  ) async {
    final result = await togglePublish(
      event.courseId,
      event.currentlyPublished,
    );
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onDeleteCourse(
    DeleteCourse event,
    Emitter<AdminState> emit,
  ) async {
    final result = await deleteCourse(event.courseId);
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onLoadAnalytics(
    LoadAnalytics event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await getAnalytics();
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (data) => emit(AnalyticsLoaded(data)),
    );
  }

  Future<void> _onLoadAcademicData(
    LoadAcademicData event,
    Emitter<AdminState> emit,
  ) async {
    final result = await getAcademicData();
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (data) => emit(
        AcademicDataLoaded(
          departments: List<Map<String, dynamic>>.from(
            data['departments'] ?? [],
          ),
          semesters: List<Map<String, dynamic>>.from(data['semesters'] ?? []),
          academicCourses: List<Map<String, dynamic>>.from(
            data['courses'] ?? [],
          ),
          courseClasses: List<Map<String, dynamic>>.from(data['classes'] ?? []),
        ),
      ),
    );
  }

  Future<void> _onSeedUsers(SeedUsers event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final result = await seedUsers();
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onSeedAchievements(
    SeedAchievements event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await seedAchievements();
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onSeedRoadmap(
    SeedRoadmap event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await seedRoadmap();
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onAssignRoadmapTeacher(
    AssignRoadmapTeacher event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await assignRoadmapTeacher(event.email);
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onImportStudents(
    ImportStudents event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await importStudents(event.payload);
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onImportTeachers(
    ImportTeachers event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await importTeachers(event.payload);
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onImportSubjects(
    ImportSubjects event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await importSubjects(event.payload);
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onLoadAcademicCoursesWithTeachers(
    LoadAcademicCoursesWithTeachers event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await getAcademicCoursesWithTeachers();
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (courses) => emit(AcademicCoursesWithTeachersLoaded(courses)),
    );
  }

  Future<void> _onCreateCourseClass(
    CreateCourseClassEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await createCourseClassUseCase(
      event.academicCourseId,
      event.classCode,
      room: event.room,
      schedule: event.schedule,
      maxStudents: event.maxStudents,
      dayOfWeek: event.dayOfWeek,
      startDate: event.startDate,
      endDate: event.endDate,
    );
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onAssignCourseTeacher(
    AssignCourseTeacherEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await assignCourseTeacherUseCase(
      event.courseClassId,
      event.teacherId,
      force: event.force,
    );
    result.fold((failure) => emit(AdminError(failure.message)), (data) {
      final success = data['success'] as bool? ?? false;
      final needConfirm = data['needConfirm'] as bool? ?? false;
      if (success) {
        emit(AdminActionSuccess(data['message'] as String? ?? 'Thành công'));
      } else if (needConfirm) {
        emit(
          AssignNeedConfirm(
            message: data['message'] as String? ?? '',
            courseClassId: event.courseClassId,
            newTeacherId: event.teacherId,
            currentTeacher: Map<String, dynamic>.from(
              data['currentTeacher'] ?? {},
            ),
          ),
        );
      } else {
        emit(AdminError(data['error'] as String? ?? 'Lỗi không xác định'));
      }
    });
  }

  Future<void> _onUnassignCourseTeacher(
    UnassignCourseTeacherEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await unassignCourseTeacherUseCase(event.courseClassId);
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onDeleteCourseClass(
    DeleteCourseClassEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await deleteCourseClassUseCase(event.courseClassId);
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }

  Future<void> _onSeedProgress(
    SeedProgress event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await seedProgressUseCase();
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (message) => emit(AdminActionSuccess(message)),
    );
  }
}
