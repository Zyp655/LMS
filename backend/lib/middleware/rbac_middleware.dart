import 'package:dart_frog/dart_frog.dart';

abstract class Roles {
  static const int student = 0;
  static const int teacher = 1;
  static const int admin = 2;

  static String label(int role) {
    switch (role) {
      case student:
        return 'Student';
      case teacher:
        return 'Teacher';
      case admin:
        return 'Admin';
      default:
        return 'Unknown';
    }
  }
}

Middleware requireRole(int minRole) {
  return (handler) {
    return (context) async {
      try {
        final userRole = context.read<UserRole>();

        if (userRole.value < minRole) {
          return Response.json(
            statusCode: 403,
            body: {
              'error': 'Forbidden',
              'message':
                  'Bạn không có quyền truy cập. Yêu cầu: ${Roles.label(minRole)}.',
            },
          );
        }

        return handler(context);
      } catch (_) {
        return Response.json(
          statusCode: 403,
          body: {
            'error': 'Forbidden',
            'message': 'Không thể xác minh quyền truy cập.',
          },
        );
      }
    };
  };
}

class UserRole {
  const UserRole(this.value);
  final int value;

  bool get isStudent => value == Roles.student;
  bool get isTeacher => value >= Roles.teacher;
  bool get isAdmin => value >= Roles.admin;
}
