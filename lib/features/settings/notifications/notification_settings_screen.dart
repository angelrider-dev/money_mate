import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/database_provider.dart';
import '../../../data/local/database.dart';
import 'package:drift/drift.dart';

// Simple key-value settings backed by AppSettings table.
final _dailyReminderProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final row = await (db.select(db.appSettings)
        ..where((s) => s.key.equals('notif_daily_reminder')))
      .getSingleOrNull();
  return row?.value == 'true';
});

final _budgetAlertsProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final row = await (db.select(db.appSettings)
        ..where((s) => s.key.equals('notif_budget_alerts')))
      .getSingleOrNull();
  return (row?.value ?? 'true') == 'true'; // on by default
});

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _setFlag(WidgetRef ref, String key, bool value) async {
    final db = ref.read(databaseProvider);
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value ? 'true' : 'false'),
        );
    ref.invalidate(_dailyReminderProvider);
    ref.invalidate(_budgetAlertsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyReminder = ref.watch(_dailyReminderProvider);
    final budgetAlerts = ref.watch(_budgetAlertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          dailyReminder.when(
            data: (value) => SwitchListTile(
              title: const Text('Daily reminder'),
              subtitle: const Text('Remind me to log expenses each day'),
              value: value,
              onChanged: (v) => _setFlag(ref, 'notif_daily_reminder', v),
            ),
            loading: () => const ListTile(title: Text('Daily reminder')),
            error: (e, _) => ListTile(title: Text('Error: $e')),
          ),
          budgetAlerts.when(
            data: (value) => SwitchListTile(
              title: const Text('Budget alerts'),
              subtitle: const Text('Notify at 80%, 90%, and 100% of a budget'),
              value: value,
              onChanged: (v) => _setFlag(ref, 'notif_budget_alerts', v),
            ),
            loading: () => const ListTile(title: Text('Budget alerts')),
            error: (e, _) => ListTile(title: Text('Error: $e')),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Note: actual push notifications are wired up in a later phase — '
              'these toggles save your preference now so nothing is lost.',
              style: AppTypography.bodyMd,
            ),
          ),
        ],
      ),
    );
  }
}
