import 'package:backend/middleware/rbac_middleware.dart';
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(requireRole(Roles.student));
}
