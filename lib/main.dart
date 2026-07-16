import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/database_provider.dart';
import 'data/repositories/seed_service.dart';

void main() {
  runApp(const ProviderScope(child: _AppBootstrap()));
}

/// Runs first-launch seeding (default user, account, categories, income
/// sources — see seed_service.dart) before showing the real app.
class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> {
  late final Future<void> _seedFuture;

  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);
    _seedFuture = SeedService(db).seedIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _seedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        return const MoneyMateApp();
      },
    );
  }
}

class MoneyMateApp extends StatelessWidget {
  const MoneyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MoneyMate',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
