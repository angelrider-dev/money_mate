import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/expense_providers.dart';

const _iconOptions = <String, IconData>{
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'shopping_bag': Icons.shopping_bag,
  'receipt': Icons.receipt,
  'local_hospital': Icons.local_hospital,
  'movie': Icons.movie,
  'house': Icons.house,
  'school': Icons.school,
  'flight': Icons.flight,
  'local_grocery_store': Icons.local_grocery_store,
  'category': Icons.category,
};

const _colorOptions = <String>[
  '#FF7043', '#42A5F5', '#AB47BC', '#FFA726', '#EF5350',
  '#26C6DA', '#8D6E63', '#5C6BC0', '#29B6F6', '#66BB6A', '#78909C',
];

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final int? categoryId;
  const AddEditCategoryScreen({super.key, this.categoryId});

  @override
  ConsumerState<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'category';
  String _selectedColor = _colorOptions.first;

  bool get _isEditing => widget.categoryId != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a category name')));
      return;
    }

    await ref.read(categoryRepositoryProvider).addCategory(
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          colorHex: _selectedColor,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Category' : 'New Category')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          const SizedBox(height: 24),

          Text('Icon', style: AppTypography.titleMd),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _iconOptions.entries.map((entry) {
              final selected = _selectedIcon == entry.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = entry.key),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      selected ? AppColors.primary : AppColors.surfaceContainerHigh,
                  child: Icon(entry.value, color: selected ? Colors.white : AppColors.onSurface),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          Text('Color', style: AppTypography.titleMd),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colorOptions.map((hex) {
              final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
              final selected = _selectedColor == hex;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: color,
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          ElevatedButton(onPressed: _save, child: const Text('Save Category')),
        ],
      ),
    );
  }
}
