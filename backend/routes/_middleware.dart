import 'package:backend/database/database.dart';
import 'package:backend/middleware/auth_middleware.dart';
import 'package:backend/middleware/cors_middleware.dart';
import 'package:backend/middleware/error_handler_middleware.dart';
import 'package:backend/middleware/rate_limit_middleware.dart';
import 'package:backend/repositories/student_repository.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/services/course_service.dart';
import 'package:backend/services/cron_service.dart';
import 'package:backend/services/discussion_broadcaster.dart';
import 'package:dart_frog/dart_frog.dart';

final _db = AppDatabase();
final _discussionBroadcaster = DiscussionBroadcaster();
final _cronService = CronService(_db)..start();
final _studentRepo = StudentRepository(_db);
final _userRepo = UserRepository(_db);
final _courseService = CourseService(_db);

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(corsMiddleware())
      .use(errorHandlerMiddleware())
      .use(rateLimitMiddleware())
      .use(authMiddleware)
      .use(provider<AppDatabase>((_) => _db))
      .use(provider<StudentRepository>((_) => _studentRepo))
      .use(provider<UserRepository>((_) => _userRepo))
      .use(provider<CourseService>((_) => _courseService))
      .use(provider<CronService>((_) => _cronService))
      .use(provider<DiscussionBroadcaster>((_) => _discussionBroadcaster));
}
