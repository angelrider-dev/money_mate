import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/expense_providers.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final int? expenseId;
  const AddEditExpenseScreen({super.key, this.expenseId});

  @override
  ConsumerState<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _showMoreOptions = false;
  bool _makeRecurring = false;

  bool get _isEditing => widget.expenseId != null;

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    await ref.read(expenseRepositoryProvider).addExpense(
          amount: amount,
          title: _titleController.text.trim().isEmpty
              ? 'Expense'
              : _titleController.text.trim(),
          categoryId: _selectedCategoryId,
          date: _selectedDate,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'New Expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AMOUNT — primary input, large
          Center(
            child: Column(
              children: [
                Text('AMOUNT', style: AppTypography.labelMd),
                const SizedBox(height: 8),
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: AppTypography.numericXl,
                    decoration: const InputDecoration(
                      prefixText: '\$ ',
                      border: InputBorder.none,
                      filled: false,
                      hintText: '0.00',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // CATEGORY — icon grid
          Text('Category', style: AppTypography.titleMd),
          const SizedBox(height: 8),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading categories: $e'),
            data: (categories) => SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  final selected = _selectedCategoryId == cat.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: selected
                              ? AppColors.primary
                              : AppColors.surfaceContainerHigh,
                          child: Icon(Icons.category_outlined,
                              color: selected ? Colors.white : AppColors.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(cat.name, style: AppTypography.bodyMd),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // TITLE
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),

          // DATE
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Date'),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
            ),
          ),

          // NOTE
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 8),

          // ADD RECEIPT
          OutlinedButton.icon(
            onPressed: () {
              // image_picker integration wired up when Quick Add / receipt
              // handling is implemented.
            },
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Add Receipt'),
          ),
          const SizedBox(height: 16),

          // MORE OPTIONS — progressive disclosure (account picker, recurring)
          ExpansionTile(
            title: const Text('More Options'),
            initiallyExpanded: _showMoreOptions,
            onExpansionChanged: (v) => setState(() => _showMoreOptions = v),
            children: [
              SwitchListTile(
                title: const Text('Make this recurring'),
                value: _makeRecurring,
                onChanged: (v) => setState(() => _makeRecurring = v),
              ),
              if (_makeRecurring)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Frequency, end date, and auto-create options will appear here '
                    '(wired up with RecurringRuleRepository).',
                    style: AppTypography.bodyMd,
                  ),
                ),
              // Account picker only shown if multi-account is enabled —
              // wired up via multiAccountEnabledProvider when Accounts UI lands.
            ],
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _save,
            child: const Text('Save Expense'),
          ),
        ],
      ),
    );
  }
}
