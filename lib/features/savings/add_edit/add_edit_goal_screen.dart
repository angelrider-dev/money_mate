import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';

class AddEditGoalScreen extends ConsumerStatefulWidget {
  final int? goalId;
  const AddEditGoalScreen({super.key, this.goalId});

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  DateTime? _targetDate;
  String? _coverImagePath;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _coverImagePath = picked.path);
  }

  Future<void> _save() async {
    final target = double.tryParse(_targetController.text);
    if (target == null || target <= 0 || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a title and target amount')));
      return;
    }

    await ref.read(savingsGoalRepositoryProvider).createGoal(
          title: _titleController.text.trim(),
          targetAmount: target,
          targetDate: _targetDate,
          coverImagePath: _coverImagePath,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Goal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _pickCoverImage,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                image: _coverImagePath != null
                    ? DecorationImage(
                        image: FileImage(File(_coverImagePath!)), fit: BoxFit.cover)
                    : null,
              ),
              child: _coverImagePath == null
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 32),
                          SizedBox(height: 8),
                          Text('Add cover photo (optional)'),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Goal Title'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _targetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Target Amount', prefixText: '\$ '),
          ),
          const SizedBox(height: 12),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Target Date (optional)'),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
              child: Text(_targetDate == null
                  ? 'Set date'
                  : '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(onPressed: _save, child: const Text('Create Goal')),
        ],
      ),
    );
  }
}
