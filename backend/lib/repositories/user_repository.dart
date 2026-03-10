import 'package:backend/database/database.dart';
import 'package:backend/utils/isolate_utils.dart';
import 'package:drift/drift.dart';

class UserRepository {
  final AppDatabase db;

  UserRepository(this.db);

  Future<User> createUser(
      {required String email, required String password}) async {
    final hashedPassword = await IsolateUtils.hashPassword(password);

    return await db.into(db.users).insertReturning(UsersCompanion.insert(
          email: email,
          passwordHash: hashedPassword,
        ));
  }

  Future<User?> getUserByEmail(String email) async {
    return await (db.select(db.users)..where((t) => t.email.equals(email)))
        .getSingleOrNull();
  }

  Future<bool> verifyPassword(String rawPassword, String hashedPassword) async {
    return IsolateUtils.checkPassword(rawPassword, hashedPassword);
  }

  Future<void> saveResetToken(String email, String token) async {
    final expiry = DateTime.now().add(Duration(minutes: 15));

    await (db.update(db.users)..where((t) => t.email.equals(email))).write(
      UsersCompanion(
        resetToken: Value(token),
        resetTokenExpiry: Value(expiry),
      ),
    );
  }
}
