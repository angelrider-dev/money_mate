import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/database.dart';
import '../local/connection.dart';

/// Single shared AppDatabase instance for the entire app.
/// Every repository provider reads this instead of creating its own connection.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openConnection());
  ref.onDispose(() => db.close());
  return db;
});
