import 'dart:isolate';
import 'package:bcrypt/bcrypt.dart';

class IsolateUtils {
  static Future<String> hashPassword(String password) async {
    return Isolate.run(() => BCrypt.hashpw(password, BCrypt.gensalt()));
  }

  static Future<bool> checkPassword(String raw, String hashed) async {
    return Isolate.run(() {
      var h = hashed;
      h = h.replaceAll(r'\$', r'$');
      if (h.startsWith(r'$2a$')) {
        h = h.replaceFirst(r'$2a$', r'$2b$');
      } else if (!h.startsWith(r'$2b$') && !h.startsWith(r'$2y$')) {
        if (h.startsWith(r'$10$')) {
          h = '\$2b\$10\$${h.substring(4)}';
        }
      }
      return BCrypt.checkpw(raw, h);
    });
  }
}
