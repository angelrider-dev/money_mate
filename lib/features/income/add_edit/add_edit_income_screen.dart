import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';

class AddEditIncomeScreen extends ConsumerStatefulWidget {
  final int? incomeId;
  const AddEditIncomeScreen({super.key, this.incomeId});

  @override
  ConsumerState<AddEditIncomeScreen> createState() => _AddEditIncomeScreenState();
}

class _AddEditIncomeScreenState extends ConsumerState<AddEditIncomeScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  int? _selectedSourceId;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.incomeId != null;

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
    if (_selectedSourceId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select an income source')));
      return;
    }

    await ref.read(incomeRepositoryProvider).addIncome(
          amount: amount,
          title: _titleController.text.trim().isEmpty
              ? 'Income'
              : _titleController.text.trim(),
          sourceId: _selectedSourceId!,
          date: _selectedDate,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(activeIncomeSourcesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Income' : 'New Income')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    style: AppTypography.numericXl.copyWith(color: AppColors.income),
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

          Text('Source', style: AppTypography.titleMd),
          const SizedBox(height: 8),
          sourcesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading sources: $e'),
            data: (sources) => SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sources.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final source = sources[i];
                  final selected = _selectedSourceId == source.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSourceId = source.id),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              selected ? AppColors.secondary : AppColors.surfaceContainerHigh,
                          child: Icon(Icons.work_outline,
                              color: selected ? Colors.white : AppColors.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(source.name, style: AppTypography.bodyMd),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),

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

          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.income),
            child: const Text('Save Income'),
          ),
        ],
      ),
    );
  }
}
