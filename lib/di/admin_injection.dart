import 'package:get_it/get_it.dart';
import '../features/admin/data/repositories/admin_repository_impl.dart';
import '../features/admin/domain/repositories/admin_repository.dart';
import '../features/admin/domain/usecases/admin_usecases.dart' as admin_uc;
import '../features/admin/presentation/bloc/admin_bloc.dart';

void initAdminModule(GetIt sl) {
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(apiClient: sl()),
  );

  sl.registerLazySingleton(() => admin_uc.GetUsersUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.UpdateUserUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.DeleteUserUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.ToggleBanUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.GetAdminCoursesUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.TogglePublishUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.DeleteCourseUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.GetAnalyticsUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.SeedUsersUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.SeedAchievementsUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.SeedRoadmapUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.AssignRoadmapTeacherUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.ImportStudentsUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.ImportTeachersUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.ImportSubjectsUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.GetAcademicDataUseCase(sl()));
  sl.registerLazySingleton(
    () => admin_uc.GetAcademicCoursesWithTeachersUseCase(sl()),
  );
  sl.registerLazySingleton(() => admin_uc.AssignCourseTeacherUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.UnassignCourseTeacherUseCase(sl()));
  sl.registerLazySingleton(() => admin_uc.CreateCourseClassUseCase(sl()));

  sl.registerFactory(
    () => AdminBloc(
      getUsers: sl(),
      updateUser: sl(),
      deleteUser: sl(),
      toggleBan: sl(),
      getAdminCourses: sl(),
      togglePublish: sl(),
      deleteCourse: sl(),
      getAnalytics: sl(),
      seedUsers: sl(),
      seedAchievements: sl(),
      seedRoadmap: sl(),
      assignRoadmapTeacher: sl(),
      importStudents: sl(),
      importTeachers: sl(),
      importSubjects: sl(),
      getAcademicData: sl(),
      getAcademicCoursesWithTeachers: sl(),
      createCourseClassUseCase: sl(),
      assignCourseTeacherUseCase: sl(),
      unassignCourseTeacherUseCase: sl(),
    ),
  );
}
