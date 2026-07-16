import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/expense_providers.dart';
import '../../../data/local/database.dart';

/// Manage-only screen — deliberately shows NO spent/limit/progress data.
/// That tracking lives on the Budgets screen. See design.md for the
/// reasoning behind this separation (resolved after design review).
class CategoriesListScreen extends ConsumerWidget {
  const CategoriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage your expense categories',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/categories/add'),
                icon: const Icon(Icons.add),
                label: const Text('Add New Category'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Center(child: Text('No categories yet'));
                  }
                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, i) => _CategoryTile(category: categories[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color? swatch;
    try {
      swatch = Color(int.parse(category.colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      swatch = AppColors.surfaceContainerHigh;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/categories/edit/${category.id}'),
        leading: CircleAvatar(
          backgroundColor: swatch.withValues(alpha: 0.2),
          child: Icon(Icons.category_outlined, color: swatch),
        ),
        title: Text(category.name, style: AppTypography.bodyLg),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final repo = ref.read(categoryRepositoryProvider);
            if (value == 'edit') {
              context.push('/categories/edit/${category.id}');
            } else if (value == 'archive') {
              final inUse = await repo.isInUse(category.id);
              await repo.archive(category.id);
              if (context.mounted && inUse) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Category archived. Existing expenses keep this category.'),
                  ),
                );
              }
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'archive', child: Text('Archive')),
          ],
        ),
      ),
    );
  }
}
