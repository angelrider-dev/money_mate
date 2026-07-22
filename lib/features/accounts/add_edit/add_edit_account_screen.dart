import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';

class AddEditAccountScreen extends ConsumerStatefulWidget {
  const AddEditAccountScreen({super.key});

  @override
  ConsumerState<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends ConsumerState<AddEditAccountScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  String _type = 'cash';

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter an account name')));
      return;
    }

    await ref.read(accountRepositoryProvider).addAccount(
          name: _nameController.text.trim(),
          type: _type,
          openingBalance: double.tryParse(_balanceController.text) ?? 0,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Account Name'),
          ),
          const SizedBox(height: 16),

          Text('Type', style: AppTypography.titleMd),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'cash', label: Text('Cash'), icon: Icon(Icons.payments_outlined)),
              ButtonSegment(value: 'bank', label: Text('Bank'), icon: Icon(Icons.account_balance_outlined)),
              ButtonSegment(value: 'card', label: Text('Card'), icon: Icon(Icons.credit_card)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Opening Balance', prefixText: '\$ '),
          ),
          const SizedBox(height: 32),

          ElevatedButton(onPressed: _save, child: const Text('Save Account')),
        ],
      ),
    );
  }
}
