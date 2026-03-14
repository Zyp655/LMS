import 'package:get_it/get_it.dart';

import 'core_injection.dart';
import 'auth_injection.dart';
import 'schedule_injection.dart';
import 'teaching_injection.dart';
import 'course_injection.dart';
import 'student_injection.dart';
import 'user_injection.dart';
import 'notification_injection.dart';
import 'task_injection.dart';
import 'roadmap_injection.dart';
import 'quiz_injection.dart';
import 'analytics_injection.dart';
import 'discussion_injection.dart';
import 'chat_injection.dart';
import 'search_injection.dart';
import 'profile_injection.dart';

import 'admin_injection.dart';

final sl = GetIt.instance;

Future<void> init() async {
  await initCoreModule(sl);

  initAuthModule(sl);
  initScheduleModule(sl);
  initTeachingModule(sl);
  initCourseModule(sl);
  initStudentModule(sl);
  initUserModule(sl);
  initNotificationModule(sl);
  initTaskModule(sl);
  initRoadmapModule(sl);
  initQuizModule(sl);
  initAnalyticsModule(sl);
  initDiscussionModule(sl);
  initChatModule(sl);
  initSearchModule(sl);
  initProfileModule(sl);

  initAdminModule(sl);
}
