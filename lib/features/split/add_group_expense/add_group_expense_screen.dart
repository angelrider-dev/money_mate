import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../data/repositories/split_calculator.dart';
import '../../../data/local/database.dart';

class AddGroupExpenseScreen extends ConsumerStatefulWidget {
  final int groupId;
  const AddGroupExpenseScreen({super.key, required this.groupId});

  @override
  ConsumerState<AddGroupExpenseScreen> createState() => _AddGroupExpenseScreenState();
}

class _AddGroupExpenseScreenState extends ConsumerState<AddGroupExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  int? _paidByMemberId;
  String _splitType = 'equal';
  final Set<int> _selectedMemberIds = {};
  final Map<int, TextEditingController> _exactControllers = {};
  final Map<int, TextEditingController> _percentControllers = {};

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (final c in _exactControllers.values) {
      c.dispose();
    }
    for (final c in _percentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;

  Map<int, double> _calculateShares() {
    switch (_splitType) {
      case 'exact':
        final shares = <int, double>{};
        for (final id in _selectedMemberIds) {
          shares[id] = double.tryParse(_exactControllers[id]?.text ?? '') ?? 0;
        }
        return shares;
      case 'percentage':
        final percentages = <int, double>{};
        for (final id in _selectedMemberIds) {
          percentages[id] = double.tryParse(_percentControllers[id]?.text ?? '') ?? 0;
        }
        return SplitCalculator.splitByPercentage(total: _amount, percentages: percentages);
      default: // equal
        return SplitCalculator.splitEqually(
          total: _amount,
          memberIds: _selectedMemberIds.toList(),
        );
    }
  }

  Future<void> _save() async {
    if (_amount <= 0 || _titleController.text.trim().isEmpty || _paidByMemberId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill in amount, title, and who paid')));
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select at least one member to split with')));
      return;
    }

    Map<int, double> shares;
    try {
      shares = _calculateShares();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return;
    }

    await ref.read(groupRepositoryProvider).addGroupExpense(
          title: _titleController.text.trim(),
          amount: _amount,
          date: DateTime.now(),
          groupId: widget.groupId,
          paidByMemberId: _paidByMemberId!,
          splitType: _splitType,
          shares: shares,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final allMembersAsync = ref.watch(activeMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Group Expense')),
      body: allMembersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              Text('Paid by', style: AppTypography.titleMd),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _paidByMemberId,
                items: members
                    .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                    .toList(),
                onChanged: (v) => setState(() => _paidByMemberId = v),
              ),
              const SizedBox(height: 16),

              Text('Split Type', style: AppTypography.titleMd),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'equal', label: Text('Equal')),
                  ButtonSegment(value: 'exact', label: Text('Exact')),
                  ButtonSegment(value: 'percentage', label: Text('%')),
                ],
                selected: {_splitType},
                onSelectionChanged: (s) => setState(() => _splitType = s.first),
              ),
              const SizedBox(height: 16),

              Text('Split with', style: AppTypography.titleMd),
              ...members.map((m) => _memberSplitRow(m)),

              const SizedBox(height: 8),
              _remainingIndicator(),

              const SizedBox(height: 32),
              ElevatedButton(onPressed: _save, child: const Text('Save Expense')),
            ],
          );
        },
      ),
    );
  }

  Widget _memberSplitRow(Member member) {
    final selected = _selectedMemberIds.contains(member.id);
    _exactControllers.putIfAbsent(member.id, () => TextEditingController());
    _percentControllers.putIfAbsent(member.id, () => TextEditingController());

    return Row(
      children: [
        Checkbox(
          value: selected,
          onChanged: (v) => setState(() {
            if (v == true) {
              _selectedMemberIds.add(member.id);
            } else {
              _selectedMemberIds.remove(member.id);
            }
          }),
        ),
        Expanded(child: Text(member.name)),
        if (selected && _splitType == 'exact')
          SizedBox(
            width: 80,
            child: TextField(
              controller: _exactControllers[member.id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(prefixText: '\$'),
              onChanged: (_) => setState(() {}),
            ),
          ),
        if (selected && _splitType == 'percentage')
          SizedBox(
            width: 70,
            child: TextField(
              controller: _percentControllers[member.id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(suffixText: '%'),
              onChanged: (_) => setState(() {}),
            ),
          ),
      ],
    );
  }

  Widget _remainingIndicator() {
    if (_splitType == 'equal' || _selectedMemberIds.isEmpty) return const SizedBox.shrink();

    double allocated = 0;
    if (_splitType == 'exact') {
      for (final id in _selectedMemberIds) {
        allocated += double.tryParse(_exactControllers[id]?.text ?? '') ?? 0;
      }
      final remaining = _amount - allocated;
      return Text(
        'Remaining to allocate: \$${remaining.toStringAsFixed(2)}',
        style: AppTypography.bodyMd.copyWith(
          color: remaining.abs() < 0.01 ? AppColors.income : AppColors.error,
        ),
      );
    } else {
      for (final id in _selectedMemberIds) {
        allocated += double.tryParse(_percentControllers[id]?.text ?? '') ?? 0;
      }
      final remaining = 100 - allocated;
      return Text(
        'Remaining: ${remaining.toStringAsFixed(1)}%',
        style: AppTypography.bodyMd.copyWith(
          color: remaining.abs() < 0.5 ? AppColors.income : AppColors.error,
        ),
      );
    }
  }
}
