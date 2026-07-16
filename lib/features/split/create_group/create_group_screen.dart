import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _memberNameController = TextEditingController();
  final List<String> _pendingMemberNames = [];

  @override
  void dispose() {
    _nameController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  void _addMemberChip() {
    final name = _memberNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _pendingMemberNames.add(name);
      _memberNameController.clear();
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a group name')));
      return;
    }

    final repo = ref.read(groupRepositoryProvider);
    final groupId = await repo.createGroup(_nameController.text.trim());

    for (final name in _pendingMemberNames) {
      final memberId = await repo.addMember(name);
      await repo.addMemberToGroup(groupId, memberId);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Group Name'),
          ),
          const SizedBox(height: 24),
          Text('Add Members', style: AppTypography.titleMd),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _memberNameController,
                  decoration: const InputDecoration(hintText: 'Member name'),
                  onSubmitted: (_) => _addMemberChip(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                onPressed: _addMemberChip,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pendingMemberNames
                .map((name) => Chip(
                      label: Text(name),
                      onDeleted: () => setState(() => _pendingMemberNames.remove(name)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: _save, child: const Text('Create Group')),
        ],
      ),
    );
  }
}
