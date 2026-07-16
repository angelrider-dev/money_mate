import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../data/providers/expense_providers.dart';

class SetBudgetScreen extends ConsumerStatefulWidget {
  final String month; // "2026-07"
  const SetBudgetScreen({super.key, required this.month});

  @override
  ConsumerState<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends ConsumerState<SetBudgetScreen> {
  final _limitController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final limit = double.tryParse(_limitController.text);
    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid limit amount')));
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a category')));
      return;
    }

    await ref.read(budgetRepositoryProvider).setBudget(
          categoryId: _selectedCategoryId!,
          limitAmount: limit,
          month: widget.month,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Set Budget')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('CATEGORY', style: AppTypography.labelMd),
          const SizedBox(height: 8),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (categories) => DropdownButtonFormField<int>(
              initialValue: _selectedCategoryId,
              hint: const Text('Select a category'),
              items: categories
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
          ),
          const SizedBox(height: 16),

          Text('MONTHLY LIMIT', style: AppTypography.labelMd),
          const SizedBox(height: 8),
          TextField(
            controller: _limitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: '\$ '),
          ),
          const SizedBox(height: 16),

          // Fixed alert thresholds per decision — no custom slider, no rollover.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Row(
              children: [
                Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You'll be notified at 80%, 90%, and 100% of this budget.",
                    style: AppTypography.bodyMd,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(onPressed: _save, child: const Text('Save Budget')),
        ],
      ),
    );
  }
}
