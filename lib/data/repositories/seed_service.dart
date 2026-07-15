import 'package:drift/drift.dart';
import '../local/database.dart';

/// Runs once on first app launch (call from main.dart after opening the DB).
/// Idempotent — safe to call every launch; it only inserts what's missing.
class SeedService {
  final AppDatabase db;
  SeedService(this.db);

  Future<void> seedIfNeeded() async {
    await _seedUser();
    await _seedDefaultAccount();
    await _seedDefaultCategories();
    await _seedDefaultIncomeSources();
  }

  /// Enforces the single-row Users table (id = 1).
  Future<void> _seedUser() async {
    final existing = await (db.select(db.users)
          ..where((u) => u.id.equals(1)))
        .getSingleOrNull();
    if (existing == null) {
      await db.into(db.users).insert(
            UsersCompanion.insert(name: const Value('Me'), currency: const Value('PKR')),
          );
    }
  }

  /// Hidden default account so Expenses/Income always have *an* accountId
  /// to point to, even while multi-account is disabled in Settings.
  Future<void> _seedDefaultAccount() async {
    final existing = await db.select(db.accounts).get();
    if (existing.isEmpty) {
      await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              name: 'Default',
              type: const Value('cash'),
            ),
          );
    }
  }

  Future<void> _seedDefaultCategories() async {
    final existing = await db.select(db.categories).get();
    if (existing.isNotEmpty) return;

    const defaults = [
      ('Food', 'restaurant', '#FF7043'),
      ('Transport', 'directions_car', '#42A5F5'),
      ('Shopping', 'shopping_bag', '#AB47BC'),
      ('Bills & Utilities', 'receipt', '#FFA726'),
      ('Medical', 'local_hospital', '#EF5350'),
      ('Entertainment', 'movie', '#26C6DA'),
      ('Rent & Housing', 'house', '#8D6E63'),
      ('Education', 'school', '#5C6BC0'),
      ('Travel', 'flight', '#29B6F6'),
      ('Groceries', 'local_grocery_store', '#66BB6A'),
      ('Other', 'category', '#78909C'),
    ];

    for (final (name, icon, color) in defaults) {
      await db.into(db.categories).insert(
            CategoriesCompanion.insert(name: name, icon: icon, colorHex: color),
          );
    }
  }

  Future<void> _seedDefaultIncomeSources() async {
    final existing = await db.select(db.incomeSources).get();
    if (existing.isNotEmpty) return;

    const defaults = [
      ('Salary', 'work_outline'),
      ('Freelance', 'laptop_mac'),
      ('Business', 'storefront'),
      ('Investments', 'trending_up'),
      ('Gifts', 'card_giftcard'),
      ('Other', 'more_horiz'),
    ];

    for (final (name, icon) in defaults) {
      await db
          .into(db.incomeSources)
          .insert(IncomeSourcesCompanion.insert(name: name, icon: icon));
    }
  }
}
