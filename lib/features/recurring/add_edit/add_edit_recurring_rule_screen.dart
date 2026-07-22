import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../data/providers/expense_providers.dart';

class AddEditRecurringRuleScreen extends ConsumerStatefulWidget {
  const AddEditRecurringRuleScreen({super.key});

  @override
  ConsumerState<AddEditRecurringRuleScreen> createState() =>
      _AddEditRecurringRuleScreenState();
}

class _AddEditRecurringRuleScreenState extends ConsumerState<AddEditRecurringRuleScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'expense';
  int? _categoryId;
  int? _sourceId;
  String _frequency = 'monthly';
  DateTime _nextDueDate = DateTime.now();
  DateTime? _endDate;
  bool _autoCreate = true;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a title and amount')));
      return;
    }
    if (_type == 'income' && _sourceId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select an income source')));
      return;
    }

    await ref.read(recurringRuleRepositoryProvider).createRule(
          title: _titleController.text.trim(),
          amount: amount,
          type: _type,
          categoryId: _type == 'expense' ? _categoryId : null,
          sourceId: _type == 'income' ? _sourceId : null,
          frequency: _frequency,
          nextDueDate: _nextDueDate,
          endDate: _endDate,
          autoCreate: _autoCreate,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final sourcesAsync = ref.watch(activeIncomeSourcesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Recurring Rule')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Expense')),
              ButtonSegment(value: 'income', label: Text('Income')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
          ),
          const SizedBox(height: 16),

          if (_type == 'expense')
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (categories) => DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            )
          else
            sourcesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (sources) => DropdownButtonFormField<int>(
                initialValue: _sourceId,
                decoration: const InputDecoration(labelText: 'Source'),
                items: sources
                    .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (v) => setState(() => _sourceId = v),
              ),
            ),
          const SizedBox(height: 16),

          Text('Frequency', style: AppTypography.titleMd),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'daily', label: Text('Daily')),
              ButtonSegment(value: 'weekly', label: Text('Weekly')),
              ButtonSegment(value: 'monthly', label: Text('Monthly')),
              ButtonSegment(value: 'yearly', label: Text('Yearly')),
            ],
            selected: {_frequency},
            onSelectionChanged: (s) => setState(() => _frequency = s.first),
          ),
          const SizedBox(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Next Due Date'),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _nextDueDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _nextDueDate = picked);
              },
              child: Text('${_nextDueDate.day}/${_nextDueDate.month}/${_nextDueDate.year}'),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_busy_outlined),
            title: const Text('End Date (optional)'),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _nextDueDate.add(const Duration(days: 365)),
                  firstDate: _nextDueDate,
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
              child: Text(_endDate == null
                  ? 'Never'
                  : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
            ),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-create transaction'),
            subtitle: const Text('Off = just remind me instead'),
            value: _autoCreate,
            onChanged: (v) => setState(() => _autoCreate = v),
          ),
          const SizedBox(height: 24),

          ElevatedButton(onPressed: _save, child: const Text('Save Rule')),
        ],
      ),
    );
  }
}
