import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../injection_container.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/admin/presentation/pages/admin_home_page.dart';
import '../../features/home/presentation/pages/main_wrapper_page.dart';
import '../../features/teaching/presentation/pages/teacher_home_page.dart';
import '../../features/course/presentation/pages/course_catalog_page.dart';
import '../../features/course/presentation/pages/course_detail_page.dart';
import '../../features/course/presentation/pages/lesson_player_page.dart';
import '../../features/course/presentation/pages/my_courses_page.dart';
import '../../features/course/presentation/bloc/course_list_bloc.dart';
import '../../features/course/domain/entities/lesson_entity.dart';
import '../../features/course/domain/entities/module_entity.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/chat/presentation/pages/conversations_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/search/presentation/pages/global_search_page.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../features/quiz/presentation/pages/generate_quiz_page.dart';
import '../../features/quiz/presentation/pages/take_quiz_page.dart';
import '../../features/quiz/presentation/pages/quiz_result_page.dart';
import '../../features/quiz/presentation/pages/my_quizzes_page.dart';
import '../../features/quiz/presentation/pages/quiz_statistics_page.dart';
import '../../features/quiz/presentation/pages/leaderboard_page.dart';
import '../../features/quiz/presentation/pages/multiplayer_lobby_page.dart';
import '../../features/quiz/presentation/pages/multiplayer_game_page.dart';
import '../../features/quiz/presentation/bloc/quiz_bloc.dart';
import '../../features/quiz/presentation/bloc/leaderboard/leaderboard_bloc.dart';
import '../../features/quiz/presentation/bloc/multiplayer/multiplayer_bloc.dart';
import '../../features/quiz/domain/entities/quiz_entity.dart';
import '../../features/analytics/presentation/pages/analytics_dashboard_page.dart';
import '../../features/analytics/presentation/bloc/analytics_bloc.dart';
import '../../features/discussion/presentation/pages/discussion_list_page.dart';
import '../../features/discussion/presentation/pages/discussion_thread_page.dart';
import '../../features/discussion/presentation/bloc/discussion_bloc.dart';
import '../../features/profile/presentation/pages/achievements_page.dart';
import '../../features/profile/presentation/bloc/achievement_bloc.dart';
import '../../features/offline/presentation/pages/offline_management_page.dart';
import '../../features/offline/presentation/bloc/offline_bloc.dart';
import '../../features/user/presentation/pages/teacher_applications_admin_page.dart';
import '../../features/admin/presentation/pages/academic_structure_page.dart';
import '../../features/admin/presentation/bloc/admin_bloc.dart';
import '../../features/course/presentation/pages/enrollment_import_page.dart';
import '../../features/admin/presentation/pages/student_import_page.dart';
import '../../features/admin/presentation/pages/teacher_import_page.dart';
import '../../features/admin/presentation/pages/subject_import_page.dart';
import '../../features/roadmap/presentation/pages/path_detail_page.dart';
import '../../features/roadmap/data/learning_paths_data.dart';

import 'app_route.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Lỗi')),
    body: const Center(child: Text('Không tìm thấy trang này!')),
  ),
  routes: [
    GoRoute(path: AppRoutes.login, builder: (context, state) => LoginPage()),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => ForgotPasswordPage(),
    ),

    GoRoute(
      path: AppRoutes.adminHome,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<AdminBloc>(),
        child: const AdminHomePage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.teacherApplications,
      builder: (context, state) => const TeacherApplicationsAdminPage(),
    ),
    GoRoute(
      path: AppRoutes.academicStructure,
      builder: (context, state) => const AcademicStructurePage(),
    ),
    GoRoute(
      path: AppRoutes.enrollmentImport,
      builder: (context, state) => const EnrollmentImportPage(),
    ),
    GoRoute(
      path: AppRoutes.studentImport,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<AdminBloc>(),
        child: const StudentImportPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.teacherImport,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<AdminBloc>(),
        child: const TeacherImportPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.subjectImport,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<AdminBloc>(),
        child: const SubjectImportPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.studentHome,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<OfflineBloc>(),
        child: const MainWrapperPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.schedule,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<OfflineBloc>(),
        child: const MainWrapperPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.teacherHome,
      builder: (context, state) => const TeacherHomePage(),
    ),

    GoRoute(
      path: AppRoutes.courseCatalog,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<CourseListBloc>(),
        child: const CourseCatalogPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.courseDetail,
      builder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);
        return CourseDetailPage(courseId: courseId);
      },
    ),
    GoRoute(
      path: AppRoutes.lessonPlayer,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return LessonPlayerPage(
          lesson: args['lesson'] as LessonEntity,
          userId: args['userId'] as int,
          startPosition: args['startPosition'] as int?,
          previousLesson: args['previousLesson'] as LessonEntity?,
          nextLesson: args['nextLesson'] as LessonEntity?,
          allModules: args['allModules'] as List<ModuleEntity>?,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.myCourses,
      builder: (context, state) {
        final userId = state.extra as int;
        return MyCoursesPage(userId: userId);
      },
    ),
    GoRoute(
      path: AppRoutes.pathDetail,
      builder: (context, state) {
        final path = state.extra as LearningPath;
        return PathDetailPage(path: path);
      },
    ),

    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<NotificationBloc>(),
        child: const NotificationsPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.conversations,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<ChatBloc>(),
        child: const ConversationsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.chatRoom,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return BlocProvider(
          create: (_) => sl<ChatBloc>(),
          child: ChatRoomPage(
            conversationId: args['conversationId'] as int,
            participantName: args['participantName'] as String,
            isTeacher: args['isTeacher'] as bool? ?? false,
          ),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.globalSearch,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<SearchBloc>(),
        child: const GlobalSearchPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.generateQuiz,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        return GenerateQuizPage(
          isForMultiplayer: args?['isForMultiplayer'] as bool? ?? false,
          videoUrl: args?['videoUrl'] as String?,
          lessonTitle: args?['lessonTitle'] as String?,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.takeQuiz,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return BlocProvider(
          create: (_) => sl<QuizBloc>(),
          child: TakeQuizPage(quiz: args['quiz']),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.quizResult,
      builder: (context, state) {
        final result = state.extra as QuizResultEntity;
        return QuizResultPage(result: result);
      },
    ),
    GoRoute(
      path: AppRoutes.myQuizzes,
      builder: (context, state) {
        final userId = state.extra as int;
        return BlocProvider(
          create: (_) => sl<QuizBloc>(),
          child: MyQuizzesPage(userId: userId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.quizStatistics,
      builder: (context, state) {
        final userId = state.extra as int;
        return BlocProvider(
          create: (_) => sl<QuizBloc>(),
          child: QuizStatisticsPage(userId: userId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.leaderboard,
      builder: (context, state) {
        final classId = state.extra as int;
        return BlocProvider(
          create: (_) => sl<LeaderboardBloc>(),
          child: LeaderboardPage(classId: classId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.multiplayerLobby,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<MultiplayerBloc>(),
        child: const MultiplayerLobbyPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.multiplayerGame,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<MultiplayerBloc>(),
        child: const MultiplayerGamePage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.analytics,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return BlocProvider(
          create: (_) => sl<AnalyticsBloc>(),
          child: AnalyticsDashboardPage(
            userId: args['userId'] as int,
            courseId: args['courseId'] as int?,
          ),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.discussions,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return BlocProvider(
          create: (_) => sl<DiscussionBloc>(),
          child: DiscussionListPage(
            courseId: args['courseId'] as int,
            courseTitle: args['courseTitle'] as String,
            lessonIds: args['lessonIds'] as List<int>,
            userId: args['userId'] as int? ?? 0,
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.discussionThread,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return BlocProvider(
          create: (_) => sl<DiscussionBloc>(),
          child: DiscussionThreadPage(
            lessonId: args['lessonId'] as int,
            userId: args['userId'] as int,
            lessonTitle: args['lessonTitle'] as String,
          ),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.achievements,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<AchievementBloc>(),
        child: const AchievementsPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.offlineManagement,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<OfflineBloc>(),
        child: const OfflineManagementPage(),
      ),
    ),
  ],
);
