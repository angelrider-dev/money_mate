import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../local/database.dart';

/// Single-row Users table access — see database.dart doc comment.
/// This is the ONLY place that writes to the Users table.
class UserRepository {
  final AppDatabase db;
  UserRepository(this.db);

  Stream<User?> watchUser() {
    return (db.select(db.users)..where((u) => u.id.equals(1))).watchSingleOrNull();
  }

  Future<User> getOrCreateUser() async {
    final existing =
        await (db.select(db.users)..where((u) => u.id.equals(1))).getSingleOrNull();
    if (existing != null) return existing;

    await db.into(db.users).insert(
          UsersCompanion.insert(name: const Value('Me'), currency: const Value('PKR')),
        );
    return (db.select(db.users)..where((u) => u.id.equals(1))).getSingle();
  }

  Future<void> updateProfile({String? name, String? avatarPath}) {
    return (db.update(db.users)..where((u) => u.id.equals(1))).write(
      UsersCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        avatarPath: avatarPath != null ? Value(avatarPath) : const Value.absent(),
      ),
    );
  }

  Future<void> updateCurrency(String currency) {
    return (db.update(db.users)..where((u) => u.id.equals(1)))
        .write(UsersCompanion(currency: Value(currency)));
  }

  String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<void> setAppLock({required bool enabled, String? pin, bool? biometricEnabled}) {
    return (db.update(db.users)..where((u) => u.id.equals(1))).write(
      UsersCompanion(
        appLockEnabled: Value(enabled),
        pinHash: pin != null ? Value(_hashPin(pin)) : const Value.absent(),
        biometricEnabled:
            biometricEnabled != null ? Value(biometricEnabled) : const Value.absent(),
      ),
    );
  }

  Future<bool> verifyPin(String pin) async {
    final user = await (db.select(db.users)..where((u) => u.id.equals(1))).getSingle();
    return user.pinHash == _hashPin(pin);
  }
}
